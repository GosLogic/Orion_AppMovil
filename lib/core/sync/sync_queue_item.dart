import 'package:equatable/equatable.dart';

enum SyncQueueStatus {
  pending,
  processing,
  completed,
  failed,
}

class SyncQueueItem extends Equatable {
  final int? id;
  final String feature;
  final String endpoint;
  final String method;
  final String payload;
  final String? headers;
  final SyncQueueStatus status;
  final int retryCount;
  final int maxRetries;
  final DateTime? lastAttemptAt;
  final DateTime? nextRetryAt;
  final DateTime createdAt;
  final String? errorMessage;

  const SyncQueueItem({
    this.id,
    required this.feature,
    required this.endpoint,
    required this.method,
    required this.payload,
    this.headers,
    this.status = SyncQueueStatus.pending,
    this.retryCount = 0,
    this.maxRetries = 8,
    this.lastAttemptAt,
    this.nextRetryAt,
    required this.createdAt,
    this.errorMessage,
  });

  SyncQueueItem copyWith({
    int? id,
    String? feature,
    String? endpoint,
    String? method,
    String? payload,
    String? headers,
    SyncQueueStatus? status,
    int? retryCount,
    int? maxRetries,
    DateTime? lastAttemptAt,
    DateTime? nextRetryAt,
    DateTime? createdAt,
    String? errorMessage,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      feature: feature ?? this.feature,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      payload: payload ?? this.payload,
      headers: headers ?? this.headers,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      createdAt: createdAt ?? this.createdAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as int?,
      feature: map['feature'] as String,
      endpoint: map['endpoint'] as String,
      method: map['method'] as String? ?? 'POST',
      payload: map['payload'] as String,
      headers: map['headers'] as String?,
      status: SyncQueueStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SyncQueueStatus.pending,
      ),
      retryCount: map['retry_count'] as int? ?? 0,
      maxRetries: map['max_retries'] as int? ?? 8,
      lastAttemptAt: map['last_attempt_at'] != null
          ? DateTime.parse(map['last_attempt_at'] as String)
          : null,
      nextRetryAt: map['next_retry_at'] != null
          ? DateTime.parse(map['next_retry_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      errorMessage: map['error_message'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'feature': feature,
      'endpoint': endpoint,
      'method': method,
      'payload': payload,
      'headers': headers,
      'status': status.name,
      'retry_count': retryCount,
      'max_retries': maxRetries,
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'next_retry_at': nextRetryAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'error_message': errorMessage,
    };
  }

  @override
  List<Object?> get props => [id, feature, endpoint, status, retryCount];
}
