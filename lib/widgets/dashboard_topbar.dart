import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_center_dialog.dart';
import '../screens/login_screen.dart'; 
import '../repositories/auth_repository.dart';
import '../config/admin_navigation.dart'; // Ensure this points to your extracted NavItem file
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/permission_manager.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;

class DashboardTopBar extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final ValueChanged<String>? onNav; // Callback to handle navigation from search

  const DashboardTopBar({super.key, this.onMenuTap, this.onNav});

  @override
  State<DashboardTopBar> createState() => _DashboardTopBarState();
}

class _DashboardTopBarState extends State<DashboardTopBar> {
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<NavItem> _searchResults = [];

  String _adminName = "Admin";
  String _adminEmail = "admin@admin.com";
  String _adminRole = "super-admin";

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  Future<void> _loadIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminEmail = prefs.getString('admin_email') ?? 'admin@admin.com';
      _adminName = prefs.getString('admin_name') ?? 'Admin';
      _adminRole = prefs.getString('admin_role') ?? 'super-admin';
    });
  }

  @override
  void dispose() {
    _hideOverlay();
    _searchController.dispose();
    super.dispose();
  }

  // --- SEARCH OVERLAY LOGIC ---
  void _showOverlay() {
    _hideOverlay();
    if (_searchResults.isEmpty) return;

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 400, // Matches search bar width
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 45), // Pushes dropdown below the search bar
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Container(
              color: Colors.white,
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (context, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  return ListTile(
                    leading: Icon(item.icon, size: 20, color: const Color(0xFFF59E0B)),
                    title: Text(item.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    onTap: () {
                      widget.onNav?.call(item.route);
                      _searchController.clear();
                      _hideOverlay();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // =========================
  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      _hideOverlay();
      return;
    }

    setState(() {
      _searchResults = AdminNavigation.searchRegistry.where((item) {
        final matches = item.label.toLowerCase().contains(query.toLowerCase());

        final hasPermission = item.permissionKey == null
            ? true
            : PermissionManager.can(item.permissionKey!);

        return matches && hasPermission;
      }).toList();
    });

    _showOverlay();
  }

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
          IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.onMenuTap),
          const SizedBox(width: 16),
          
          // --- SEARCH BAR SECTION ---
          Expanded(
            child: CompositedTransformTarget(
              link: _layerLink,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search dashboard menus...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
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
          
          // --- PROFILE DROPDOWN ---
          Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              tooltip: 'User Menu',
              child: CircleAvatar(
                backgroundColor: const Color(0xFFF59E0B),
                child: Text(_adminName.isNotEmpty ? _adminName[0].toUpperCase() : "A", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false, 
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFF59E0B),
                          child: Text(_adminName.isNotEmpty ? _adminName[0].toUpperCase() : "A", style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_adminName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
                            Text(_adminEmail, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
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
                const PopupMenuItem<String>(
                  value: 'logout',
                  height: 40,
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: Colors.redAccent),
                      SizedBox(width: 12),
                      Text("Sign Out", style: TextStyle(fontSize: 14, color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'logout') {
                  _handleLogoutRequest(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGOUT LOGIC ---
  void _handleLogoutRequest(BuildContext context) {
    CustomCenterDialog.show(
      context,
      title: "Sign Out?",
      message: "Are you sure you want to log out of the admin panel?",
      type: DialogType.warning,
      confirmText: "Yes, Logout",
      cancelText: "No",
      onConfirm: () async {
        await PermissionManager.clear();

        await AuthRepository().logout();
        if (kIsWeb) {
          html.window.location.reload();
          return;
        }
        if (context.mounted) {
           Navigator.of(context).pushAndRemoveUntil(
             MaterialPageRoute(builder: (context) => const LoginScreen()),
             (Route<dynamic> route) => false, 
           );
        }
      },
    );
  }
}
