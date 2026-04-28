import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

import './screens/login_screen.dart';
import './screens/dashboard_screen.dart';
import './controllers/provider_controller.dart';
import '../services/permission_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  // Check if session exists
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  Get.put(ProviderController());
  if (isLoggedIn) {
    await PermissionManager.loadFromLocal();
  }

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
        textTheme: GoogleFonts.poppinsTextTheme(),
        primaryColor: const Color(0xFFEA5800),
        useMaterial3: true,
      ),
      // If logged in, we wrap the entire entry in PopScope to block web gestures/back buttons
      home: isLoggedIn 
          ? const PopScope(
              canPop: false, 
              child: DashboardScreen(),
            ) 
          : const LoginScreen(), 
    );
  }
}
