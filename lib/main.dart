import 'package:flutter/material.dart';
import 'hq/hq_console.dart';
import 'hq/hq_palette.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STEP HQ · Executive Console',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: HqPalette.purple),
        fontFamily: 'Malgun Gothic',
        scaffoldBackgroundColor: HqPalette.canvas,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: HqPalette.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: HqPalette.line),
          ),
        ),
      ),
      home: const HqConsole(),
    );
  }
}
