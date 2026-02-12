import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

import './screens/login_screen.dart';
import './screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Panel',
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(),
        primaryColor: const Color(0xFF0461A5),
        useMaterial3: true,
      ),
      // UPDATED LOGIC BELOW
      // We wrap DashboardScreen in PopScope to lock the navigation
      home: isLoggedIn 
          ? const PopScope(
              canPop: false, // This effectively locks the screen, preventing "back"
              child: DashboardScreen(),
            ) 
          : const LoginScreen(), 
    );
  }
}