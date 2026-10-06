import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/site.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../services/admin_api.dart';

class TaskFormScreen extends StatefulWidget {
  final AdminApi api;
  final Task? item;

  const TaskFormScreen({super.key, required this.api, this.item});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  int? _siteId;
  int? _assignedTo;
  bool _isBroadcast = false;
  String _priority = 'medium';

  List<Site> _sites = [];
  List<User> _engineers = [];
  bool _loadingDependencies = true;
  bool _saving = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _titleCtrl = TextEditingController(text: it?.title ?? '');
    _descCtrl = TextEditingController(text: it?.description ?? '');

    _siteId = it?.siteId;
    _assignedTo = it?.assignedTo;
    _isBroadcast = it?.isBroadcast ?? false;
    _priority = it?.priority ?? 'medium';

    _loadDependencies();
  }

  Future<void> _loadDependencies() async {
    try {
      final sitesRes = await widget.api.get('sites');
      final usersRes = await widget.api.get('users');

      if (!mounted) return;

      final sList = (sitesRes as List).map((e) => Site.fromJson(e)).toList();
      final uList = (usersRes as List).map((e) => User.fromJson(e)).toList();

      setState(() {
        _sites = sList;
        _engineers = uList.where((u) => u.role == 'engineer').toList();
        _loadingDependencies = false;

        if (_siteId == null && _sites.isNotEmpty) {
          _siteId = _sites.first.id;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDependencies = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_siteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الموقع التابع للمهمة', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await widget.api.post('work-plan-save', {
        'id': widget.item?.id ?? 0,
        'site_id': _siteId,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'assigned_to': _assignedTo ?? 0,
        'is_broadcast': _isBroadcast,
        'priority': _priority,
      });

      if (!mounted) return;
      // ✅ القاعدة الذهبية: الخروج وإرجاع true
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
          content: Text('حدث خطأ غير متوقع أثناء حفظ الخطة', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل خطة العمل' : 'إضافة خطة عمل جديدة'),
      ),
      body: _loadingDependencies
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<int>(
                    value: _siteId,
                    decoration: const InputDecoration(
                      labelText: 'الموقع / المشروع *',
                      prefixIcon: Icon(Icons.business_rounded),
                    ),
                    items: _sites.map(
                      (s) => DropdownMenuItem<int>(
                        value: s.id,
                        child: Text(s.name, overflow: TextOverflow.ellipsis),
                      ),
                    ).toList(),
                    onChanged: (v) => setState(() => _siteId = v),
                    validator: (v) => v == null ? 'يرجى اختيار الموقع' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'عنوان المهمة / الإجراء *',
                      prefixIcon: Icon(Icons.assignment_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'عنوان المهمة مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: const InputDecoration(
                      labelText: 'درجة الأولوية *',
                      prefixIcon: Icon(Icons.priority_high_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('منخفضة')),
                      DropdownMenuItem(value: 'medium', child: Text('متوسطة')),
                      DropdownMenuItem(value: 'high', child: Text('عالية')),
                      DropdownMenuItem(value: 'urgent', child: Text('حرجة / عاجلة')),
                    ],
                    onChanged: (v) => setState(() => _priority = v ?? 'medium'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text(
                      'تعميم لجميع مهندسي الموقع (Broadcast)',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    ),
                    subtitle: const Text(
                      'تظهر المهمة لجميع مهندسي هذا المشروع دون تخصيص',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    value: _isBroadcast,
                    onChanged: (val) {
                      setState(() {
                        _isBroadcast = val;
                        if (val) _assignedTo = null;
                      });
                    },
                  ),
                  if (!_isBroadcast) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _assignedTo,
                      decoration: const InputDecoration(
                        labelText: 'إسناد لمهندس محدد',
                        prefixIcon: Icon(Icons.engineering_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('بدون تحديد'),
                        ),
                        ..._engineers.map(
                          (u) => DropdownMenuItem<int>(
                            value: u.id,
                            child: Text(u.fullName.isNotEmpty ? u.fullName : u.username),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _assignedTo = v),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'تفاصيل الخطة وتوجيهات التنفيذ',
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
                      _isEdit ? 'حفظ التعديلات' : 'إصدار خطة العمل',
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