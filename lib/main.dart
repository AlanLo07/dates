import 'package:flutter/material.dart';
import 'screens/input.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Citas',
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
      home: const InputScreen(),
    );
  }
}
