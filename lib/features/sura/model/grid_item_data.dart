import 'package:flutter/material.dart';

class GridItemData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  GridItemData({required this.icon, required this.label, required this.onTap});
}