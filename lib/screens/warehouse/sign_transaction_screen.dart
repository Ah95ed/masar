import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/warehouse_move.dart';
import '../../services/admin_api.dart';
import '../../services/session_manager.dart';
import '../../widgets/signature_canvas.dart';

class SignTransactionScreen extends StatefulWidget {
  final AdminApi api;
  final WarehouseMove move;

  const SignTransactionScreen({
    super.key,
    required this.api,
    required this.move,
  });

  @override
  State<SignTransactionScreen> createState() => _SignTransactionScreenState();
}

class _SignTransactionScreenState extends State<SignTransactionScreen> {
  final _signerNameCtrl = TextEditingController();
  Uint8List? _signatureBytes;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = SessionManager.instance.user;
    _signerNameCtrl.text = user?['full_name']?.toString() ?? 'المدير العام';
  }

  @override
  void dispose() {
    _signerNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitSignature() async {
    final signerName = _signerNameCtrl.text.trim();
    if (signerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم الموقّع', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    if (_signatureBytes == null || _signatureBytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى التوقيع في المساحة المخصصة أولاً', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final base64Signature = 'data:image/png;base64,${base64Encode(_signatureBytes!)}';
      await widget.api.post('transaction-sign', {
        'move_id': widget.move.id,
        'signer_name': signerName,
        'signature_data': base64Signature,
      });

      if (!mounted) return;
      // ✅ القاعدة الذهبية: إغلاق الشاشة وإرجاع true لجلب البيانات الحقيقية من السيرفر
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      if (e.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم توقيع واعتماد هذه الحركة المخزنية مسبقاً',
                style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppTheme.warning,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message, style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ غير متوقع أثناء حفظ التوقيع', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.move;

    return Scaffold(
      appBar: AppBar(
        title: Text('توقيع حركة مخزنية #${m.id}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ملخص الحركة
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.itemName ?? 'مادة مخزنية',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'النوع: ${m.type == "out" ? "صرف موقع" : m.type == "in" ? "إدخال مخزني" : "تسوية"}  ·  الكمية: ${m.quantity} ${m.unit ?? ""}',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  if (m.siteName != null && m.siteName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'الموقع المستلم: ${m.siteName}',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.accentCyan),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _signerNameCtrl,
            decoration: const InputDecoration(
              labelText: 'اسم الموقّع / المستلم *',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'التوقيع الحي (Signature Canvas):',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          SignatureCanvasWidget(
            height: 220,
            onSigned: (bytes) {
              setState(() => _signatureBytes = bytes);
            },
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _submitting ? null : _submitSignature,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.draw_rounded),
            label: const Text(
              'تأكيد وحفظ التوقيع الرقمي',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryDark,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}