import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// ID idempotente para POST maintenance: maint-<uuid>
String generateMaintenanceRequestId() => 'maint-${_uuid.v4()}';
