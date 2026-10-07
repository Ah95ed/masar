import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/site.dart';
import '../../providers/sites_provider.dart';
import '../../services/admin_api.dart';
import '../../widgets/auto_refresh_wrapper.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/pill.dart';
import '../../widgets/state_view.dart';
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
            item == null
                ? 'تم إنشاء الموقع بنجاح'
                : 'تم تحديث بيانات الموقع بنجاح',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: kGreen,
        ),
      );
    }
  }

  Future<void> _cancelSite(Site site) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'إلغاء الموقع',
      message: 'هل أنت متأكد من رغبتك في إلغاء وتجميد موقع "${site.name}"؟',
      confirmText: 'إلغاء الموقع',
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    final success = await context.read<SitesProvider>().cancelSite(site.id);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إلغاء الموقع بنجاح',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: kGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sitesProv = context.watch<SitesProvider>();
    final sites = sitesProv.filteredSites;
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 850;

    return AutoRefreshWrapper(
      interval: const Duration(seconds: 30),
      onRefresh: () => sitesProv.fetchSites(),
      child: Scaffold(
        drawer: widget.drawer,
        appBar: AppBar(
          title: const Text('المواقع والمشاريع'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_business_rounded),
              tooltip: 'موقع جديد',
              onPressed: () => _openForm(),
            ),
          ],
        ),
        body: StateView(
          loading: sitesProv.isLoading && sitesProv.sites.isEmpty,
          error: sitesProv.error,
          empty: false,
          onRetry: () => sitesProv.fetchSites(),
          child: RefreshIndicator(
            onRefresh: () => sitesProv.fetchSites(),
            color: kCyan,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // رأس: المواقع والمشاريع + وصف + زر + موقع جديد
                _buildHeaderBar(sitesProv),
                const SizedBox(height: 12),

                // 4 مربعات فلترة (ChoiceChips)
                _buildFilterChips(sitesProv),
                const SizedBox(height: 16),

                if (sites.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'لا توجد مواقع تطابق معايير البحث',
                        style: TextStyle(fontFamily: 'Cairo', color: kMuted),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isTablet ? 3 : (width >= 600 ? 2 : 1),
                      mainAxisExtent: 220,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: sites.length,
                    itemBuilder: (context, index) =>
                        _buildSiteCard(sites[index]),
                  ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'sites_fab',
          onPressed: () => _openForm(),
          backgroundColor: kInk,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeaderBar(SitesProvider prov) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kLine),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المواقع والمشاريع الإنشائية',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: kInk,
                ),
              ),
              Text(
                'متابعة حالة مواقع العمل والميزانيات والمهندسين المشرفين',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: kMuted,
                ),
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: () => _openForm(),
            style: FilledButton.styleFrom(backgroundColor: kInk),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              '+ موقع جديد',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(SitesProvider prov) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChoiceChip('all', 'الكل (${prov.sites.length})', prov),
          const SizedBox(width: 8),
          _buildChoiceChip('active', 'نشط', prov),
          const SizedBox(width: 8),
          _buildChoiceChip('completed', 'مكتمل', prov),
          const SizedBox(width: 8),
          _buildChoiceChip('cancelled', 'ملغى', prov),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String status, String label, SitesProvider prov) {
    final isSelected = prov.filterStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => prov.setFilter(status),
      selectedColor: kInk,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : kInk,
      ),
      side: BorderSide(color: isSelected ? kInk : kLine),
    );
  }

  Widget _buildSiteCard(Site site) {
    final isActive = site.status == 'active';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: kLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Pill.info(
                  text: site.code.isNotEmpty ? site.code : 'SP-${site.id}',
                ),
                Pill(
                  text: site.statusLabel,
                  type: isActive ? PillType.success : PillType.neutral,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              site.name,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: kInk,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              'العميل: ${site.clientName.isNotEmpty ? site.clientName : "غير محدد"}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: kMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'المهندس: ${site.managerName != null && site.managerName!.isNotEmpty ? site.managerName! : "غير معين"}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: kMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (site.location != null && site.location!.isNotEmpty)
              Text(
                site.location!,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: kCyan,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const Spacer(),
            const Divider(height: 1, color: kLine),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _openForm(item: site),
                  icon: const Icon(Icons.edit_outlined, size: 16, color: kCyan),
                  label: const Text(
                    'تعديل',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: kCyan,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _cancelSite(site),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: kRed,
                  ),
                  label: const Text(
                    'حذف',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: kRed,
                    ),
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
