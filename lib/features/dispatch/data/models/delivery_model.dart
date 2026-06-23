import 'dart:convert';

import 'package:orion_app/features/dispatch/domain/entities/delivery.dart';
import 'package:orion_app/features/dispatch/domain/entities/proof_of_delivery.dart';

class DeliveryModel extends Delivery {
  const DeliveryModel({
    required super.id,
    required super.tripStopId,
    required super.customerName,
    super.packageDescription = '',
    super.proof,
    super.deliveredAt,
    super.synced = false,
    super.isCompleted = false,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    final proofType = json['proof_type'] as String?;
    ProofOfDelivery? proof;
    if (proofType != null) {
      proof = ProofOfDelivery(
        type: ProofType.values.firstWhere(
          (t) => t.name == proofType,
          orElse: () => ProofType.photo,
        ),
        photoPath: json['photo_path'] as String?,
        signaturePath: json['signature_path'] as String?,
        notes: json['notes'] as String?,
      );
    }

    return DeliveryModel(
      id: json['id'] as String,
      tripStopId: json['trip_stop_id'] as String,
      customerName: json['customer_name'] as String? ?? 'Cliente',
      packageDescription: json['package_description'] as String? ?? '',
      proof: proof,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      synced: json['synced'] == true || json['synced'] == 1,
      isCompleted: json['is_completed'] == true || json['is_completed'] == 1,
    );
  }

  factory DeliveryModel.fromEntity(Delivery delivery) {
    return DeliveryModel(
      id: delivery.id,
      tripStopId: delivery.tripStopId,
      customerName: delivery.customerName,
      packageDescription: delivery.packageDescription,
      proof: delivery.proof,
      deliveredAt: delivery.deliveredAt,
      synced: delivery.synced,
      isCompleted: delivery.isCompleted,
    );
  }

  factory DeliveryModel.fromLocalMap(Map<String, dynamic> map) {
    final payload =
        jsonDecode(map['payload_json'] as String) as Map<String, dynamic>;
    return DeliveryModel.fromJson({...payload, 'id': map['id']});
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trip_stop_id': tripStopId,
        'customer_name': customerName,
        'package_description': packageDescription,
        'proof_type': proof?.type.name,
        'photo_path': proof?.photoPath,
        'signature_path': proof?.signaturePath,
        'notes': proof?.notes,
        'delivered_at': deliveredAt?.toIso8601String(),
        'is_completed': isCompleted,
        'synced': synced,
      };

  /// Payload para POST /dispatch/deliveries (booleanos explícitos, synced=false).
  Map<String, dynamic> toApiPayload() => {
        'id': id,
        'trip_stop_id': tripStopId,
        'customer_name': customerName,
        'package_description': packageDescription,
        'proof_type': proof?.type.name,
        'photo_path': proof?.photoPath,
        'signature_path': proof?.signaturePath,
        'notes': proof?.notes,
        'delivered_at': (deliveredAt ?? DateTime.now()).toIso8601String(),
        'is_completed': isCompleted,
        'synced': false,
      };

  Map<String, dynamic> toLocalMap() => {
        'id': id,
        'trip_stop_id': tripStopId,
        'proof_type': proof?.type.name ?? '',
        'photo_path': proof?.photoPath,
        'signature_path': proof?.signaturePath,
        'notes': proof?.notes,
        'delivered_at':
            (deliveredAt ?? DateTime.now()).toIso8601String(),
        'payload_json': jsonEncode(toJson()),
        'synced': synced ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

  Delivery toEntity() => Delivery(
        id: id,
        tripStopId: tripStopId,
        customerName: customerName,
        packageDescription: packageDescription,
        proof: proof,
        deliveredAt: deliveredAt,
        synced: synced,
        isCompleted: isCompleted,
      );
}
