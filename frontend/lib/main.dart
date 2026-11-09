import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_service.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authService = AuthService();
  final token = await authService.getToken();

  runApp(AIJobAssistantApp(initialScreen: token != null ? const DashboardScreen() : const AuthScreen()));
}

class AIJobAssistantApp extends StatelessWidget {
  final Widget initialScreen;

  const AIJobAssistantApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Job Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialScreen,
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}

