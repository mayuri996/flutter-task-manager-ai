import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/sentiment_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SentimentService().init(); // load once here
  runApp(const TaskApp());
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Task Manager',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
