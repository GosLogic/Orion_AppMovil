import 'package:equatable/equatable.dart';
import 'package:orion_app/features/dispatch/domain/entities/proof_of_delivery.dart';

class Delivery extends Equatable {
  final String id;
  final String tripStopId;
  final String customerName;
  final String packageDescription;
  final ProofOfDelivery? proof;
  final DateTime? deliveredAt;
  final bool synced;
  final bool isCompleted;
  final double? latitude;
  final double? longitude;

  const Delivery({
    required this.id,
    required this.tripStopId,
    required this.customerName,
    this.packageDescription = '',
    this.proof,
    this.deliveredAt,
    this.synced = false,
    this.isCompleted = false,
    this.latitude,
    this.longitude,
  });

  Delivery copyWith({
    String? id,
    String? tripStopId,
    String? customerName,
    String? packageDescription,
    ProofOfDelivery? proof,
    DateTime? deliveredAt,
    bool? synced,
    bool? isCompleted,
    double? latitude,
    double? longitude,
  }) {
    return Delivery(
      id: id ?? this.id,
      tripStopId: tripStopId ?? this.tripStopId,
      customerName: customerName ?? this.customerName,
      packageDescription: packageDescription ?? this.packageDescription,
      proof: proof ?? this.proof,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      synced: synced ?? this.synced,
      isCompleted: isCompleted ?? this.isCompleted,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  List<Object?> get props =>
      [id, tripStopId, customerName, isCompleted, latitude, longitude];
}
