import 'package:equatable/equatable.dart';

class TelemetrySyncResult extends Equatable {
  final int accepted;
  final int rejected;
  final int pendingRemaining;

  const TelemetrySyncResult({
    required this.accepted,
    required this.rejected,
    this.pendingRemaining = 0,
  });

  @override
  List<Object?> get props => [accepted, rejected, pendingRemaining];
}
