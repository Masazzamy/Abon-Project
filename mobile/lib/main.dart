import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'providers/user_provider.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  final loggedIn = await authService.isLoggedIn();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MyApp(isLoggedIn: loggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abon Salakopi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5E3C),
          primary: const Color(0xFF8B5E3C),
          secondary: const Color(0xFFF5E6D3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF8B5E3C), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
      themeMode: ThemeMode.light, // force light
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
      ],
      home: isLoggedIn ? const DashboardPage() : const LoginPage(),
    );
  }
}
