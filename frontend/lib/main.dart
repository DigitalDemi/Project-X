import 'package:flutter/material.dart';
import 'package:frontend/services/calender_service.dart';
import 'package:frontend/services/learning_service.dart';
import 'package:provider/provider.dart';
import 'services/local_database.dart';
import 'services/api_service.dart';
import 'services/sync_service.dart';
import 'services/task_service.dart';
import 'services/topic_service.dart';
import 'services/profile_service.dart';
import 'services/content_service.dart';
import 'ui/navigation/shared/body.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final localDb = LocalDatabase();
  final database = await localDb.database; 
  final apiService = ApiService();
  final syncService = SyncService(
    localDb, 
    apiService,
    SyncConfig(
      syncInterval: const Duration(minutes: 15),
      syncTasks: true,
      syncCalendar: true,
      syncTopics: true,
    ),
  );
  
  // Initialize feature services
  final taskService = TaskService(syncService);
  final topicService = TopicService(syncService);
  final calendarService = CalendarService(database);
  final profileService = ProfileService();
  final learningService = LearningService(); // Initialize the new service

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => profileService),
        ChangeNotifierProvider(create: (_) => taskService),
        ChangeNotifierProvider(create: (_) => topicService),
        ChangeNotifierProvider(create: (_) => calendarService),
        ChangeNotifierProvider(create: (_) => learningService), // Add learning service
        ChangeNotifierProvider(create: (_) => ContentService()), // Add this line

      ],
      child: const MyApp(), // This is fine since MyApp is already defined
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learning App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.deepPurpleAccent,
        cardColor: Colors.grey[900],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: const Body(),
    );
  }
}