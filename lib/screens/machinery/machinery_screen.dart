import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/machinery.dart';
import '../../services/admin_api.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class MachineryScreen extends StatefulWidget {
  final AdminApi api;

  const MachineryScreen({super.key, required this.api});

  @override
  State<MachineryScreen> createState() => _MachineryScreenState();
}

class _MachineryScreenState extends State<MachineryScreen> {
  List<Machinery> _machinery = [];
  bool _loading = true;
  String? _error;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ✅ جلب البيانات دائماً من السيرفر
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await widget.api.get('machinery');
      if (!mounted) return;
      setState(() {
        _machinery = (res as List).map((e) => Machinery.fromJson(e)).toList();
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
        _error = 'حدث خطأ أثناء تحميل أسطول الآليات والمعدات';
        _loading = false;
      });
    }
  }

  List<Machinery> get _filteredMachinery {
    if (_filterStatus == 'all') return _machinery;
    return _machinery.where((m) => m.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أسطول الآليات والمعدات الثقيلة'),
        // ⚠️ لا يوجد زر Refresh في الـ AppBar
      ),
      body: _loading
          ? const LoadingState(message: 'جاري تحميل سجل الآليات...')
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primaryTeal,
                  child: Column(
                    children: [
                      _buildFiltersHeader(),
                      Expanded(
                        child: _filteredMachinery.isEmpty
                            ? const EmptyState(
                                title: 'لا توجد آليات',
                                message: 'لم يتم العثور على معدات بالحالة المحددة',
                                icon: Icons.precision_manufacturing_outlined,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _filteredMachinery.length,
                                itemBuilder: (context, index) {
                                  final m = _filteredMachinery[index];
                                  return _buildMachineryCard(m);
                                },
                              ),
                      ),
                    ],
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
            _buildStatusChip('all', 'الكل (${_machinery.length})'),
            _buildStatusChip('available', 'متاحة للعمل'),
            _buildStatusChip('in_use', 'قيد التشغيل بالموقع'),
            _buildStatusChip('maintenance', 'تحت الصيانة'),
            _buildStatusChip('out_of_service', 'خارج الخدمة'),
          ],
        ),
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

  Widget _buildMachineryCard(Machinery m) {
    Color statusBg = AppTheme.border;
    Color statusFg = AppTheme.textSecondary;
    String statusText = m.status;

    switch (m.status) {
      case 'available':
        statusBg = AppTheme.successLight;
        statusFg = AppTheme.success;
        statusText = 'متاحة';
        break;
      case 'in_use':
        statusBg = AppTheme.infoLight;
        statusFg = AppTheme.info;
        statusText = 'قيد العمل';
        break;
      case 'maintenance':
        statusBg = AppTheme.warningLight;
        statusFg = AppTheme.warning;
        statusText = 'صيانة';
        break;
      case 'out_of_service':
        statusBg = AppTheme.dangerLight;
        statusFg = AppTheme.danger;
        statusText = 'خارج الخدمة';
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
                    m.name,
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
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusFg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (m.code.isNotEmpty)
                  Text(
                    'الكود: ${m.code}  ·  ',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textMuted),
                  ),
                if (m.plateNumber != null && m.plateNumber!.isNotEmpty)
                  Text(
                    'رقم اللوحة: ${m.plateNumber}',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
                  ),
              ],
            ),
            if (m.operatorName != null && m.operatorName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'السائق / المشغّل: ${m.operatorName}',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
            if (m.hourlyCost > 0) ...[
              const SizedBox(height: 8),
              Text(
                'كلفة الساعة: ${m.hourlyCost.toStringAsFixed(0)} د.ع',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentCyan,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}