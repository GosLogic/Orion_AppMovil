import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/telemetry/domain/entities/telemetry_sync_result.dart';
import 'package:orion_app/features/telemetry/domain/repositories/telemetry_repository.dart';

/// Estado observable del job de sincronización de telemetría.
class TelemetrySyncState {
  final bool isActive;
  final bool isSyncing;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? lastError;

  const TelemetrySyncState({
    this.isActive = false,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.lastError,
  });

  TelemetrySyncState copyWith({
    bool? isActive,
    bool? isSyncing,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? lastError,
  }) {
    return TelemetrySyncState(
      isActive: isActive ?? this.isActive,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: lastError,
    );
  }
}

/// Job periódico que envía posiciones GPS pendientes al backend.
class TelemetrySyncService {
  /// Intervalo de envío al servidor (mapa en vivo ~20 s).
  static const Duration defaultSyncInterval = Duration(seconds: 20);

  TelemetrySyncService({
    required TelemetryRepository repository,
    Connectivity? connectivity,
    Duration syncInterval = defaultSyncInterval,
    Duration baseBackoff = const Duration(seconds: 2),
    int maxBackoffAttempts = 3,
  })  : _repository = repository,
        _connectivity = connectivity ?? Connectivity(),
        _syncInterval = syncInterval,
        _baseBackoff = baseBackoff,
        _maxBackoffAttempts = maxBackoffAttempts;

  final TelemetryRepository _repository;
  final Connectivity _connectivity;
  final Duration _syncInterval;
  final Duration _baseBackoff;
  final int _maxBackoffAttempts;
  final Random _random = Random();

  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isActive = false;

  final ValueNotifier<TelemetrySyncState> stateNotifier =
      ValueNotifier(const TelemetrySyncState());

  bool get isActive => _isActive;

  void start() {
    if (_isActive) return;
    _isActive = true;
    stateNotifier.value = stateNotifier.value.copyWith(isActive: true);

    _timer = Timer.periodic(_syncInterval, (_) => unawaited(syncNow()));

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        final online = results.any((r) => r != ConnectivityResult.none);
        if (online) unawaited(syncNow());
      },
    );

    unawaited(_refreshPendingCount());
    unawaited(syncNow());
  }

  Future<void> flushAndStop() async {
    _isActive = false;
    _timer?.cancel();
    _timer = null;
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;

    for (var attempt = 0; attempt < _maxBackoffAttempts; attempt++) {
      final countResult = await _repository.countUnsyncedPositions();
      final pending = switch (countResult) {
        Success(value: final n) => n,
        Error() => 0,
      };
      if (pending == 0) break;

      final syncResult = await _syncWithBackoff(attempt);
      if (syncResult case Success(value: final r) when r.accepted > 0) {
        continue;
      }
      if (syncResult case Error()) {
        await Future<void>.delayed(_backoffDuration(attempt));
      }
    }

    await _refreshPendingCount();
    stateNotifier.value = stateNotifier.value.copyWith(isActive: false);
  }

  Future<Result<TelemetrySyncResult>> syncNow() async {
    if (!_isActive) {
      return const Success(
        TelemetrySyncResult(accepted: 0, rejected: 0),
      );
    }

    stateNotifier.value = stateNotifier.value.copyWith(
      isSyncing: true,
      lastError: null,
    );

    try {
      final result = await _syncWithBackoff(0);
      await _refreshPendingCount();

      if (result case Success(value: final sync) when sync.accepted > 0) {
        stateNotifier.value = stateNotifier.value.copyWith(
          lastSyncedAt: DateTime.now(),
        );
      }

      if (result case Error(failure: final failure)) {
        stateNotifier.value = stateNotifier.value.copyWith(
          lastError: failure.message,
        );
      }

      return result;
    } finally {
      stateNotifier.value = stateNotifier.value.copyWith(isSyncing: false);
    }
  }

  Future<Result<TelemetrySyncResult>> _syncWithBackoff(int attempt) async {
    var result = await _repository.syncPendingPositions();
    if (result case Success()) return result;

    for (var i = 1; i < _maxBackoffAttempts; i++) {
      await Future<void>.delayed(_backoffDuration(i));
      result = await _repository.syncPendingPositions();
      if (result case Success()) return result;
    }
    return result;
  }

  Duration _backoffDuration(int attempt) {
    final exponentialMs = _baseBackoff.inMilliseconds * pow(2, attempt);
    final jitterMs = _random.nextInt(500);
    return Duration(milliseconds: exponentialMs.toInt() + jitterMs);
  }

  Future<void> _refreshPendingCount() async {
    final result = await _repository.countUnsyncedPositions();
    if (result case Success(value: final count)) {
      stateNotifier.value = stateNotifier.value.copyWith(
        pendingCount: count,
      );
    }
  }

  Future<void> refreshPendingCount() => _refreshPendingCount();
}
