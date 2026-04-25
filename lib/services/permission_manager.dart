import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import '../models/permission_module.dart';

class PermissionManager {
  static final Set<String> _modules = {};

  static const String _storageKey = "user_permissions";

  // ================================
  // REACTIVE STATE (IMPORTANT FIX)
  // ================================
  static final RxBool ready = false.obs;

  // ================================
  // SET FROM API
  // ================================
  static void set(List<UserModule> list) {
    _modules.clear();

    for (var item in list) {
      if (item.isActive) {
        _modules.add(item.moduleIdentifier);
      }
    }

    ready.value = true; // API loaded → ready
  }

  // ================================
  // CHECK PERMISSION
  // ================================
  static bool can(String moduleId) {
    return _modules.contains(moduleId);
  }

  // ================================
  // SAVE TO LOCAL STORAGE
  // ================================
  static Future<void> saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _storageKey,
        jsonEncode(_modules.toList()),
      );
    } catch (e) {
      print("SAVE PERMISSION ERROR: $e");
    }
  }

  // ================================
  // RESTORE FROM LOCAL STORAGE
  // ================================
  static Future<void> loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);

      if (data == null) {
        ready.value = true; // still allow UI
        return;
      }

      final List decoded = jsonDecode(data);

      _modules
        ..clear()
        ..addAll(decoded.cast<String>());

      debugPrintPermissions();

    } catch (e) {
      _modules.clear();
      print("LOAD PERMISSION ERROR: $e");
    } finally {
      ready.value = true; // ALWAYS unlock UI
    }
  }

  // ================================
  // CLEAR (LOGOUT)
  // ================================
  static Future<void> clear() async {
    _modules.clear();
    ready.value = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  // ================================
  // DEBUG
  // ================================
  static void debugPrintPermissions() {
    // ignore: avoid_print
    print("ACTIVE MODULES => $_modules");
  }

  // ================================
  // HELPER (optional use in UI)
  // ================================
  static bool get isReady => ready.value;
}