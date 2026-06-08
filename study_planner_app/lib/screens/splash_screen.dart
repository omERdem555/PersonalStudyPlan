import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await context.read<AppProvider>().loadData();
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    final isOnboarded = context.read<AppProvider>().isOnboarded;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isOnboarded ? const HomeScreen() : const OnboardingScreen(),
      ), //Kullanıcı varsa home yoksa onboarding ekranına yönlendir
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3366FF), Color(0xFF00B8D4)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_outlined, size: 68, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                'AI Destekli Çalışma Planı',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Performansınızı analiz eden ve günlük çalışma planı oluşturan bir yardımcı.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
