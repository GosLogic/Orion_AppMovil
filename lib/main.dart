import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:orion_app/app.dart';
import 'package:orion_app/core/constants/api_constants.dart';
import 'package:orion_app/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  if (kDebugMode) {
    debugPrint('[Orion] API base URL: ${ApiConstants.baseUrl}');
  }
  runApp(const OrionApp());
}
