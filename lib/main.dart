import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'controllers/music_orchestrator.dart';
import 'core/theme/app_theme.dart';
import 'services/firebase_service.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientation and clean status bar styling
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase (if configured) and Core Music Orchestrator
  await FirebaseService.instance.init();
  await MusicOrchestrator.instance.init();

  runApp(const CityMuApp());
}

class CityMuApp extends StatelessWidget {
  const CityMuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CityMu - Spatial Foley Lo-Fi Generator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}
