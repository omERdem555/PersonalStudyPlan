import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:study_planner_app/providers/app_provider.dart';
import 'package:study_planner_app/screens/splash_screen.dart';
import 'package:study_planner_app/storage/local_storage_service.dart';
import 'package:study_planner_app/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();// Veritabanını başlat
  runApp(const StudyPlannerApp());
}

class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(), // AppProvider'ı sağlayarak uygulamayı sarmala
      builder: (context, child) {
        final provider = context.watch<AppProvider>();
        return MaterialApp(
          title: 'AI Destekli Çalışma Planı',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: provider.themeMode,
          home: const SplashScreen(), // Uygulama açıldığında SplashScreen'i göster
        );
      },
    );
  }
}
