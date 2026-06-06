import 'package:equatable/equatable.dart';

enum ProofType { photo, signature, both }

class ProofOfDelivery extends Equatable {
  final ProofType type;
  final String? photoPath;
  final String? signaturePath;
  final String? notes;

  const ProofOfDelivery({
    required this.type,
    this.photoPath,
    this.signaturePath,
    this.notes,
  });

  @override
  List<Object?> get props => [type, photoPath, signaturePath, notes];
}
