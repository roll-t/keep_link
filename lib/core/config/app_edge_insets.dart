import 'package:flutter/material.dart';

/// Cấu hình padding dùng chung toàn app
class AppEdgeInsets {
  // All
  static const EdgeInsets all4 = EdgeInsets.all(4);
  static const EdgeInsets all6 = EdgeInsets.all(6);
  static const EdgeInsets all8 = EdgeInsets.all(8);
  static const EdgeInsets all12 = EdgeInsets.all(12);
  static const EdgeInsets all16 = EdgeInsets.all(16);
  static const EdgeInsets all20 = EdgeInsets.all(20);
  static const EdgeInsets all24 = EdgeInsets.all(24);
  static const EdgeInsets all32 = EdgeInsets.all(32);

  // Vertical only
  static const EdgeInsets v4 = EdgeInsets.symmetric(vertical: 4);
  static const EdgeInsets v8 = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets v12 = EdgeInsets.symmetric(vertical: 12);
  static const EdgeInsets v16 = EdgeInsets.symmetric(vertical: 16);
  static const EdgeInsets v20 = EdgeInsets.symmetric(vertical: 20);
  static const EdgeInsets v24 = EdgeInsets.symmetric(vertical: 24);

  // Horizontal only
  static const EdgeInsets h4 = EdgeInsets.symmetric(horizontal: 4);
  static const EdgeInsets h8 = EdgeInsets.symmetric(horizontal: 8);
  static const EdgeInsets h12 = EdgeInsets.symmetric(horizontal: 12);
  static const EdgeInsets h16 = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets h20 = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets h24 = EdgeInsets.symmetric(horizontal: 24);

  // Page default
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: 16);

  // --- Kết hợp custom ---
  static const EdgeInsets v16h14 = EdgeInsets.symmetric(vertical: 16, horizontal: 14);
  static const EdgeInsets v8h16 = EdgeInsets.symmetric(vertical: 8, horizontal: 16);
  static const EdgeInsets v8h12 = EdgeInsets.symmetric(vertical: 8, horizontal: 12);
  static const EdgeInsets v6h12 = EdgeInsets.symmetric(vertical: 6, horizontal: 12);
  static const EdgeInsets v4h8 = EdgeInsets.symmetric(vertical: 4, horizontal: 8);
  static const EdgeInsets v12h16 = EdgeInsets.symmetric(vertical: 12, horizontal: 16);
  static const EdgeInsets v16h20 = EdgeInsets.symmetric(vertical: 16, horizontal: 20);
  static const EdgeInsets v20h16 = EdgeInsets.symmetric(vertical: 20, horizontal: 16);
  static const EdgeInsets v24h16 = EdgeInsets.symmetric(vertical: 24, horizontal: 16);
  static const EdgeInsets v16h24 = EdgeInsets.symmetric(vertical: 16, horizontal: 24);
  static const EdgeInsets v20h24 = EdgeInsets.symmetric(vertical: 20, horizontal: 24);
  static const EdgeInsets v24h20 = EdgeInsets.symmetric(vertical: 24, horizontal: 20);
  static const EdgeInsets v32h16 = EdgeInsets.symmetric(vertical: 32, horizontal: 16);

  // Padding riêng (custom)
  static const EdgeInsets h16b30 = EdgeInsets.only(left: 16, right: 16, bottom: 30);
}
