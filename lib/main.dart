import 'package:flutter/material.dart';
import 'package:orion_app/app.dart';
import 'package:orion_app/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const OrionApp());
}
