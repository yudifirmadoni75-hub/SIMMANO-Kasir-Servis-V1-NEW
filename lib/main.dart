import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/services/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.init();
  runApp(const SimmanoApp());
}
