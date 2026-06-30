import 'package:flutter/material.dart';
import 'services/db_service.dart';
import 'services/chatbot_service.dart';
import 'views/dashboard_view.dart';
import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize offline database (Hive)
    await DbService.init();
    
    // Load saved API key and initialize ChatbotService
    final apiKey = DbService.getApiKey();
    final keyToUse = apiKey.isNotEmpty ? apiKey : defaultGeminiApiKey;
    ChatbotService.init(keyToUse);
  } catch (e, stackTrace) {
    debugPrint('DATABASE INIT FAILURE: $e');
    debugPrint(stackTrace.toString());
  }

  runApp(const PaveSyncApp());
}

class PaveSyncApp extends StatelessWidget {
  const PaveSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PaveSync AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      ),
      home: const DashboardView(),
    );
  }
}
