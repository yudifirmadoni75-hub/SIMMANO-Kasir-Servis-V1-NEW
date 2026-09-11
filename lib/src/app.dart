import 'package:flutter/material.dart';
import 'ui/home_screen.dart';

class SimmanoApp extends StatelessWidget {
  const SimmanoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'SIMMANO',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue, scaffoldBackgroundColor: const Color(0xfff7f8fa), cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero)),
    home: const HomeScreen(),
  );
}
