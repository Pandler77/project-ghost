import 'package:flutter/material.dart';

class ProtocolColors {
  ProtocolColors._();

  static const List<int> available = [
    0xFF6750A4, // Purple
    0xFF1565C0, // Blue
    0xFF00838F, // Teal
    0xFF2E7D32, // Green
    0xFF558B2F, // Lime green
    0xFFF9A825, // Yellow
    0xFFEF6C00, // Orange
    0xFFC62828, // Red
    0xFFAD1457, // Pink
    0xFF6A1B9A, // Deep purple
    0xFF5D4037, // Brown
    0xFF455A64, // Slate
  ];

  static Color fromValue(int value) {
    return Color(value);
  }
}