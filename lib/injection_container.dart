import 'package:orion_app/core/database/database_helper.dart';
import 'package:orion_app/core/location/device_location_service.dart';
import 'package:orion_app/core/network/api_client.dart';
import 'package:orion_app/core/network/auth_dio_factory.dart';
import 'package:orion_app/core/network/maintenance_api_client.dart';
import 'package:orion_app/core/network/auth_token_provider.dart';
import 'package:orion_app/core/sync/sync_manager.dart';
import 'package:orion_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:orion_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:orion_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:orion_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:orion_app/features/auth/domain/usecases/check_session_usecase.dart';
import 'package:orion_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:orion_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:orion_app/features/dispatch/data/datasources/dispatch_local_datasource.dart';
import 'package:orion_app/features/dispatch/data/services/geocoding_service.dart';
import 'package:orion_app/features/dispatch/data/services/stop_destination_resolver.dart';
import 'package:orion_app/features/dispatch/data/services/waze_navigation_service.dart';
import 'package:orion_app/features/dispatch/data/datasources/dispatch_remote_datasource.dart';
import 'package:orion_app/features/dispatch/data/repositories/dispatch_repository_impl.dart';
import 'package:orion_app/features/dispatch/domain/repositories/dispatch_repository.dart';
import 'package:orion_app/features/dispatch/domain/usecases/end_jornada_usecase.dart';
import 'package:orion_app/features/dispatch/domain/usecases/get_deliveries_usecase.dart';
import 'package:orion_app/features/dispatch/domain/usecases/load_daily_route_usecase.dart';
import 'package:orion_app/features/dispatch/domain/usecases/load_route_sheet_usecase.dart';
import 'package:orion_app/features/dispatch/domain/usecases/load_route_sheets_usecase.dart';
import 'package:orion_app/features/dispatch/domain/usecases/mark_stop_arrived_usecase.dart';
import 'package:orion_app/features/dispatch/domain/usecases/start_jornada_usecase.dart';
import 'package:orion_app/features/dispatch/domain/usecases/submit_proof_of_delivery_usecase.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_bloc.dart';
import 'package:orion_app/features/incidents/data/datasources/incidents_local_datasource.dart';
import 'package:orion_app/features/incidents/data/repositories/incidents_repository_impl.dart';
import 'package:orion_app/features/incidents/domain/repositories/incidents_repository.dart';
import 'package:orion_app/features/incidents/data/datasources/maintenance_remote_datasource.dart';
import 'package:orion_app/features/incidents/data/services/maintenance_sync_service.dart';
import 'package:orion_app/features/incidents/domain/usecases/get_maintenance_history_usecase.dart';
import 'package:orion_app/features/incidents/domain/usecases/submit_maintenance_request_usecase.dart';
import 'package:orion_app/features/incidents/domain/usecases/submit_route_incident_usecase.dart';
import 'package:orion_app/features/incidents/domain/usecases/trigger_panic_alert_usecase.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_bloc.dart';
import 'package:orion_app/core/network/notification_api_client.dart';
import 'package:orion_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:orion_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:orion_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:orion_app/features/notifications/domain/usecases/get_notification_detail_usecase.dart';
import 'package:orion_app/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:orion_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:orion_app/features/telemetry/data/datasources/telemetry_local_datasource.dart';
import 'package:orion_app/features/telemetry/data/datasources/telemetry_remote_datasource.dart';
import 'package:orion_app/features/telemetry/data/repositories/telemetry_repository_impl.dart';
import 'package:orion_app/features/telemetry/data/services/gps_tracker_service.dart';
import 'package:orion_app/features/telemetry/data/services/telemetry_coordinator.dart';
import 'package:orion_app/features/telemetry/data/services/telemetry_sync_service.dart';
import 'package:orion_app/features/telemetry/domain/repositories/telemetry_repository.dart';
import 'package:orion_app/features/telemetry/domain/usecases/save_position_usecase.dart';
import 'package:orion_app/features/telemetry/domain/usecases/sync_pending_positions_usecase.dart';
import 'package:orion_app/features/telemetry/presentation/bloc/telemetry_bloc.dart';

final sl = _ServiceLocator();

class _ServiceLocator {
  final Map<Type, dynamic> _instances = {};

  T get<T>() {
    final instance = _instances[T];
    if (instance == null) {
      throw StateError('Dependencia no registrada: $T');
    }
    return instance as T;
  }

  void registerSingleton<T>(T instance) {
    _instances[T] = instance;
  }
}

Future<void> initDependencies() async {
  // Core
  sl.registerSingleton<DatabaseHelper>(DatabaseHelper.instance);

  final authLocal = AuthLocalDataSourceImpl(
    databaseHelper: sl.get<DatabaseHelper>(),
  );
  sl.registerSingleton<AuthLocalDataSource>(authLocal);
  sl.registerSingleton<AuthTokenProvider>(authLocal);

  sl.registerSingleton<ApiClient>(
    ApiClient(
      tokenProvider: sl.get<AuthTokenProvider>(),
      authLocalDataSource: authLocal,
    ),
  );

  sl.registerSingleton<DeviceLocationService>(DeviceLocationService());

  sl.registerSingleton<SyncManager>(
    SyncManager(
      databaseHelper: sl.get<DatabaseHelper>(),
      apiClient: sl.get<ApiClient>(),
      authLocalDataSource: authLocal,
    ),
  );

  // Auth — Dio público (sin JWT) apuntando al API Gateway
  sl.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl(dio: AuthDioFactory.create()),
  );
  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      remoteDataSource: sl.get<AuthRemoteDataSource>(),
      localDataSource: sl.get<AuthLocalDataSource>(),
    ),
  );
  sl.registerSingleton<LoginUseCase>(
    LoginUseCase(sl.get<AuthRepository>()),
  );
  sl.registerSingleton<LogoutUseCase>(
    LogoutUseCase(sl.get<AuthRepository>()),
  );
  sl.registerSingleton<CheckSessionUseCase>(
    CheckSessionUseCase(sl.get<AuthRepository>()),
  );
  sl.registerSingleton<AuthBloc>(
    AuthBloc(
      loginUseCase: sl.get<LoginUseCase>(),
      logoutUseCase: sl.get<LogoutUseCase>(),
      checkSessionUseCase: sl.get<CheckSessionUseCase>(),
    ),
  );

  // Dispatch
  sl.registerSingleton<DispatchLocalDataSource>(
    DispatchLocalDataSourceImpl(databaseHelper: sl.get<DatabaseHelper>()),
  );
  sl.registerSingleton<DispatchRemoteDataSource>(
    DispatchRemoteDataSourceImpl(apiClient: sl.get<ApiClient>()),
  );
  sl.registerSingleton<DispatchRepository>(
    DispatchRepositoryImpl(
      localDataSource: sl.get<DispatchLocalDataSource>(),
      remoteDataSource: sl.get<DispatchRemoteDataSource>(),
      syncManager: sl.get<SyncManager>(),
      deviceLocationService: sl.get<DeviceLocationService>(),
    ),
  );
  sl.registerSingleton<GeocodingService>(GeocodingService());
  sl.registerSingleton<StopDestinationResolver>(
    StopDestinationResolver(geocodingService: sl.get<GeocodingService>()),
  );
  sl.registerSingleton<WazeNavigationService>(
    WazeNavigationService(
      destinationResolver: sl.get<StopDestinationResolver>(),
    ),
  );
  sl.registerSingleton<LoadRouteSheetsUseCase>(
    LoadRouteSheetsUseCase(sl.get<DispatchRepository>()),
  );
  sl.registerSingleton<LoadRouteSheetUseCase>(
    LoadRouteSheetUseCase(sl.get<DispatchRepository>()),
  );
  sl.registerSingleton<LoadDailyRouteUseCase>(
    LoadDailyRouteUseCase(sl.get<DispatchRepository>()),
  );
  sl.registerSingleton<StartJornadaUseCase>(
    StartJornadaUseCase(sl.get<DispatchRepository>()),
  );
  sl.registerSingleton<EndJornadaUseCase>(
    EndJornadaUseCase(sl.get<DispatchRepository>()),
  );
  sl.registerSingleton<MarkStopArrivedUseCase>(
    MarkStopArrivedUseCase(sl.get<DispatchRepository>()),
  );
  sl.registerSingleton<GetDeliveriesUseCase>(
    GetDeliveriesUseCase(sl.get<DispatchRepository>()),
  );
  sl.registerSingleton<SubmitProofOfDeliveryUseCase>(
    SubmitProofOfDeliveryUseCase(sl.get<DispatchRepository>()),
  );
  sl.registerSingleton<DispatchBloc>(
    DispatchBloc(
      loadRouteSheetsUseCase: sl.get<LoadRouteSheetsUseCase>(),
      loadRouteSheetUseCase: sl.get<LoadRouteSheetUseCase>(),
      loadDailyRouteUseCase: sl.get<LoadDailyRouteUseCase>(),
      startJornadaUseCase: sl.get<StartJornadaUseCase>(),
      endJornadaUseCase: sl.get<EndJornadaUseCase>(),
      markStopArrivedUseCase: sl.get<MarkStopArrivedUseCase>(),
      getDeliveriesUseCase: sl.get<GetDeliveriesUseCase>(),
      submitProofOfDeliveryUseCase: sl.get<SubmitProofOfDeliveryUseCase>(),
      dispatchRepository: sl.get<DispatchRepository>(),
    ),
  );

  // Telemetry
  sl.registerSingleton<TelemetryLocalDataSource>(
    TelemetryLocalDataSourceImpl(databaseHelper: sl.get<DatabaseHelper>()),
  );
  sl.registerSingleton<TelemetryRemoteDataSource>(
    TelemetryRemoteDataSourceImpl(apiClient: sl.get<ApiClient>()),
  );
  sl.registerSingleton<TelemetryRepository>(
    TelemetryRepositoryImpl(
      localDataSource: sl.get<TelemetryLocalDataSource>(),
      remoteDataSource: sl.get<TelemetryRemoteDataSource>(),
    ),
  );
  sl.registerSingleton<SavePositionUseCase>(
    SavePositionUseCase(sl.get<TelemetryRepository>()),
  );
  sl.registerSingleton<SyncPendingPositionsUseCase>(
    SyncPendingPositionsUseCase(sl.get<TelemetryRepository>()),
  );
  sl.registerSingleton<GpsTrackerService>(
    GpsTrackerService(savePositionUseCase: sl.get<SavePositionUseCase>()),
  );
  sl.registerSingleton<TelemetrySyncService>(
    TelemetrySyncService(
      repository: sl.get<TelemetryRepository>(),
      syncInterval: TelemetrySyncService.defaultSyncInterval,
    ),
  );
  sl.registerSingleton<TelemetryCoordinator>(
    TelemetryCoordinator(
      gpsTrackerService: sl.get<GpsTrackerService>(),
      syncService: sl.get<TelemetrySyncService>(),
    ),
  );
  sl.registerSingleton<TelemetryBloc>(
    TelemetryBloc(
      coordinator: sl.get<TelemetryCoordinator>(),
      syncService: sl.get<TelemetrySyncService>(),
    ),
  );

  // Incidents + Maintenance
  sl.registerSingleton<MaintenanceApiClient>(
    MaintenanceApiClient(tokenProvider: sl.get<AuthTokenProvider>()),
  );
  sl.registerSingleton<MaintenanceRemoteDataSource>(
    MaintenanceRemoteDataSourceImpl(
      apiClient: sl.get<MaintenanceApiClient>(),
    ),
  );
  sl.registerSingleton<IncidentsLocalDataSource>(
    IncidentsLocalDataSourceImpl(databaseHelper: sl.get<DatabaseHelper>()),
  );
  sl.registerSingleton<MaintenanceSyncService>(
    MaintenanceSyncService(
      localDataSource: sl.get<IncidentsLocalDataSource>(),
      remoteDataSource: sl.get<MaintenanceRemoteDataSource>(),
    ),
  );
  sl.registerSingleton<IncidentsRepository>(
    IncidentsRepositoryImpl(
      localDataSource: sl.get<IncidentsLocalDataSource>(),
      maintenanceRemoteDataSource: sl.get<MaintenanceRemoteDataSource>(),
      maintenanceSyncService: sl.get<MaintenanceSyncService>(),
      syncManager: sl.get<SyncManager>(),
    ),
  );
  sl.registerSingleton<SubmitRouteIncidentUseCase>(
    SubmitRouteIncidentUseCase(sl.get<IncidentsRepository>()),
  );
  sl.registerSingleton<SubmitMaintenanceRequestUseCase>(
    SubmitMaintenanceRequestUseCase(sl.get<IncidentsRepository>()),
  );
  sl.registerSingleton<GetMaintenanceHistoryUseCase>(
    GetMaintenanceHistoryUseCase(sl.get<IncidentsRepository>()),
  );
  sl.registerSingleton<TriggerPanicAlertUseCase>(
    TriggerPanicAlertUseCase(sl.get<IncidentsRepository>()),
  );
  sl.registerSingleton<IncidentsBloc>(
    IncidentsBloc(
      submitRouteIncidentUseCase: sl.get<SubmitRouteIncidentUseCase>(),
      submitMaintenanceRequestUseCase:
          sl.get<SubmitMaintenanceRequestUseCase>(),
      triggerPanicAlertUseCase: sl.get<TriggerPanicAlertUseCase>(),
      getMaintenanceHistoryUseCase: sl.get<GetMaintenanceHistoryUseCase>(),
      incidentsRepository: sl.get<IncidentsRepository>(),
    ),
  );

  await sl.get<DatabaseHelper>().database;
  await sl.get<SyncManager>().start();
  sl.get<MaintenanceSyncService>().start();

  // Notifications
  sl.registerSingleton<NotificationApiClient>(
    NotificationApiClient(tokenProvider: sl.get<AuthTokenProvider>()),
  );
  sl.registerSingleton<NotificationRemoteDataSource>(
    NotificationRemoteDataSourceImpl(
      apiClient: sl.get<NotificationApiClient>(),
    ),
  );
  sl.registerSingleton<NotificationRepository>(
    NotificationRepositoryImpl(
      remoteDataSource: sl.get<NotificationRemoteDataSource>(),
      tokenProvider: sl.get<AuthTokenProvider>(),
    ),
  );
  sl.registerSingleton<GetNotificationsUseCase>(
    GetNotificationsUseCase(sl.get<NotificationRepository>()),
  );
  sl.registerSingleton<GetNotificationDetailUseCase>(
    GetNotificationDetailUseCase(sl.get<NotificationRepository>()),
  );
  sl.registerSingleton<NotificationsBloc>(
    NotificationsBloc(
      getNotificationsUseCase: sl.get<GetNotificationsUseCase>(),
      getNotificationDetailUseCase: sl.get<GetNotificationDetailUseCase>(),
    ),
  );
}
