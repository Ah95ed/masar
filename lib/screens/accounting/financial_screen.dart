import '../../widgets/auto_refresh_wrapper.dart';
import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../services/admin_api.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class FinancialScreen extends StatefulWidget {
  final AdminApi api;

  const FinancialScreen({super.key, required this.api});

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ✅ جلب البيانات من السيرفر
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await widget.api.get('financial');
      if (!mounted) return;
      setState(() {
        _data = res is Map<String, dynamic> ? res : Map<String, dynamic>.from(res as Map);
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
        _error = 'حدث خطأ أثناء تحميل ميزان المراجعة والتقارير المالية';
        _loading = false;
      });
    }
  }

  Future<void> _loadSilently() async {
    try {
      final res = await widget.api.get('financial');
      if (!mounted) return;
      setState(() {
        _data = res is Map<String, dynamic> ? res : Map<String, dynamic>.from(res as Map);
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
        title: const Text('ميزان المراجعة والتقارير المالية'),
        // ⚠️ لا يوجد زر Refresh في الـ AppBar
      ),
      body: _loading
          ? const LoadingState(message: 'جاري احتساب المجاميع والأرصدة المالية...')
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primaryTeal,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      _buildTrialBalanceSection(),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totals = _data?['totals'] as Map<String, dynamic>? ?? {};
    final totalDebit = totals['total_debit']?.toString() ?? '0';
    final totalCredit = totals['total_credit']?.toString() ?? '0';
    final isBalanced = totalDebit == totalCredit;

    return Card(
      elevation: 0,
      color: isBalanced ? AppTheme.surface : AppTheme.dangerLight.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isBalanced ? AppTheme.border : AppTheme.danger),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'حالة التوازن المحاسبي',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBalanced ? AppTheme.successLight : AppTheme.dangerLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isBalanced ? 'متوازن دقيق ✓' : 'غير متوازن ⚠️',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isBalanced ? AppTheme.success : AppTheme.danger,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('إجمالي المدين',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        '$totalDebit د.ع',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: AppTheme.border),
                Expanded(
                  child: Column(
                    children: [
                      const Text('إجمالي الدائن',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        '$totalCredit د.ع',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrialBalanceSection() {
    final rows = _data?['accounts'] as List? ?? [];

    if (rows.isEmpty) {
      return const EmptyState(
        title: 'لا توجد بيانات للأرصدة',
        message: 'لا تتوفر حركة مالية مرحّلة لحسابات دليل الحسابات',
        icon: Icons.account_balance_wallet_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أرصدة الحسابات ومجاميع ميزان المراجعة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
            itemBuilder: (context, index) {
              final row = rows[index] as Map<String, dynamic>;
              final code = row['code']?.toString() ?? '';
              final name = row['name']?.toString() ?? '';
              final debit = row['debit']?.toString() ?? '0';
              final credit = row['credit']?.toString() ?? '0';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('مدين: $debit',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.primaryDark)),
                        Text('دائن: $credit',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
