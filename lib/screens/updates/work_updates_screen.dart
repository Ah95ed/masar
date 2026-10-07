import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/task.dart';
import '../../services/admin_api.dart';
import '../../widgets/auto_refresh_wrapper.dart';
import '../../widgets/pill.dart';
import '../../widgets/state_view.dart';

class WorkUpdatesScreen extends StatefulWidget {
  final AdminApi api;
  final int? planId;
  final Widget? drawer;

  const WorkUpdatesScreen({
    super.key,
    required this.api,
    this.planId,
    this.drawer,
  });

  @override
  State<WorkUpdatesScreen> createState() => _WorkUpdatesScreenState();
}

class _WorkUpdatesScreenState extends State<WorkUpdatesScreen> {
  List<Map<String, dynamic>> _updates = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUpdates();
  }

  Future<void> _fetchUpdates() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final q = widget.planId != null ? {'plan_id': widget.planId.toString()} : <String, String>{};
      dynamic res;
      try {
        res = await widget.api.get('work-updates', q);
      } catch (_) {
        // Fallback: جلب المهام وتحويلها إلى سجل تحديثات
        final tasksRes = await widget.api.get('tasks');
        if (tasksRes is List) {
          res = tasksRes.map((t) {
            final task = Task.fromJson(Map<String, dynamic>.from(t));
            return {
              'id': task.id,
              'work_plan_id': task.id,
              'engineer_id': task.assignedTo,
              'full_name': task.assignedToName ?? 'مهندس الموقع',
              'title': task.title,
              'site_name': task.siteName ?? 'الموقع #${task.siteId}',
              'old_progress': 0,
              'new_progress': task.progress,
              'old_status': 'pending',
              'new_status': task.status,
              'note': task.description ?? 'تحديث ميداني لمجريات خطة العمل',
              'created_at': task.createdAt ?? 'اليوم',
            };
          }).toList();
        }
      }

      if (!mounted) return;
      final list = (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() {
        _updates = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل سجل تحديثات العمل';
        _loading = false;
      });
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final q = widget.planId != null ? {'plan_id': widget.planId.toString()} : <String, String>{};
      final res = await widget.api.get('work-updates', q);
      if (!mounted) return;
      if (res is List) {
        setState(() {
          _updates = res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return AutoRefreshWrapper(
      interval: const Duration(seconds: 30),
      onRefresh: _silentRefresh,
      child: Scaffold(
        drawer: widget.drawer,
        appBar: AppBar(
          title: Row(
            children: [
              const Text('تحديثات المهندسين'),
              const SizedBox(width: 8),
              if (_updates.isNotEmpty)
                Pill.info(text: '${_updates.length} تحديث'),
            ],
          ),
        ),
        body: StateView(
          loading: _loading,
          error: _error,
          empty: _updates.isEmpty,
          emptyMessage: 'لا توجد تحديثات عمل مسجلة حتى الآن',
          onRetry: _fetchUpdates,
          child: RefreshIndicator(
            onRefresh: _fetchUpdates,
            color: kCyan,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kLine),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: kCyanPale,
                        child: const Icon(Icons.history_rounded, color: kCyan),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.planId != null ? 'سجل تحديثات الخطة #${widget.planId}' : 'سجل التحديثات الميدانية للمهندسين',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: kInk,
                              ),
                            ),
                            const Text(
                              'متابعة فورية لتطور نسب الإنجاز وحالات المهام بالمواقع',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (isWide)
                  _buildTable()
                else
                  _buildCardsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: kLine),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(kPaper),
          columns: const [
            DataColumn(label: Text('المهندس', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            DataColumn(label: Text('المهمة والموقع', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            DataColumn(label: Text('التقدم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الحالة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الملاحظة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            DataColumn(label: Text('التاريخ', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
          ],
          rows: _updates.map((u) {
            final engineer = u['full_name']?.toString() ?? 'مهندس';
            final taskTitle = u['title']?.toString() ?? 'مهمة';
            final siteName = u['site_name']?.toString() ?? 'موقع';
            final oldProg = u['old_progress'] ?? 0;
            final newProg = u['new_progress'] ?? 0;
            final oldStatus = u['old_status']?.toString() ?? '';
            final newStatus = u['new_status']?.toString() ?? '';
            final note = u['note']?.toString() ?? '-';
            final date = u['created_at']?.toString() ?? '';

            return DataRow(
              cells: [
                DataCell(Text(engineer, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
                DataCell(Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(taskTitle, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(siteName, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: kMuted)),
                  ],
                )),
                DataCell(Pill.success(text: '$oldProg% ← $newProg%')),
                DataCell(Pill.info(text: '$oldStatus ← $newStatus')),
                DataCell(SizedBox(
                  width: 200,
                  child: Text(note, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                )),
                DataCell(Text(date, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: kMuted))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCardsList() {
    return Column(
      children: _updates.map((u) {
        final engineer = u['full_name']?.toString() ?? 'مهندس';
        final taskTitle = u['title']?.toString() ?? 'مهمة';
        final siteName = u['site_name']?.toString() ?? 'موقع';
        final oldProg = u['old_progress'] ?? 0;
        final newProg = u['new_progress'] ?? 0;
        final note = u['note']?.toString() ?? '';
        final date = u['created_at']?.toString() ?? '';

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
                    Text(
                      engineer,
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14, color: kInk),
                    ),
                    Pill.success(text: '$oldProg% ← $newProg%'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$taskTitle · $siteName',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kCyan, fontWeight: FontWeight.w600),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    note,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  date,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: kMuted),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}