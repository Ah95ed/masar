import 'package:flutter/material.dart';
import '../core/constants.dart';

class StateView extends StatelessWidget {
  final bool loading;
  final String? error;
  final bool empty;
  final Widget child;
  final VoidCallback onRetry;
  final String emptyMessage;

  const StateView({
    super.key,
    required this.loading,
    required this.error,
    required this.empty,
    required this.child,
    required this.onRetry,
    this.emptyMessage = 'لا توجد بيانات',
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: kCyan));
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: kRed),
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(backgroundColor: kInk),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          ),
        ),
      );
    }
    if (empty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inbox_outlined, size: 64, color: kMuted),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: const TextStyle(fontFamily: 'Cairo', color: kMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    return child;
  }
}