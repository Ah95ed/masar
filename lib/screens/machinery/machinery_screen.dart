import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/machinery.dart';
import '../../services/admin_api.dart';
import '../../widgets/auto_refresh_wrapper.dart';
import '../../widgets/pill.dart';
import '../../widgets/state_view.dart';

class MachineryScreen extends StatefulWidget {
  final AdminApi api;
  final Widget? drawer;

  const MachineryScreen({super.key, required this.api, this.drawer});

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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل قائمة الآليات والمعدات';
        _loading = false;
      });
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final res = await widget.api.get('machinery');
      if (!mounted) return;
      setState(() {
        _machinery = (res as List).map((e) => Machinery.fromJson(e)).toList();
      });
    } catch (_) {}
  }

  List<Machinery> get _filteredMachinery {
    if (_filterStatus == 'all') return _machinery;
    return _machinery.where((m) => m.status.toLowerCase() == _filterStatus.toLowerCase()).toList();
  }

  Future<void> _openForm({Machinery? item}) async {
    final codeCtrl = TextEditingController(text: item?.code ?? '');
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final plateCtrl = TextEditingController(text: item?.plateNumber ?? '');
    final driverCtrl = TextEditingController(text: item?.driverName ?? '');
    final hourlyRateCtrl = TextEditingController(
      text: item?.hourlyRate != null && item!.hourlyRate > 0 ? item.hourlyRate.toStringAsFixed(0) : '',
    );
    String status = item?.status ?? 'available';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text(item == null ? 'إضافة آلية جديدة' : 'تعديل بيانات الآلية', style: const TextStyle(fontFamily: 'Cairo')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'كود الآلية *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم / نوع الآلية *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: plateCtrl,
                  decoration: const InputDecoration(labelText: 'رقم اللوحة'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: driverCtrl,
                  decoration: const InputDecoration(labelText: 'اسم المشغل / السائق'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: hourlyRateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'كلفة الساعة (\$)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'حالة الآلية'),
                  items: const [
                    DropdownMenuItem(value: 'available', child: Text('جاهزة ومتاحة')),
                    DropdownMenuItem(value: 'in_use', child: Text('قيد الاستخدام بالموقع')),
                    DropdownMenuItem(value: 'maintenance', child: Text('تحت الصيانة')),
                    DropdownMenuItem(value: 'out_of_service', child: Text('خارج الخدمة')),
                  ],
                  onChanged: (v) => setDlgState(() => status = v ?? 'available'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: kInk),
              child: const Text('حفظ البيانات', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;

    try {
      await widget.api.post('machinery-save', {
        'id': item?.id ?? 0,
        'code': codeCtrl.text.trim(),
        'name': nameCtrl.text.trim(),
        'plate_number': plateCtrl.text.trim(),
        'driver_name': driverCtrl.text.trim(),
        'hourly_rate': double.tryParse(hourlyRateCtrl.text.trim()) ?? 0.0,
        'status': status,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(item == null ? 'تمت إضافة الآلية بنجاح' : 'تم تحديث الآلية بنجاح', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: kGreen,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حفظ الآلية: $e', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: kRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredMachinery;
    final isWide = MediaQuery.of(context).size.width >= 850;

    return AutoRefreshWrapper(
      interval: const Duration(seconds: 60),
      onRefresh: _silentRefresh,
      child: Scaffold(
        drawer: widget.drawer,
        appBar: AppBar(
          title: const Text('أسطول الآليات والمعدات'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'إضافة آلية',
              onPressed: () => _openForm(),
            ),
          ],
        ),
        body: StateView(
          loading: _loading && _machinery.isEmpty,
          error: _error,
          empty: false,
          onRetry: _load,
          child: RefreshIndicator(
            onRefresh: _load,
            color: kCyan,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeaderBar(),
                const SizedBox(height: 12),

                _buildFilterChips(),
                const SizedBox(height: 16),

                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('لا توجد آليات تطابق التصفية الحالية', style: TextStyle(fontFamily: 'Cairo', color: kMuted)),
                    ),
                  )
                else if (isWide)
                  _buildMachineryTable(list)
                else
                  _buildMachineryCards(list),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBar() {
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
                'الآليات والمعدات الثقيلة',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15, color: kInk),
              ),
              Text(
                'متابعة جاهزية وتوزيع الآليات وتكاليف التشغيل بالساعة',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kMuted),
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: () => _openForm(),
            style: FilledButton.styleFrom(backgroundColor: kInk),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('+ إضافة آلية', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChoiceChip('all', 'الكل (${_machinery.length})'),
          const SizedBox(width: 8),
          _buildChoiceChip('available', 'جاهزة ومتاحة'),
          const SizedBox(width: 8),
          _buildChoiceChip('in_use', 'قيد العمل'),
          const SizedBox(width: 8),
          _buildChoiceChip('maintenance', 'تحت الصيانة'),
          const SizedBox(width: 8),
          _buildChoiceChip('out_of_service', 'خارج الخدمة'),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String status, String label) {
    final isSelected = _filterStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterStatus = status),
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

  Widget _buildMachineryTable(List<Machinery> list) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = 950.0;
        final tableWidth = constraints.maxWidth > minWidth ? constraints.maxWidth : minWidth;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: kLine),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: kPaper,
                    child: const Row(
                      children: [
                        Expanded(flex: 14, child: Text('الكود', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk))),
                        Expanded(flex: 26, child: Text('الآلية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk))),
                        Expanded(flex: 18, child: Text('اللوحة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk))),
                        Expanded(flex: 20, child: Text('المشغل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk))),
                        Expanded(flex: 16, child: Text('الحالة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk))),
                        Expanded(flex: 16, child: Text('كلفة الساعة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk))),
                        Expanded(flex: 14, child: Align(alignment: AlignmentDirectional.centerEnd, child: Text('الإجراءات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk)))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: kLine),
                  ...list.map((item) {
                    final isAvailable = item.status == 'available';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: kLine, width: 0.8)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 14,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Pill.info(text: item.code),
                            ),
                          ),
                          Expanded(
                            flex: 26,
                            child: Text(
                              item.name,
                              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 18,
                            child: Text(
                              item.plateNumber ?? '-',
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kInk),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 20,
                            child: Text(
                              item.driverName ?? 'غير معين',
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kInk),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 16,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Pill(
                                text: item.statusLabel,
                                type: isAvailable ? PillType.success : PillType.neutral,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 16,
                            child: Text(
                              '${item.hourlyRate.toStringAsFixed(0)} \$',
                              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12, color: kInk),
                            ),
                          ),
                          Expanded(
                            flex: 14,
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: kCyan),
                                tooltip: 'تعديل',
                                onPressed: () => _openForm(item: item),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildMachineryCards(List<Machinery> list) {
    return Column(
      children: list.map((m) {
        final isAvailable = m.status == 'available';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
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
                    Pill.info(text: m.code),
                    Pill(
                      text: m.statusLabel,
                      type: isAvailable ? PillType.success : PillType.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  m.name,
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15, color: kInk),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.pin_outlined, size: 13, color: kMuted),
                    const SizedBox(width: 4),
                    Text('لوحة: ${m.plateNumber ?? "بدون"}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: kMuted)),
                    const Spacer(),
                    const Icon(Icons.person_outline, size: 13, color: kMuted),
                    const SizedBox(width: 4),
                    Text('سائق: ${m.driverName ?? "غير معين"}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: kMuted)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'كلفة الساعة: ${m.hourlyRate.toStringAsFixed(0)} \$',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: kGreen),
                ),
                const Divider(height: 18, color: kLine),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _openForm(item: m),
                      icon: const Icon(Icons.edit_outlined, size: 16, color: kCyan),
                      label: const Text('تعديل البيانات', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kCyan)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}