import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../models/task.dart';
import '../models/report.dart';

class ExcelService {
  ExcelService._();
  static final ExcelService instance = ExcelService._();

  // ==================== خطط العمل (TASKS) ====================

  /// تصدير قائمة خطط العمل إلى ملف Excel (.xlsx)
  Future<String?> exportTasksToExcel(List<Task> tasks) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'خطط العمل');
    final sheet = excel['خطط العمل'];

    // ترويسة الأعمدة
    sheet.appendRow([
      TextCellValue('المعرف'),
      TextCellValue('عنوان الخطة'),
      TextCellValue('الموقع'),
      TextCellValue('المهندس المكلف'),
      TextCellValue('الأولوية'),
      TextCellValue('الحالة'),
      TextCellValue('نسبة الإنجاز %'),
      TextCellValue('تعميم'),
      TextCellValue('الوصف والتفاصيل'),
      TextCellValue('تاريخ الإنشاء'),
    ]);

    // إضافة البيانات
    for (final t in tasks) {
      sheet.appendRow([
        IntCellValue(t.id),
        TextCellValue(t.title),
        TextCellValue(t.siteName ?? 'الموقع #${t.siteId}'),
        TextCellValue(t.assignedToName ?? 'غير معين'),
        TextCellValue(t.priorityLabel),
        TextCellValue(t.statusLabel),
        IntCellValue(t.progress),
        TextCellValue(t.isBroadcast ? 'نعم (تعميم)' : 'لا'),
        TextCellValue(t.description ?? ''),
        TextCellValue(t.createdAt ?? ''),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) return null;

    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return await _saveAndOpenFile(bytes, 'work_plans_$dateStr.xlsx');
  }

  /// تنزيل نموذج فارغ لخطط العمل لتسهيل تعبئته واستيراده
  Future<String?> downloadTasksTemplate() async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'نموذج خطط العمل');
    final sheet = excel['نموذج خطط العمل'];

    sheet.appendRow([
      TextCellValue('عنوان الخطة *'),
      TextCellValue('رقم الموقع *'),
      TextCellValue('الوصف'),
      TextCellValue('الأولوية (urgent/high/medium/low)'),
      TextCellValue('رقم المهندس'),
      TextCellValue('تعميم (نعم/لا)'),
    ]);

    // صف توضيحي كمثال
    sheet.appendRow([
      TextCellValue('صب خرسانة الدور الأول'),
      IntCellValue(1),
      TextCellValue('استكمال أعمال الصب والتشطيب'),
      TextCellValue('high'),
      IntCellValue(0),
      TextCellValue('لا'),
    ]);

    final bytes = excel.encode();
    if (bytes == null) return null;

    return await _saveAndOpenFile(bytes, 'work_plans_template.xlsx');
  }

  /// استيراد وقراءة ملف Excel لخطط العمل
  Future<List<Map<String, dynamic>>?> importTasksFromExcel() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (files.isEmpty) return null;

    final file = files.first;
    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) return null;

    final excel = Excel.decodeBytes(bytes);
    final List<Map<String, dynamic>> parsedTasks = [];

    for (final table in excel.tables.keys) {
      final rows = excel.tables[table]!.rows;
      if (rows.length <= 1) continue; // تخطي إذا كان الجدول فارغاً أو يحتوي فقط على الترويسة

      // قراءة الصفوف بدءاً من الصف الثاني (تخطي العناوين)
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        String getCellStr(int idx) {
          if (idx >= row.length || row[idx] == null) return '';
          return row[idx]!.value?.toString().trim() ?? '';
        }

        final title = getCellStr(0);
        if (title.isEmpty) continue; // حقل العنوان إلزامي

        final siteIdStr = getCellStr(1);
        final siteId = int.tryParse(siteIdStr) ?? 1;

        final desc = getCellStr(2);
        String priority = getCellStr(3).toLowerCase();
        if (priority.isEmpty || !['urgent', 'high', 'medium', 'low'].contains(priority)) {
          if (priority.contains('عاجل')) {
            priority = 'urgent';
          } else if (priority.contains('عالي')) {
            priority = 'high';
          } else if (priority.contains('منخفض')) {
            priority = 'low';
          } else {
            priority = 'medium';
          }
        }

        final assignedToStr = getCellStr(4);
        final assignedTo = int.tryParse(assignedToStr);

        final broadcastStr = getCellStr(5).toLowerCase();
        final isBroadcast = broadcastStr.contains('نعم') || broadcastStr.contains('true') || broadcastStr == '1';

        parsedTasks.add({
          'title': title,
          'site_id': siteId,
          'description': desc,
          'priority': priority,
          'assigned_to': assignedTo,
          'is_broadcast': isBroadcast,
        });
      }
      break; // الاكتفاء بالورقة الأولى
    }

    return parsedTasks;
  }

  // ==================== التقارير اليومية (REPORTS) ====================

  /// تصدير التقارير اليومية إلى ملف Excel (.xlsx)
  Future<String?> exportReportsToExcel(List<Report> reports) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'التقارير اليومية');
    final sheet = excel['التقارير اليومية'];

    sheet.appendRow([
      TextCellValue('المعرف'),
      TextCellValue('تاريخ التقرير'),
      TextCellValue('الموقع'),
      TextCellValue('المهندس'),
      TextCellValue('نسبة الإنجاز %'),
      TextCellValue('عدد العمال'),
      TextCellValue('عدد الآليات'),
      TextCellValue('الحالة'),
      TextCellValue('الأعمال المنجزة'),
      TextCellValue('المشاكل والمعوقات'),
      TextCellValue('المواد المستخدمة'),
      TextCellValue('ملاحظات السلامة'),
      TextCellValue('إجمالي المصروفات'),
    ]);

    for (final r in reports) {
      double totalExpenses = 0.0;
      for (final exp in r.expenses) {
        totalExpenses += exp.total;
      }

      sheet.appendRow([
        IntCellValue(r.id),
        TextCellValue(r.reportDate),
        TextCellValue(r.siteName ?? 'الموقع #${r.siteId}'),
        TextCellValue(r.engineerName ?? 'المهندس #${r.engineerId}'),
        IntCellValue(r.workProgress),
        IntCellValue(r.manpowerCount),
        IntCellValue(r.machineryCount),
        TextCellValue(r.statusLabel),
        TextCellValue(r.workDone),
        TextCellValue(r.issues ?? ''),
        TextCellValue(r.materialsUsed ?? ''),
        TextCellValue(r.safetyNotes ?? ''),
        DoubleCellValue(totalExpenses),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) return null;

    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return await _saveAndOpenFile(bytes, 'daily_reports_$dateStr.xlsx');
  }

  /// تصدير تقرير مفصل واحد مع المصروفات والإيصالات
  Future<String?> exportSingleReportToExcel(Report report) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'تفاصيل التقرير');
    final sheet1 = excel['تفاصيل التقرير'];

    // بيانات التقرير الأساسية
    sheet1.appendRow([TextCellValue('الحقل'), TextCellValue('القيمة')]);
    sheet1.appendRow([TextCellValue('رقم التقرير'), IntCellValue(report.id)]);
    sheet1.appendRow([TextCellValue('تاريخ التقرير'), TextCellValue(report.reportDate)]);
    sheet1.appendRow([TextCellValue('الموقع'), TextCellValue(report.siteName ?? 'الموقع #${report.siteId}')]);
    sheet1.appendRow([TextCellValue('المهندس المعد للتقرير'), TextCellValue(report.engineerName ?? 'المهندس #${report.engineerId}')]);
    sheet1.appendRow([TextCellValue('نسبة الإنجاز'), TextCellValue('${report.workProgress}%')]);
    sheet1.appendRow([TextCellValue('حالة التقرير'), TextCellValue(report.statusLabel)]);
    sheet1.appendRow([TextCellValue('عدد العمال'), IntCellValue(report.manpowerCount)]);
    sheet1.appendRow([TextCellValue('عدد الآليات'), IntCellValue(report.machineryCount)]);
    sheet1.appendRow([TextCellValue('حالة الطقس'), TextCellValue('${report.weather ?? "-"} (${report.temperature ?? "-"}°C)')]);
    sheet1.appendRow([TextCellValue('الأعمال المنجزة'), TextCellValue(report.workDone)]);
    sheet1.appendRow([TextCellValue('المشاكل والمعوقات'), TextCellValue(report.issues ?? '-')]);
    sheet1.appendRow([TextCellValue('المواد المستخدمة'), TextCellValue(report.materialsUsed ?? '-')]);
    sheet1.appendRow([TextCellValue('ملاحظات السلامة'), TextCellValue(report.safetyNotes ?? '-')]);
    sheet1.appendRow([TextCellValue('ملاحظات الإدارة'), TextCellValue(report.adminNotes ?? '-')]);

    // ورقة عمل ثانية للمصروفات
    final sheet2 = excel['المصروفات النثرية'];
    sheet2.appendRow([
      TextCellValue('البند / المادة'),
      TextCellValue('التصنيف'),
      TextCellValue('الكمية'),
      TextCellValue('سعر الوحدة'),
      TextCellValue('الإجمالي'),
      TextCellValue('ملاحظات'),
    ]);

    double grandTotal = 0;
    for (final exp in report.expenses) {
      grandTotal += exp.total;
      sheet2.appendRow([
        TextCellValue(exp.itemName),
        TextCellValue(exp.category),
        DoubleCellValue(exp.quantity),
        DoubleCellValue(exp.unitPrice),
        DoubleCellValue(exp.total),
        TextCellValue(exp.notes ?? ''),
      ]);
    }

    sheet2.appendRow([
      TextCellValue('المجموع الكلي'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(grandTotal),
      TextCellValue(''),
    ]);

    final bytes = excel.encode();
    if (bytes == null) return null;

    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    return await _saveAndOpenFile(bytes, 'report_${report.id}_$dateStr.xlsx');
  }

  /// استيراد تقارير من ملف Excel
  Future<List<Map<String, dynamic>>?> importReportsFromExcel() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (files.isEmpty) return null;

    final file = files.first;
    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) return null;

    final excel = Excel.decodeBytes(bytes);
    final List<Map<String, dynamic>> parsedReports = [];

    for (final table in excel.tables.keys) {
      final rows = excel.tables[table]!.rows;
      if (rows.length <= 1) continue;

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        String getCellStr(int idx) {
          if (idx >= row.length || row[idx] == null) return '';
          return row[idx]!.value?.toString().trim() ?? '';
        }

        final date = getCellStr(0);
        final siteIdStr = getCellStr(1);
        final progressStr = getCellStr(2);
        final workersStr = getCellStr(3);
        final machineryStr = getCellStr(4);
        final workDone = getCellStr(5);
        final issues = getCellStr(6);
        final materials = getCellStr(7);

        if (workDone.isEmpty) continue;

        parsedReports.add({
          'report_date': date.isNotEmpty ? date : DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'site_id': int.tryParse(siteIdStr) ?? 1,
          'work_progress': int.tryParse(progressStr) ?? 0,
          'workers_count': int.tryParse(workersStr) ?? 0,
          'machinery_count': int.tryParse(machineryStr) ?? 0,
          'work_done': workDone,
          'issues': issues,
          'materials_used': materials,
        });
      }
      break;
    }

    return parsedReports;
  }

  // ==================== الحفظ وفتح الملفات ====================

  Future<String?> _saveAndOpenFile(List<int> bytes, String defaultFileName) async {
    try {
      String? outputPath;

      if (!kIsWeb && Platform.isWindows) {
        // على الويندوز: حفظ في مسار التنزيلات أو المستندات
        final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        outputPath = '${dir.path}${Platform.pathSeparator}$defaultFileName';
        final file = File(outputPath);
        await file.writeAsBytes(bytes, flush: true);
      } else {
        // على أندرويد والأجهزة الأخرى
        final dir = await getApplicationDocumentsDirectory();
        outputPath = '${dir.path}/$defaultFileName';
        final file = File(outputPath);
        await file.writeAsBytes(bytes, flush: true);
      }

      // محاولة فتح الملف مباشرة عبر البرنامج الافتراضي (Excel / Office)
      try {
        await OpenFilex.open(outputPath);
      } catch (_) {}

      return outputPath;
    } catch (e) {
      debugPrint('Error saving excel file: $e');
      return null;
    }
  }
}