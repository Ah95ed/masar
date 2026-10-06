import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/site.dart';
import '../../models/user.dart';
import '../../services/admin_api.dart';

class SiteFormScreen extends StatefulWidget {
  final AdminApi api;
  final Site? item;

  const SiteFormScreen({super.key, required this.api, this.item});

  @override
  State<SiteFormScreen> createState() => _SiteFormScreenState();
}

class _SiteFormScreenState extends State<SiteFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _clientCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _budgetCtrl;
  late final TextEditingController _descCtrl;

  late String _workDate;
  late String _startTime;
  late String _endTime;
  late String _status;
  int? _managerId;

  List<User> _engineers = [];
  bool _saving = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _nameCtrl = TextEditingController(text: it?.name ?? '');
    _clientCtrl = TextEditingController(text: it?.clientName ?? '');
    _locationCtrl = TextEditingController(text: it?.location ?? '');
    _budgetCtrl = TextEditingController(
      text: it?.budget != null && it!.budget > 0 ? it.budget.toStringAsFixed(0) : '',
    );
    _descCtrl = TextEditingController(text: it?.description ?? '');

    _workDate = it?.workDate ?? DateTime.now().toIso8601String().split('T').first;
    _startTime = it?.startTime ?? '08:00';
    _endTime = it?.endTime ?? '17:00';
    _status = it?.status ?? 'active';
    _managerId = it?.managerId;

    _loadEngineers();
  }

  Future<void> _loadEngineers() async {
    try {
      final res = await widget.api.get('users');
      if (!mounted) return;
      final list = (res as List).map((e) => User.fromJson(e)).toList();
      setState(() {
        _engineers = list.where((u) => u.role == 'engineer').toList();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _clientCtrl.dispose();
    _locationCtrl.dispose();
    _budgetCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    DateTime initial = DateTime.tryParse(_workDate) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _workDate = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await widget.api.post('site-save', {
        'id': widget.item?.id ?? 0,
        'name': _nameCtrl.text.trim(),
        'client_name': _clientCtrl.text.trim(),
        'work_date': _workDate,
        'start_time': _startTime,
        'end_time': _endTime,
        'location': _locationCtrl.text.trim(),
        'budget': double.tryParse(_budgetCtrl.text) ?? 0,
        'status': _status,
        'manager_id': _managerId ?? 0,
        'description': _descCtrl.text.trim(),
      });

      if (!mounted) return;
      // ✅ القاعدة الذهبية: إغلاق النموذج وإرجاع true لجلب البيانات من السيرفر
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ غير متوقع أثناء الحفظ', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل الموقع' : 'إضافة موقع جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم المشروع / الموقع *',
                prefixIcon: Icon(Icons.business_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم الموقع مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clientCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم العميل / الجهة المالكة',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'الموقع الجغرافي / العنوان',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الميزانية التقديرية (د.ع)',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ بدء العمل',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(_workDate, style: const TextStyle(fontFamily: 'Cairo')),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'حالة الموقع *',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'planning', child: Text('قيد التخطيط')),
                DropdownMenuItem(value: 'active', child: Text('نشط (قيد التنفيذ)')),
                DropdownMenuItem(value: 'paused', child: Text('متوقف مؤقتاً')),
                DropdownMenuItem(value: 'completed', child: Text('مكتمل')),
                DropdownMenuItem(value: 'cancelled', child: Text('ملغي')),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'active'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _managerId,
              decoration: const InputDecoration(
                labelText: 'المهندس المشرف',
                prefixIcon: Icon(Icons.engineering_outlined),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('بدون مهندس محدد'),
                ),
                ..._engineers.map(
                  (u) => DropdownMenuItem<int>(
                    value: u.id,
                    child: Text(u.fullName.isNotEmpty ? u.fullName : u.username),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _managerId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'وصف المشروع وملاحظات',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isEdit ? 'حفظ التعديلات' : 'إنشاء الموقع',
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}