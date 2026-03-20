import 'package:flutter/material.dart';

class NavItem {
  final String label;
  final String route;
  final IconData icon;
  final List<String> keywords; // Extra words to help search

  NavItem({
    required this.label, 
    required this.route, 
    required this.icon, 
    this.keywords = const []
  });
}