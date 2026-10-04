import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_helpers.dart';
import '../../models/financial_model.dart';
import '../../providers/management_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_widget.dart';

/// شاشة الحسابات والمالية ودليل الحسابات وقيود اليومية للمدير العام
class FinancialScreen extends StatefulWidget {
  const FinancialScreen({super.key});

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ManagementProvider>();
      p.fetchFinancialData();
      p.fetchSites();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==================== حوار إنشاء/تعديل حساب مالي ====================
  void _showAccountDialog([AccountModel? account]) {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(text: account?.code);
    final nameCtrl = TextEditingController(text: account?.name);
    final descCtrl = TextEditingController(text: account?.description);
    String type = account?.type ?? 'expense';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(account == null ? 'إضافة حساب جديد إلى الدليل' : 'تعديل بيانات الحساب'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                        controller: codeCtrl,
                        style: const TextStyle(fontSize: 12.5),
                        decoration: const InputDecoration(hintText: 'رقم الحساب (مثال: 1010) *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: nameCtrl,
                        style: const TextStyle(fontSize: 12.5),
                        decoration: const InputDecoration(hintText: 'اسم الحساب المالي *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                      ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: type,
                    decoration: const InputDecoration(hintText: 'نوع الحساب'),
                    items: const [
                      DropdownMenuItem(value: 'asset', child: Text('أصول (Asset)')),
                      DropdownMenuItem(value: 'liability', child: Text('خصوم والتزامات (Liability)')),
                      DropdownMenuItem(value: 'equity', child: Text('حقوق ملكية ورأس مال (Equity)')),
                      DropdownMenuItem(value: 'revenue', child: Text('إيرادات ومستخلصات (Revenue)')),
                      DropdownMenuItem(value: 'expense', child: Text('مصروفات وتكاليف (Expense)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => type = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'الوصف أو الغرض من الحساب'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final payload = {
                    if (account != null) 'id': account.id,
                    'code': codeCtrl.text.trim(),
                    'name': nameCtrl.text.trim(),
                    'type': type,
                    if (descCtrl.text.isNotEmpty) 'description': descCtrl.text.trim(),
                  };

                  final ok = await context.read<ManagementProvider>().saveAccount(payload);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حفظ الحساب المالي بنجاح.'), backgroundColor: AppTheme.successColor),
                    );
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== حوار حذف حساب مالي (مع قاعدة منع الحذف إن كان مستخدماً) ====================
  void _confirmDeleteAccount(AccountModel account) {
    if (account.hasJournalEntries) {
      showDialog(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.block_rounded, color: AppTheme.dangerColor),
                SizedBox(width: 8),
                Text('غير مسموح بحذف الحساب'),
              ],
            ),
            content: Text(
              'لا يمكن حذف الحساب "${account.name}" (${account.code}) لأن له قيود يومية وحركات مسجلة بالنظام.\nتنص القواعد المحاسبية على وجوب بقاء الحساب لسلامة الميزانية وسجل المراجعة.',
              style: const TextStyle(height: 1.4),
            ),
            actions: [
              ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً')),
            ],
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الحساب المالي'),
          content: Text('هل أنت متأكد من حذف الحساب "${account.name}" (${account.code}) نهائياً؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await context.read<ManagementProvider>().deleteAccount(account.id);
                if (mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف الحساب بنجاح.'), backgroundColor: AppTheme.successColor),
                  );
                }
              },
              child: const Text('تأكيد الحذف'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== حوار إنشاء قيد يومية متوازن ====================
  void _showCreateJournalEntryDialog([JournalEntryModel? reverseFrom]) {
    final formKey = GlobalKey<FormState>();
    final descCtrl = TextEditingController(
      text: reverseFrom != null ? 'قيد عكسي لتصحيح القيد #${reverseFrom.entryNumber}: ${reverseFrom.description}' : '',
    );
    final dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final prov = context.read<ManagementProvider>();

    int? selectedSiteId = reverseFrom?.siteId ?? (prov.sites.isNotEmpty ? prov.sites.first.id : null);

    // تجهيز سطور القيد
    List<Map<String, dynamic>> lines = [];
    if (reverseFrom != null && reverseFrom.lines.isNotEmpty) {
      // عكس المدين والدائن
      for (var l in reverseFrom.lines) {
        lines.add({
          'account_id': l.accountId,
          'debit': l.credit,
          'credit': l.debit,
          'description': 'عكس طرف القيد #${reverseFrom.entryNumber}',
        });
      }
    } else {
      // سطرين افتراضيين (طرف مدين وطرف دائن)
      final firstAcc = prov.accounts.isNotEmpty ? prov.accounts.first.id : 0;
      final secondAcc = prov.accounts.length > 1 ? prov.accounts[1].id : firstAcc;
      lines = [
        {'account_id': firstAcc, 'debit': 0.0, 'credit': 0.0, 'description': ''},
        {'account_id': secondAcc, 'debit': 0.0, 'credit': 0.0, 'description': ''},
      ];
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          double totalDebit = lines.fold(0.0, (s, l) => s + (double.tryParse(l['debit'].toString()) ?? 0.0));
          double totalCredit = lines.fold(0.0, (s, l) => s + (double.tryParse(l['credit'].toString()) ?? 0.0));
          bool isBalanced = (totalDebit - totalCredit).abs() < 0.01 && totalDebit > 0;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(reverseFrom != null ? 'إنشاء قيد عكسي تصحيحي' : 'إنشاء قيد يومية محاسبي'),
              content: SizedBox(
                width: 540,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: dateCtrl,
                          style: const TextStyle(fontSize: 12.5),
                          decoration: const InputDecoration(hintText: 'تاريخ القيد (YYYY-MM-DD) *'),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: selectedSiteId,
                          decoration: const InputDecoration(hintText: 'المشروع المرتبط (اختياري)'),
                          items: prov.sites
                              .map((s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                  ))
                              .toList(),
                          onChanged: (val) => setDialogState(() => selectedSiteId = val),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: descCtrl,
                          style: const TextStyle(fontSize: 12.5),
                          decoration: const InputDecoration(labelText: 'البيان وشرح القيد المحاسبي *'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 14),
                        const Text('أطراف القيد (المدين والدائن):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        ...lines.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final line = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      isExpanded: true,
                                      value: line['account_id'],
                                      decoration: const InputDecoration(
                                        hintText: 'اختر الحساب',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      ),
                                      items: prov.accounts
                                          .map((a) => DropdownMenuItem(
                                                value: a.id,
                                                child: Text(
                                                  '${a.code} - ${a.name}',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (v) => setDialogState(() => line['account_id'] = v),
                                    ),
                                  ),
                                  if (lines.length > 2) ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                                      tooltip: 'حذف الطرف',
                                      onPressed: () {
                                        setDialogState(() => lines.removeAt(idx));
                                      },
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: line['debit'] > 0 ? line['debit'].toString() : '',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(fontSize: 12),
                                      decoration: const InputDecoration(
                                        hintText: 'مدين',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      ),
                                      onChanged: (v) => setDialogState(() => line['debit'] = double.tryParse(v) ?? 0.0),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: line['credit'] > 0 ? line['credit'].toString() : '',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(fontSize: 12),
                                      decoration: const InputDecoration(
                                        hintText: 'دائن',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      ),
                                      onChanged: (v) => setDialogState(() => line['credit'] = double.tryParse(v) ?? 0.0),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                        const SizedBox(height: 8),
                        // شريط توازن القيد
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isBalanced ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isBalanced ? Colors.green.shade200 : Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('إجمالي المدين: ${totalDebit.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('إجمالي الدائن: ${totalCredit.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(
                                isBalanced ? '✓ متوازن' : '✗ غير متوازن',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isBalanced ? Colors.green.shade800 : Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: isBalanced
                      ? () async {
                          if (!formKey.currentState!.validate()) return;
                          final payload = {
                            'date': dateCtrl.text.trim(),
                            'description': descCtrl.text.trim(),
                            'site_id': selectedSiteId,
                            'lines': lines,
                          };

                          final ok = await prov.createJournalEntry(payload);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم ترحيل قيد اليومية بنجاح.'), backgroundColor: AppTheme.successColor),
                            );
                          }
                        }
                      : null,
                  child: const Text('ترحيل القيد'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==================== تفاصيل قيد مرحل ====================
  void _openEntryDetails(JournalEntryModel entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('قيد يومية: ${entry.entryNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                        Text('التاريخ: ${entry.date}  •  المشروع: ${entry.siteName ?? "عام"}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                    child: const Text('قيد مرحل رسمياً', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(entry.description, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
              const Divider(height: 24),
              const Text('الأطراف المحاسبية المقيدة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: entry.lines.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final l = entry.lines[idx];
                    return ListTile(
                      dense: true,
                      title: Text(l.accountName ?? 'حساب #${l.accountId}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: l.description != null && l.description!.isNotEmpty ? Text(l.description!, style: const TextStyle(fontSize: 11)) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (l.debit > 0)
                            Text('مدين: ${ArabicHelpers.formatCurrency(l.debit)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                          if (l.credit > 0)
                            Text('دائن: ${ArabicHelpers.formatCurrency(l.credit)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'القيد مرحل في السجل المالي ولا يمكن حذفه أو تعديله. في حال الخطأ يتم إنشاء قيد عكسي للتسوية.',
                        style: TextStyle(fontSize: 11, color: Colors.brown),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('إنشاء قيد عكسي لتصحيح هذا القيد'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showCreateJournalEntryDialog(entry);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ManagementProvider>();
    final fin = prov.financialSummary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('الإدارة المالية ودليل الحسابات'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.cyan,
          indicatorWeight: 3.5,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFCBD5E1),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          tabs: const [
            Tab(icon: Icon(Icons.account_tree_rounded, size: 22), text: 'دليل الحسابات (Accounts)'),
            Tab(icon: Icon(Icons.menu_book_rounded, size: 22), text: 'قيود اليومية (Journal)'),
          ],
        ),
      ),
      body: Column(
        children: [
          // لوحة الملخص المالي الأعلى
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('إجمالي الإيرادات', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text(ArabicHelpers.formatCurrency(fin.totalRevenues), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981))),
                    ],
                  ),
                ),
                Container(height: 24, width: 1, color: Colors.grey.shade300),
                Expanded(
                  child: Column(
                    children: [
                      const Text('إجمالي المصروفات', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text(ArabicHelpers.formatCurrency(fin.totalExpenses), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
                Container(height: 24, width: 1, color: Colors.grey.shade300),
                Expanded(
                  child: Column(
                    children: [
                      const Text('صافي الأرباح', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text(ArabicHelpers.formatCurrency(fin.netProfit), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAccountsTab(),
                _buildJournalTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_financial_screen',
        onPressed: () {
          if (_tabController.index == 0) {
            _showAccountDialog();
          } else {
            _showCreateJournalEntryDialog();
          }
        },
        icon: Icon(
          _tabController.index == 0
              ? Icons.account_balance_wallet_rounded
              : Icons.menu_book_rounded,
        ),
        label: Text(
          _tabController.index == 0 ? 'إضافة حساب جديد' : 'ترحيل قيد يومي',
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildAccountsTab() {
    final prov = context.watch<ManagementProvider>();

    if (prov.financialState == LoadingState.loading && prov.accounts.isEmpty) {
      return const LoadingWidget(message: 'جاري تحميل دليل الحسابات...');
    }

    if (prov.financialState == LoadingState.error && prov.accounts.isEmpty) {
      return ErrorView(message: prov.financialError ?? 'تعذر تحميل الحسابات', onRetry: () => prov.fetchFinancialData());
    }

    if (prov.accounts.isEmpty) {
      return EmptyView(
        title: 'لا توجد حسابات',
        message: 'أضف الحسابات المالية لتسجيل القيود والمصروفات.',
        icon: Icons.account_balance_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () => prov.fetchFinancialData(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: prov.accounts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final acc = prov.accounts[index];

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            color: Colors.white,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.08),
                child: Text(acc.code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ),
              title: Row(
                children: [
                  Expanded(child: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                    child: Text(acc.typeLabel, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ),
                ],
              ),
              subtitle: Text(
                'الرصيد: ${ArabicHelpers.formatCurrency(acc.balance)}${acc.hasJournalEntries ? " • مرتبط بقيود" : ""}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _showAccountDialog(acc),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: acc.hasJournalEntries ? Colors.grey.shade400 : AppTheme.dangerColor),
                    onPressed: () => _confirmDeleteAccount(acc),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJournalTab() {
    final prov = context.watch<ManagementProvider>();

    if (prov.journalEntries.isEmpty) {
      return EmptyView(
        title: 'لا توجد قيود يومية',
        message: 'قيود الصرف واعتماد التقارير ستظهر هنا بالتسلسل التاريخي.',
        icon: Icons.menu_book_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () => prov.fetchFinancialData(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: prov.journalEntries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final entry = prov.journalEntries[index];

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openEntryDetails(entry),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.receipt_rounded, color: Color(0xFF10B981), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.entryNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                              const SizedBox(height: 2),
                              Text('${entry.date}  •  ${entry.siteName ?? "الإدارة العامة"}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        Text(
                          ArabicHelpers.formatCurrency(entry.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(entry.description, style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)), maxLines: 2),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Text('${entry.lines.length} طرف قيد', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        const Spacer(),
                        const Text('تفاصيل القيد', style: TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF0284C7)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
