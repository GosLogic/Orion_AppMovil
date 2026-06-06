import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/dispatch/domain/entities/route_sheet.dart';
import 'package:orion_app/features/dispatch/domain/repositories/dispatch_repository.dart';

class StartJornadaUseCase {
  final DispatchRepository repository;

  StartJornadaUseCase(this.repository);

  Future<Result<RouteSheet>> call(String routeSheetId) {
    return repository.startJornada(routeSheetId);
  }
}
