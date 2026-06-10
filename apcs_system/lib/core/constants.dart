import 'package:flutter/material.dart';
import '../config/environment.dart';

class AppColors {
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF1A3A8F);
  static const Color primaryLight = Color(0xFF93C5FD);
  static const Color accent = Color(0xFF2563EB);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFEAB308);
  static const Color error = Color(0xFFDC2626);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);

  static const Color priorityHigh = Color(0xFFE53935);
  static const Color priorityMedium = Color(0xFFF9A825);
  static const Color priorityLow = Color(0xFF2E7D32);
}

class ApiConfig {
  // ============================================
  // Используется конфигурация из Environment
  // ============================================
  
  // Текущий API URL (из файла конфигурации)
  static const String baseUrl = Environment.apiBaseUrl;
  
  // Альтернативные URL (для справки)
  // Android эмулятор: http://10.0.2.2:8080/api/v1
  // iOS симулятор: http://localhost:8080/api/v1
  // Реальное устройство: http://192.168.1.100:8080/api/v1 (измените IP)
  // Production: https://api.example.com/api/v1 (измените домен)
}
