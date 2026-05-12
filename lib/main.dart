import 'package:flutter/material.dart';
import 'package:myberikan/views/splash_screen.dart'; // sesuaikan nama package

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Berikan Bahari Indonesia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A80C4)),
        fontFamily: 'Poppins',
      ),
      home: const SplashScreen(),
    );
  }
}