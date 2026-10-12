import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/merchant_api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // Ensure Flutter engine binding is initialized before SharedPreferences calls
  WidgetsFlutterBinding.ensureInitialized();
  
  final apiService = MerchantApiService();
  final bool loggedIn = await apiService.isLoggedIn();

  runApp(MyApp(isLoggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  
  const MyApp({
    super.key, 
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Merchant App',
      debugShowCheckedModeBanner: false,
      
      // Use the unified app theme
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Enforce dark theme to align with User App
      
      // Route dynamically depending on active auth token status
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
