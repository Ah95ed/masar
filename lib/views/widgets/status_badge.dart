import 'package:flutter/material.dart';
import '../../core/utils/arabic_helpers.dart';

/// شارة حالة ملونة بأناقة وبأبعاد متناسقة تدعم التوليد التلقائي من اسم الحالة
class StatusBadge extends StatelessWidget {
  final String? status;
  final String? label;
  final Color? color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    this.status,
    this.label,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = label ?? _resolveLabel(status);
    final effectiveColor = color ?? _resolveColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: effectiveColor),
            const SizedBox(width: 4),
          ],
          Text(
            effectiveLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }

  static String _resolveLabel(String? status) {
    if (status == null) return 'غير محدد';
    switch (status.toLowerCase()) {
      case 'active':
        return 'نشط';
      case 'inactive':
        return 'معطل';
      case 'operational':
        return 'تعمل';
      case 'under_maintenance':
        return 'تحت الصيانة';
      case 'completed':
      case 'done':
        return 'مكتمل';
      case 'pending':
        return 'قيد الانتظار';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'cancelled':
        return 'ملغي';
      case 'approved':
        return 'معتمد';
      case 'rejected':
        return 'مرفوض';
      case 'pending_approval':
        return 'بانتظار الاعتماد';
      default:
        return ArabicHelpers.translateTaskStatus(status);
    }
  }

  static Color _resolveColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'active':
      case 'operational':
      case 'completed':
      case 'done':
      case 'approved':
        return const Color(0xFF10B981);
      case 'inactive':
      case 'cancelled':
      case 'rejected':
      case 'broken':
        return const Color(0xFFEF4444);
      case 'under_maintenance':
      case 'pending':
      case 'pending_approval':
        return const Color(0xFFF59E0B);
      case 'in_progress':
        return const Color(0xFF0284C7);
      default:
        return const Color(0xFF64748B);
    }
  }
}
