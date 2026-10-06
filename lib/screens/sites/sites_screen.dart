import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/site.dart';
import '../../services/admin_api.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import 'site_form_screen.dart';

class SitesScreen extends StatefulWidget {
  final AdminApi api;

  const SitesScreen({super.key, required this.api});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  List<Site> _sites = [];
  bool _loading = true;
  String? _error;
  String _filterStatus = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ✅ القاعدة الذهبية: جلب البيانات دائماً من السيرفر
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await widget.api.get('sites');
      if (!mounted) return;
      setState(() {
        _sites = (res as List).map((e) => Site.fromJson(e)).toList();
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
        _error = 'حدث خطأ أثناء تحميل المواقع';
        _loading = false;
      });
    }
  }

  Future<void> _openForm({Site? item}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SiteFormScreen(api: widget.api, item: item),
      ),
    );

    // ✅ إذا عاد النموذج بـ true نقوم بإعادة الجلب من السيرفر فوراً
    if (saved == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item == null ? 'تم إنشاء الموقع بنجاح' : 'تم تحديث بيانات الموقع بنجاح',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _cancelSite(Site site) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'إلغاء الموقع',
      message: 'هل أنت متأكد من إلغاء الموقع "${site.name}"؟',
      confirmText: 'إلغاء الموقع',
      isDestructive: true,
    );

    if (!confirmed) return;

    try {
      await widget.api.post('site-cancel', {'site_id': site.id});
      if (!mounted) return;
      // ✅ إعادة الجلب بعد نجاح الإلغاء
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء الموقع بنجاح', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.success,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  List<Site> get _filteredSites {
    return _sites.where((site) {
      final matchesStatus = _filterStatus == 'all' || site.status == _filterStatus;
      final matchesSearch = _searchQuery.isEmpty ||
          site.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          site.clientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          site.code.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المواقع والمشاريع'),
        // ⚠️ لا يوجد زر Refresh في الـ AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
            tooltip: 'إضافة موقع',
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: _loading
          ? const LoadingState(message: 'جاري تحميل قائمة المواقع...')
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primaryTeal,
                  child: Column(
                    children: [
                      _buildFiltersHeader(),
                      Expanded(
                        child: _filteredSites.isEmpty
                            ? const EmptyState(
                                title: 'لا توجد مواقع مطابقة',
                                message: 'قم بإضافة موقع جديد أو تعديل معايير البحث',
                                icon: Icons.business_outlined,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _filteredSites.length,
                                itemBuilder: (context, index) {
                                  final site = _filteredSites[index];
                                  return _buildSiteCard(site);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: AppTheme.primaryDark,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFiltersHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: 'بحث باسم الموقع أو العميل أو الكود...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('all', 'الكل (${_sites.length})'),
                _buildStatusChip('active', 'نشط'),
                _buildStatusChip('planning', 'تخطيط'),
                _buildStatusChip('paused', 'متوقف'),
                _buildStatusChip('completed', 'مكتمل'),
                _buildStatusChip('cancelled', 'ملغي'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label) {
    final isSelected = _filterStatus == status;
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
        onSelected: (_) => setState(() => _filterStatus = status),
      ),
    );
  }

  Widget _buildSiteCard(Site site) {
    Color statusBg = AppTheme.border;
    Color statusFg = AppTheme.textSecondary;
    String statusLabel = site.status;

    switch (site.status) {
      case 'active':
        statusBg = AppTheme.successLight;
        statusFg = AppTheme.success;
        statusLabel = 'نشط';
        break;
      case 'planning':
        statusBg = AppTheme.infoLight;
        statusFg = AppTheme.info;
        statusLabel = 'قيد التخطيط';
        break;
      case 'paused':
        statusBg = AppTheme.warningLight;
        statusFg = AppTheme.warning;
        statusLabel = 'متوقف';
        break;
      case 'completed':
        statusBg = Colors.purple.shade50;
        statusFg = Colors.purple;
        statusLabel = 'مكتمل';
        break;
      case 'cancelled':
        statusBg = AppTheme.dangerLight;
        statusFg = AppTheme.danger;
        statusLabel = 'ملغي';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    site.name,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusFg,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (v) {
                    if (v == 'edit') _openForm(item: site);
                    if (v == 'cancel') _cancelSite(site);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('تعديل', style: TextStyle(fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                    if (site.status != 'cancelled')
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            Icon(Icons.cancel_outlined, size: 18, color: AppTheme.danger),
                            SizedBox(width: 8),
                            Text('إلغاء الموقع', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.danger)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (site.clientName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 15, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'العميل: ${site.clientName}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            if (site.location != null && site.location!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 15, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      site.location!,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (site.budget > 0)
                  Text(
                    'الميزانية: ${site.budget.toStringAsFixed(0)} د.ع',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentCyan,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (site.workDate != null && site.workDate!.isNotEmpty)
                  Text(
                    site.workDate!,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
