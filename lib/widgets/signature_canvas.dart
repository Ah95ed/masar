import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../core/theme.dart';

class SignatureCanvasWidget extends StatefulWidget {
  final ValueChanged<Uint8List?> onSigned;
  final VoidCallback? onClear;
  final double height;

  const SignatureCanvasWidget({
    super.key,
    required this.onSigned,
    this.onClear,
    this.height = 200,
  });

  @override
  State<SignatureCanvasWidget> createState() => _SignatureCanvasWidgetState();
}

class _SignatureCanvasWidgetState extends State<SignatureCanvasWidget> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: AppTheme.primaryDark,
      exportBackgroundColor: Colors.white,
    );
    _controller.addListener(_handleSignatureChange);
  }

  void _handleSignatureChange() async {
    if (_controller.isNotEmpty) {
      final bytes = await _controller.toPngBytes();
      widget.onSigned(bytes);
    } else {
      widget.onSigned(null);
    }
  }

  void _clear() {
    _controller.clear();
    widget.onSigned(null);
    widget.onClear?.call();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleSignatureChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Signature(
                controller: _controller,
                backgroundColor: Colors.white,
                height: widget.height,
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Text(
                  'وقع هنا',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppTheme.textMuted.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.clear, size: 16, color: AppTheme.danger),
              label: const Text(
                'مسح التوقيع',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppTheme.danger,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}