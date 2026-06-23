class MaintenanceSubmitResponseModel {
  final String id;
  final String status;

  const MaintenanceSubmitResponseModel({
    required this.id,
    required this.status,
  });

  factory MaintenanceSubmitResponseModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceSubmitResponseModel(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'PENDING',
    );
  }
}
