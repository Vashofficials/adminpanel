import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Ensure you have this package
import 'custom_center_dialog.dart'; // Import your dialog file
// Import your LoginScreen
// import 'package:your_app/screens/login_screen.dart'; 
// For now I will assume a class named LoginScreen exists, update the import above.
import '../main.dart'; // Or wherever your LoginScreen is defined
import '../screens/login_screen.dart'; // Import the LoginScreen

class DashboardTopBar extends StatelessWidget {
  final VoidCallback? onMenuTap;

  const DashboardTopBar({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.menu_rounded), onPressed: onMenuTap),
          const SizedBox(width: 16),
          
          // Search Bar
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Language Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFF1F5FF), borderRadius: BorderRadius.circular(8)),
            child: Row(children: const [
              Icon(Icons.public, size: 16, color: Color(0xFFF59E0B)),
              SizedBox(width: 6),
              Text('EN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
            ]),
          ),
          
          const SizedBox(width: 16),
          
          // --- PROFILE DROPDOWN (Updated) ---
          Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 60), // Pushes the menu down slightly
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              tooltip: 'User Menu',
              // This acts as the Trigger Widget
              child: const CircleAvatar(
                backgroundColor: Color(0xFFF59E0B),
                child: Text("A", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              // Menu Items
              itemBuilder: (context) => [
                // 1. Header Item (Non-clickable User Info)
                PopupMenuItem<String>(
                  enabled: false, // Disables click effect
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFFF59E0B),
                          child: Text("A", style: TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text("super-admin", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
                            Text("admin@admin.com", style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 2. Settings
                const PopupMenuItem<String>(
                  value: 'settings',
                  height: 40,
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, size: 20, color: Colors.grey),
                      SizedBox(width: 12),
                      Text("Settings", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                
                // 3. Sign Out
                const PopupMenuItem<String>(
                  value: 'logout',
                  height: 40,
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: Colors.redAccent), // Red icon for logout
                      SizedBox(width: 12),
                      Text("Sign Out", style: TextStyle(fontSize: 14, color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
              // Handle Selection
              onSelected: (value) {
                if (value == 'logout') {
                  _handleLogoutRequest(context);
                } else if (value == 'settings') {
                  // Handle settings navigation
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGOUT LOGIC WITH POPUP ---
  void _handleLogoutRequest(BuildContext context) {
    CustomCenterDialog.show(
      context,
      title: "Sign Out?",
      message: "Are you sure you want to log out of the admin panel?",
      type: DialogType.warning, // Uses your generic Warning style (Blue/Orange)
      confirmText: "Yes, Logout",
      cancelText: "No",
      onConfirm: () async {
        // 1. Clear Session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', false);

        // 2. Navigate
        if (context.mounted) {
           // Replace 'LoginScreen()' with your actual login widget class
           Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false, 
           );
           
           // For testing/example if LoginScreen isn't imported yet:
           print("Logged out successfully");
        }
      },
    );
  }
}