import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/site.dart';
import '../../providers/sites_provider.dart';
import '../../services/admin_api.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import 'site_form_screen.dart';

class SitesScreen extends StatefulWidget {
  final AdminApi api;
  final Widget? drawer;

  const SitesScreen({super.key, required this.api, this.drawer});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SitesProvider>().fetchSites();
    });
  }

  Future<void> _openForm({Site? item}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SiteFormScreen(api: widget.api, item: item),
      ),
    );

    if (saved == true && mounted) {
      await context.read<SitesProvider>().fetchSites();
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
      message: 'هل أنت متأكد من رغبتك في إلغاء موقع "${site.name}"؟',
      confirmText: 'إلغاء الموقع',
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    final success = await context.read<SitesProvider>().cancelSite(site.id);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء الموقع بنجاح', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sitesProv = context.watch<SitesProvider>();
    final sites = sitesProv.filteredSites;

    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('المواقع والمشاريع'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
            tooltip: 'إضافة موقع',
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: sitesProv.isLoading && sitesProv.sites.isEmpty
          ? const LoadingState(message: 'جاري تحميل المواقع...')
          : sitesProv.error != null && sitesProv.sites.isEmpty
              ? ErrorState(message: sitesProv.error!, onRetry: () => sitesProv.fetchSites())
              : RefreshIndicator(
                  onRefresh: () => sitesProv.fetchSites(),
                  color: AppTheme.primaryTeal,
                  child: Column(
                    children: [
                      _buildFiltersHeader(sitesProv),
                      Expanded(
                        child: sites.isEmpty
                            ? const EmptyState(
                                title: 'لا توجد مواقع',
                                message: 'لم يتم العثور على أي مواقع تطابق معايير البحث',
                                icon: Icons.business_outlined,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: sites.length,
                                itemBuilder: (context, index) {
                                  final site = sites[index];
                                  return _buildSiteTile(site);
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

  Widget _buildFiltersHeader(SitesProvider prov) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            onChanged: (v) => prov.setSearch(v),
            decoration: const InputDecoration(
              hintText: 'بحث باسم الموقع، الرمز، العميل...',
              prefixIcon: Icon(Icons.search, size: 20),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('all', 'الكل (${prov.sites.length})', prov),
                _buildStatusChip('active', 'نشط', prov),
                _buildStatusChip('planning', 'تخطيط', prov),
                _buildStatusChip('paused', 'متوقف', prov),
                _buildStatusChip('completed', 'مكتمل', prov),
                _buildStatusChip('cancelled', 'ملغي', prov),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label, SitesProvider prov) {
    final isSelected = prov.filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => prov.setFilter(status),
        selectedColor: AppTheme.primaryDark,
        backgroundColor: Colors.grey.shade100,
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }

  Widget _buildSiteTile(Site site) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(site.status).withOpacity(0.12),
          child: Icon(
            Icons.location_city_rounded,
            color: _getStatusColor(site.status),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                site.name,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(site.status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                site.statusLabel,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(site.status),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              'الرمز: ${site.code} • العميل: ${site.clientName}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
            if (site.budget > 0) ...[
              const SizedBox(height: 2),
              Text(
                'الميزانية: ${site.budget.toStringAsFixed(0)} \$',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        trailing: site.isCancelled
            ? null
            : PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: AppTheme.textMuted),
                onSelected: (val) {
                  if (val == 'edit') _openForm(item: site);
                  if (val == 'cancel') _cancelSite(site);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('تعديل الموقع', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel_outlined, size: 18, color: AppTheme.danger),
                        SizedBox(width: 8),
                        Text('إلغاء الموقع', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppTheme.danger)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.primaryTeal;
      case 'planning':
        return const Color(0xFF6366F1);
      case 'paused':
        return AppTheme.warning;
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.danger;
      default:
        return AppTheme.textSecondary;
    }
  }
}
