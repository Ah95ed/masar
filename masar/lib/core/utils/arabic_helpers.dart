import 'package:flutter/material.dart';

/// أدوات مساعدة للترجمة والتنسيق العربي
class ArabicHelpers {
  ArabicHelpers._();

  /// ترجمة حالات المهام
  static String translateTaskStatus(String? status) {
    if (status == null) return 'غير محدد';
    switch (status.toLowerCase()) {
      case 'pending':
        return 'قيد الانتظار';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'review':
        return 'قيد المراجعة';
      case 'done':
        return 'مكتملة';
      case 'cancelled':
        return 'ملغاة';
      default:
        return status;
    }
  }

  /// لون حالة المهمة
  static Color getTaskStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'review':
        return Colors.purple;
      case 'done':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// ترجمة أولوية المهمة
  static String translatePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'urgent':
      case 'high':
        return 'عالية';
      case 'medium':
        return 'متوسطة';
      case 'low':
        return 'منخفضة';
      default:
        return priority ?? 'عادية';
    }
  }

  /// لون أولوية المهمة
  static Color getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'urgent':
      case 'high':
        return Colors.red.shade700;
      case 'medium':
        return Colors.amber.shade800;
      case 'low':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  /// ترجمة حالات المواقع
  static String translateSiteStatus(String? status) {
    if (status == null) return 'غير محدد';
    switch (status.toLowerCase()) {
      case 'active':
        return 'نشط';
      case 'completed':
        return 'مكتمل';
      case 'halted':
      case 'paused':
        return 'متوقف مؤقتاً';
      case 'planning':
        return 'قيد التخطيط';
      default:
        return status;
    }
  }

  /// ترجمة حالات الآليات
  static String translateMachineryStatus(String? status) {
    if (status == null) return 'غير محدد';
    switch (status.toLowerCase()) {
      case 'operational':
      case 'active':
        return 'جاهزة للعمل';
      case 'under_maintenance':
      case 'maintenance':
        return 'تحت الصيانة';
      case 'idle':
        return 'متوقفة';
      case 'broken':
        return 'معطلة';
      default:
        return status;
    }
  }

  /// لون حالة الآلية
  static Color getMachineryStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'operational':
      case 'active':
        return Colors.green;
      case 'under_maintenance':
      case 'maintenance':
        return Colors.amber.shade800;
      case 'idle':
        return Colors.blueGrey;
      case 'broken':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// ترجمة فئات المصروفات
  static String translateExpenseCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'materials':
        return 'مواد ومستلزمات';
      case 'labor':
        return 'عمالة وأجور';
      case 'fuel':
        return 'وقود ومحروقات';
      case 'equipment':
        return 'معدات وآليات';
      case 'transport':
        return 'نقل وشحن';
      case 'other':
        return 'مصروفات أخرى';
      default:
        return category ?? 'أخرى';
    }
  }

  /// ترجمة الأدوار
  static String translateRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'manager':
      case 'admin':
        return 'مدير النظام';
      case 'engineer':
        return 'مهندس موقع';
      default:
        return role ?? 'مستخدم';
    }
  }

  /// تنسيق الأرقام والعملة
  static String formatCurrency(dynamic amount) {
    if (amount == null) return '0 ر.س';
    final parsed = double.tryParse(amount.toString()) ?? 0.0;
    return '${parsed.toStringAsFixed(parsed.truncateToDouble() == parsed ? 0 : 2)} ر.س';
  }
}
