import 'package:flutter/material.dart';
import '../core/constants.dart';

/// بطاقة تنبيه تفاعلية تطفو أسفل الشاشة بنعومة وتأثيرات عصرية (In-App Toast Banner)
class InAppNotificationToast {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    String? type,
    VoidCallback? onTap,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    Color accentColor = kCyan;
    IconData icon = Icons.notifications_active_outlined;

    final t = type?.toLowerCase() ?? '';
    if (t.contains('approved') || t.contains('success')) {
      accentColor = kGreen;
      icon = Icons.check_circle_outline;
    } else if (t.contains('rejected') || t.contains('cancel') || t.contains('danger')) {
      accentColor = kRed;
      icon = Icons.error_outline;
    } else if (t.contains('task') || t.contains('plan')) {
      accentColor = kCyan;
      icon = Icons.assignment_outlined;
    } else if (t.contains('broadcast') || t.contains('alert') || t.contains('warning')) {
      accentColor = kAmber;
      icon = Icons.campaign_outlined;
    }

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        bottom: 24,
        left: 20,
        right: 20,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                builder: (context, val, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - val) * 40),
                    child: Opacity(opacity: val.clamp(0.0, 1.0), child: child),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: kInk,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withOpacity(0.55), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: accentColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onTap != null) ...[
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            entry.remove();
                            if (_currentEntry == entry) _currentEntry = null;
                            onTap();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text(
                            'معاينة',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
                        onPressed: () {
                          entry.remove();
                          if (_currentEntry == entry) _currentEntry = null;
                        },
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 5000), () {
      if (entry.mounted && _currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    });
  }
}