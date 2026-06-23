class TelemetryBatchResponseModel {
  final int accepted;
  final int rejected;

  const TelemetryBatchResponseModel({
    required this.accepted,
    required this.rejected,
  });

  factory TelemetryBatchResponseModel.fromJson(Map<String, dynamic> json) {
    return TelemetryBatchResponseModel(
      accepted: (json['accepted'] as num?)?.toInt() ?? 0,
      rejected: (json['rejected'] as num?)?.toInt() ?? 0,
    );
  }
}
