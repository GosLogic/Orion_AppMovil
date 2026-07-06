import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:orion_app/core/auth/session_expired_notifier.dart';
import 'package:orion_app/core/database/database_helper.dart';
import 'package:orion_app/core/network/api_client.dart';
import 'package:orion_app/core/sync/sync_queue_item.dart';
import 'package:orion_app/features/auth/data/datasources/auth_local_datasource.dart';

/// Gestor centralizado de sincronización offline-first.
///
/// Lee la cola persistida en SQLite y reintenta envíos al servidor
/// aplicando Retry con Backoff Exponencial + jitter cuando hay red.
class SyncManager {
  SyncManager({
    required DatabaseHelper databaseHelper,
    required ApiClient apiClient,
    required AuthLocalDataSource authLocalDataSource,
    Connectivity? connectivity,
    Duration pollInterval = const Duration(seconds: 30),
    Duration baseBackoff = const Duration(seconds: 2),
    Duration maxBackoff = const Duration(minutes: 15),
    int maxConcurrent = 3,
    SessionExpiredNotifier? sessionExpiredNotifier,
  })  : _databaseHelper = databaseHelper,
        _apiClient = apiClient,
        _authLocalDataSource = authLocalDataSource,
        _sessionExpiredNotifier =
            sessionExpiredNotifier ?? SessionExpiredNotifier.instance,
        _connectivity = connectivity ?? Connectivity(),
        _pollInterval = pollInterval,
        _baseBackoff = baseBackoff,
        _maxBackoff = maxBackoff,
        _maxConcurrent = maxConcurrent;

  final DatabaseHelper _databaseHelper;
  final ApiClient _apiClient;
  final AuthLocalDataSource _authLocalDataSource;
  final SessionExpiredNotifier _sessionExpiredNotifier;
  final Connectivity _connectivity;
  final Duration _pollInterval;
  final Duration _baseBackoff;
  final Duration _maxBackoff;
  final int _maxConcurrent;
  final Random _random = Random();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _pollTimer;
  bool _isProcessing = false;
  bool _isStarted = false;

  final ValueNotifier<SyncManagerState> stateNotifier =
      ValueNotifier(const SyncManagerState());

  /// Inicia escucha de conectividad y ciclo periódico en segundo plano.
  Future<void> start() async {
    if (_isStarted) return;
    _isStarted = true;

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) => _onConnectivityChanged(results),
    );

    _pollTimer = Timer.periodic(_pollInterval, (_) => processQueue());

    await processQueue();
  }

  /// Detiene el gestor y libera recursos.
  Future<void> stop() async {
    _isStarted = false;
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Encola un payload para sincronización diferida.
  Future<int> enqueue({
    required String feature,
    required String endpoint,
    required Map<String, dynamic> payload,
    String method = 'POST',
    Map<String, String>? headers,
    int maxRetries = 8,
  }) async {
    final item = SyncQueueItem(
      feature: feature,
      endpoint: endpoint,
      method: method.toUpperCase(),
      payload: jsonEncode(payload),
      headers: headers != null ? jsonEncode(headers) : null,
      maxRetries: maxRetries,
      createdAt: DateTime.now(),
    );

    final id = await _databaseHelper.enqueueSyncItem(item);
    await _refreshPendingCount();

    final hasNetwork = await _hasNetworkConnection();
    if (hasNetwork) {
      unawaited(processQueue());
    }

    return id;
  }

  /// Procesa la cola de sincronización pendiente.
  Future<void> processQueue() async {
    if (_isProcessing) return;

    final hasNetwork = await _hasNetworkConnection();
    if (!hasNetwork) {
      stateNotifier.value = stateNotifier.value.copyWith(
        isOnline: false,
        lastError: null,
      );
      return;
    }

    _isProcessing = true;
    stateNotifier.value = stateNotifier.value.copyWith(
      isOnline: true,
      isSyncing: true,
      lastError: null,
    );

    try {
      final pendingItems = await _databaseHelper.getPendingSyncItems(
        limit: _maxConcurrent,
      );

      if (pendingItems.isEmpty) {
        await _refreshPendingCount();
        return;
      }

      await Future.wait(
        pendingItems.map(_processItem),
        eagerError: false,
      );

      await _refreshPendingCount();
    } catch (e) {
      stateNotifier.value = stateNotifier.value.copyWith(
        lastError: e.toString(),
      );
      debugPrint('[SyncManager] Error general: $e');
    } finally {
      _isProcessing = false;
      stateNotifier.value = stateNotifier.value.copyWith(isSyncing: false);
    }
  }

  Future<void> _processItem(SyncQueueItem item) async {
    if (item.id == null) return;

    final processingItem = item.copyWith(
      status: SyncQueueStatus.processing,
      lastAttemptAt: DateTime.now(),
    );
    await _databaseHelper.updateSyncItem(processingItem);

    try {
      await _dispatchHttpRequest(processingItem);

      await _databaseHelper.deleteSyncItem(item.id!);
      stateNotifier.value = stateNotifier.value.copyWith(
        lastSyncedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 409) {
        await _databaseHelper.deleteSyncItem(item.id!);
        stateNotifier.value = stateNotifier.value.copyWith(
          lastSyncedAt: DateTime.now(),
        );
        debugPrint(
          '[SyncManager] Item ${item.id} idempotente (409) — tratado como éxito',
        );
        return;
      }
      if (statusCode == 401) {
        await _databaseHelper.deleteSyncItem(item.id!);
        await _authLocalDataSource.clearSession();
        _sessionExpiredNotifier.notify();
        debugPrint(
          '[SyncManager] Item ${item.id} rechazado (401) — sesión expirada',
        );
        return;
      }
      await _handleRetry(processingItem, e.message ?? e.toString());
    } catch (e) {
      await _handleRetry(processingItem, e.toString());
    }
  }

  Future<void> _dispatchHttpRequest(SyncQueueItem item) async {
    final payload = jsonDecode(item.payload);
    final headers = item.headers != null
        ? Map<String, dynamic>.from(jsonDecode(item.headers!) as Map)
        : null;

    final options = Options(
      method: item.method,
      headers: headers?.map((k, v) => MapEntry(k, v.toString())),
    );

    switch (item.method) {
      case 'GET':
        await _apiClient.get(item.endpoint, options: options);
      case 'PUT':
        await _apiClient.put(item.endpoint, data: payload, options: options);
      case 'PATCH':
        await _apiClient.patch(item.endpoint, data: payload, options: options);
      case 'DELETE':
        await _apiClient.delete(item.endpoint, data: payload, options: options);
      case 'POST':
      default:
        await _apiClient.post(item.endpoint, data: payload, options: options);
    }
  }

  Future<void> _handleRetry(SyncQueueItem item, String errorMessage) async {
    final nextRetryCount = item.retryCount + 1;

    if (nextRetryCount >= item.maxRetries) {
      final failedItem = item.copyWith(
        status: SyncQueueStatus.failed,
        retryCount: nextRetryCount,
        errorMessage: errorMessage,
        lastAttemptAt: DateTime.now(),
      );
      await _databaseHelper.updateSyncItem(failedItem);
      debugPrint(
        '[SyncManager] Item ${item.id} agotó reintentos: $errorMessage',
      );
      return;
    }

    final backoff = _calculateBackoff(nextRetryCount);
    final nextRetryAt = DateTime.now().add(backoff);

    final retriedItem = item.copyWith(
      status: SyncQueueStatus.pending,
      retryCount: nextRetryCount,
      nextRetryAt: nextRetryAt,
      errorMessage: errorMessage,
      lastAttemptAt: DateTime.now(),
    );

    await _databaseHelper.updateSyncItem(retriedItem);

    debugPrint(
      '[SyncManager] Reintento ${nextRetryCount}/${item.maxRetries} '
      'para item ${item.id} en ${backoff.inSeconds}s. Error: $errorMessage',
    );
  }

  /// Backoff exponencial: base * 2^retryCount + jitter aleatorio (0-1000ms).
  Duration _calculateBackoff(int retryCount) {
    final exponentialMs = _baseBackoff.inMilliseconds * pow(2, retryCount);
    final jitterMs = _random.nextInt(1000);
    final totalMs = exponentialMs + jitterMs;
    final cappedMs = min(totalMs, _maxBackoff.inMilliseconds.toDouble());
    return Duration(milliseconds: cappedMs.toInt());
  }

  Future<bool> _hasNetworkConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    stateNotifier.value = stateNotifier.value.copyWith(isOnline: isOnline);

    if (isOnline) {
      await processQueue();
    }
  }

  Future<void> _refreshPendingCount() async {
    final count = await _databaseHelper.countPendingSyncItems();
    stateNotifier.value = stateNotifier.value.copyWith(pendingCount: count);
  }
}

class SyncManagerState {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? lastError;

  const SyncManagerState({
    this.isOnline = false,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.lastError,
  });

  SyncManagerState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? lastError,
  }) {
    return SyncManagerState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: lastError,
    );
  }
}
