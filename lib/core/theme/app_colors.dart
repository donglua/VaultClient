import 'package:flutter/material.dart';

/// 全局颜色 Token，对齐 Stitch 设计规范
class AppColors {
  // 品牌主色
  static const brandPrimary = Color(0xFF0053D4);
  static const brandPrimaryAlt = Color(0xFF1E6BFF);
  static const brandPrimaryPressed = Color(0xFF1552CC);
  static const brandPrimaryContainer = Color(0xFFE8F0FF);
  static const brandSecondary = Color(0xFF0EA5A6);
  static const brandAccent = Color(0xFFF59E0B);

  // 语义色
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const error = Color(0xFFDC2626);
  static const info = Color(0xFF0EA5E9);

  // 亮色中性色
  static const lightBg = Color(0xFFF8FAFC);       // 页面背景
  static const lightSurface = Color(0xFFFFFFFF);  // 卡片/组件
  static const lightSurfaceLow = Color(0xFFF2F3FF); // 侧栏背景
  static const lightSurfaceHigh = Color(0xFFEAEDFF); // 高亮背景
  static const lightBorder = Color(0xFFCBD5E1);
  static const lightTextPrimary = Color(0xFF131B2E);
  static const lightTextSecondary = Color(0xFF475569);
  static const lightTextTertiary = Color(0xFF64748B);

  // 暗色中性色
  static const darkBg = Color(0xFF0B1220);
  static const darkSurface = Color(0xFF111827);
  static const darkSurfaceElevated = Color(0xFF1F2937);
  static const darkBorder = Color(0xFF334155);
  static const darkTextPrimary = Color(0xFFE5E7EB);
  static const darkTextSecondary = Color(0xFF94A3B8);
}
