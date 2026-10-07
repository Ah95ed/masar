import 'package:flutter/material.dart';

const kInk       = Color(0xFF102b3f);
const kInkSoft   = Color(0xFF193e54);
const kCyan      = Color(0xFF078da5);
const kCyanPale  = Color(0xFFe7f5f6);
const kGreen     = Color(0xFF13805d);
const kGreenPale = Color(0xFFe6f5ed);
const kAmber     = Color(0xFFb76b08);
const kAmberPale = Color(0xFFfff3dd);
const kRed       = Color(0xFFbd3f42);
const kRedPale   = Color(0xFFfae9e9);
const kPaper     = Color(0xFFf4f7f8);
const kLine      = Color(0xFFdce5e8);
const kMuted     = Color(0xFF647782);

class AppConstants {
  AppConstants._();

  static const String appName = 'Maxlond Management';
  static const String appSubtitle = 'إدارة المشاريع والتقارير والحركات';
  static const String appVersion = '2.0.0';

  // Server Origin
  static const String origin = 'https://vehiclegate.ghusun.net';

  // Device Info
  static const String deviceInfo = 'Maxlond Management / Flutter';

  // Required Role
  static const String requiredRole = 'admin';

  // User-Agent
  static const String userAgent =
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
}