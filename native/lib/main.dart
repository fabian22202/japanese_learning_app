import 'package:flutter/material.dart';
import 'controller.dart';
import 'ui/screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await LearningController.load();
  runApp(KotobaApp(controller: controller));
}
class KotobaApp extends StatelessWidget {
  final LearningController controller;
  const KotobaApp({super.key, required this.controller});
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'Kotoba', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, fontFamily: 'KotobaJapanese',
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffdc765b), surface: const Color(0xfffffcf6)),
      scaffoldBackgroundColor: const Color(0xfff5f1e8),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(vertical: 7))),
    home: Shell(controller: controller));
}
