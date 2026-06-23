import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/dispatch/domain/entities/route_sheet.dart';
import 'package:orion_app/features/dispatch/domain/repositories/dispatch_repository.dart';

class LoadRouteSheetsUseCase {
  LoadRouteSheetsUseCase(this.repository);

  final DispatchRepository repository;

  Future<Result<List<RouteSheet>>> call() => repository.getRouteSheets();
}
