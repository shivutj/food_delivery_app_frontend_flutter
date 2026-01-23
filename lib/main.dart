// lib/main.dart - REPLACE THE ENTIRE FILE

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart'; // ✅ ADD THIS
import 'screens/login_screen.dart';

void main() async {
  // ✅ ADD THIS
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Show loading screen until theme is loaded
          if (!themeProvider.isLoaded) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ),
            );
          }

          return MaterialApp(
            title: 'Food Delivery App',
            debugShowCheckedModeBanner: false,

            // Dynamic theme switching
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
