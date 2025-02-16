import 'package:flutter/material.dart';
import 'package:frontend/ui/navigation/shared/body.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/profile_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ProfileService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dark Mode UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.deepPurpleAccent,
        cardColor: Colors.grey[900], // Dark gray for cards
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: Body (),
    );
  }
}
