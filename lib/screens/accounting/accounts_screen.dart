import '../../widgets/auto_refresh_wrapper.dart';
import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/account.dart';
import '../../services/admin_api.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class AccountsScreen extends StatefulWidget {
  final AdminApi api;

  const AccountsScreen({super.key, required this.api});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<Account> _accounts = [];
  bool _loading = true;
  String? _error;
  String _filterType = 'all';

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
      final res = await widget.api.get('accounts');
      if (!mounted) return;
      setState(() {
        _accounts = (res as List).map((e) => Account.fromJson(e)).toList();
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
        _error = 'حدث خطأ أثناء تحميل شجرة الحسابات';
        _loading = false;
      });
    }
  }

  List<Account> get _filteredAccounts {
    if (_filterType == 'all') return _accounts;
    return _accounts.where((a) => a.type == _filterType).toList();
  }

  Future<void> _loadSilently() async {
    try {
      final res = await widget.api.get('accounts');
      if (!mounted) return;
      setState(() {
        _accounts = (res as List).map((e) => Account.fromJson(e)).toList();
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
        title: const Text('دليل الحسابات المالي'),
        // ⚠️ لا يوجد زر Refresh في الـ AppBar
      ),
      body: _loading
          ? const LoadingState(message: 'جاري تحميل شجرة الحسابات...')
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primaryTeal,
                  child: Column(
                    children: [
                      _buildFiltersHeader(),
                      Expanded(
                        child: _filteredAccounts.isEmpty
                            ? const EmptyState(
                                title: 'لا توجد حسابات',
                                message: 'لم يتم العثور على أي حسابات بالفئة المحددة',
                                icon: Icons.account_balance_outlined,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _filteredAccounts.length,
                                itemBuilder: (context, index) {
                                  final acc = _filteredAccounts[index];
                                  return _buildAccountTile(acc);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildFiltersHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTypeChip('all', 'الكل (${_accounts.length})'),
            _buildTypeChip('asset', 'الأصول'),
            _buildTypeChip('liability', 'الخصوم'),
            _buildTypeChip('equity', 'حقوق الملكية'),
            _buildTypeChip('revenue', 'الإيرادات'),
            _buildTypeChip('expense', 'المصروفات'),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
        selected: isSelected,
        selectedColor: AppTheme.primaryDark,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => setState(() => _filterType = type),
      ),
    );
  }

  Widget _buildAccountTile(Account acc) {
    String typeArabic = acc.type;
    switch (acc.type) {
      case 'asset':
        typeArabic = 'أصل';
        break;
      case 'liability':
        typeArabic = 'خصم';
        break;
      case 'equity':
        typeArabic = 'حق ملكية';
        break;
      case 'revenue':
        typeArabic = 'إيراد';
        break;
      case 'expense':
        typeArabic = 'مصروف';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryDark.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            acc.code,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppTheme.primaryDark,
            ),
          ),
        ),
        title: Text(
          acc.name,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          typeArabic + (acc.parentName != null ? ' · تابع لـ: ${acc.parentName}' : ''),
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.textSecondary),
        ),
        trailing: Text(
          '${acc.balance.toStringAsFixed(0)} د.ع',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: acc.balance >= 0 ? AppTheme.textPrimary : AppTheme.danger,
          ),
        ),
      ),
    );
  }
}
