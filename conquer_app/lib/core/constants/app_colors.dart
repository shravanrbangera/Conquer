import 'package:flutter/material.dart';

/// CONQUER Design System Palette — High-contrast Cyberpunk Adventure
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color bgDeep = Color(0xFF030712); // Deep obsidian
  static const Color bgSurface = Color(0xFF0B1220); // Dark navy slate
  static const Color bgSurfaceLighter = Color(0xFF131D31);
  static const Color bgGlass = Color(0xCC0B1220);

  // Neon Accents
  static const Color neonCyan = Color(0xFF00F0FF); // Primary tactical accent
  static const Color neonBlue = Color(0xFF3B82F6); // Player's territory
  static const Color neonPink = Color(0xFFFF007A); // Rival territory
  static const Color neonCrimson = Color(0xFFFF0055); // Attacking / Alert
  static const Color neonEmerald = Color(0xFF00FF9D); // Success / Loop closed
  static const Color neonGold = Color(0xFFFFD700); // XP / Coins / Prestige
  static const Color neonPurple = Color(0xFFB026FF); // Exploration / Rare

  // Text Colors
  static const Color textWhite = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);

  // Borders & Glows
  static const Color borderSubtle = Color(0x26FFFFFF);
  static const Color borderCyan = Color(0x6600F0FF);
  static const Color borderEmerald = Color(0x6600FF9D);
  static const Color borderCrimson = Color(0x66FF0055);

  // Territory Colors
  static const Color playerTerritory = Color(0x553B82F6);
  static const Color enemyTerritory = Color(0x55FF0055);
  static const Color contestedTerritory = Color(0x55FFD700);
}
