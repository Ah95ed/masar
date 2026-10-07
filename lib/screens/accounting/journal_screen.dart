import '../../widgets/auto_refresh_wrapper.dart';
import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/journal_entry.dart';
import '../../services/admin_api.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class JournalScreen extends StatefulWidget {
  final AdminApi api;

  const JournalScreen({super.key, required this.api});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<JournalEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ✅ جلب القيود من السيرفر
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await widget.api.get('journal');
      if (!mounted) return;
      setState(() {
        _entries = (res as List).map((e) => JournalEntry.fromJson(e)).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'حدث خطأ أثناء تحميل قيود اليومية';
        _loading = false;
      });
    }
  }

  Future<void> _loadSilently() async {
    try {
      final res = await widget.api.get('journal');
      if (!mounted) return;
      setState(() {
        _entries = (res as List).map((e) => JournalEntry.fromJson(e)).toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AutoRefreshWrapper(
      interval: const Duration(seconds: 60),
      onRefresh: _loadSilently,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('سجل قيود اليومية العامة'),
        // ⚠️ لا يوجد زر Refresh في الـ AppBar
      ),
      body: _loading
          ? const LoadingState(message: 'جاري تحميل القيود المحاسبية...')
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primaryTeal,
                  child: _entries.isEmpty
                      ? const EmptyState(
                          title: 'لا توجد قيود يومية',
                          message: 'لم يتم تسجيل أي قيود محاسبية حتى الآن',
                          icon: Icons.receipt_long_outlined,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            return _buildEntryCard(entry);
                          },
                        ),
                ),
      ),
    );
  }

  Widget _buildEntryCard(JournalEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Row(
          children: [
            Text(
              'قيد #${entry.entryNumber}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: entry.status == 'posted' ? AppTheme.successLight : AppTheme.warningLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                entry.status == 'posted' ? 'مرحّل' : 'مسودة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: entry.status == 'posted' ? AppTheme.success : AppTheme.warning,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'التاريخ: ${entry.entryDate}  ·  الإجمالي: ${entry.totalDebit.toStringAsFixed(0)} د.ع',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
            ),
            if (entry.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                entry.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ],
        ),
        children: [
          if (entry.lines.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('لا توجد بنود تفصيلية لهذا القيد',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.textMuted)),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ...entry.lines.map((l) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.accountName ?? 'حساب #${l.accountId}',
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                            ),
                          ),
                          if (l.debit > 0)
                            Text(
                              'مدين: ${l.debit.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          if (l.credit > 0)
                            Text(
                              'دائن: ${l.credit.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentCyan,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
