<?php
declare(strict_types=1);
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../database.php';
require_once __DIR__ . '/../security.php';
require_once __DIR__ . '/../auth.php';
require_once __DIR__ . '/../helpers.php';
Auth::requireRole('admin');

$type = Security::clean($_GET['type'] ?? '', 20);
if (!in_array($type, ['reports', 'accounting'], true)) {
    http_response_code(400);
    exit('نوع التصدير غير صالح');
}
$from = Security::clean($_GET['from'] ?? '', 10);
$to = Security::clean($_GET['to'] ?? '', 10);
$isDate = static function (string $value): bool {
    $date = DateTime::createFromFormat('Y-m-d', $value);
    return $date !== false && $date->format('Y-m-d') === $value;
};
if (($from !== '' && !$isDate($from)) || ($to !== '' && !$isDate($to)) || ($from !== '' && $to !== '' && $from > $to)) {
    http_response_code(422);
    exit('نطاق التاريخ غير صالح');
}
$range = static function (string $column, array &$params) use ($from, $to): string {
    $where = [];
    if ($from !== '') { $where[] = $column . ' >= ?'; $params[] = $from; }
    if ($to !== '') { $where[] = $column . ' < DATE_ADD(?, INTERVAL 1 DAY)'; $params[] = $to; }
    return $where === [] ? '' : ' WHERE ' . implode(' AND ', $where);
};
$queryRows = static function (string $sql, array $params = []): array {
    $statement = db()->prepare($sql);
    $statement->execute($params);
    return $statement->fetchAll();
};
$statusLabels = ['draft'=>'مسودة','submitted'=>'مرسلة','approved'=>'معتمدة','rejected'=>'مرفوضة','posted'=>'مرحّل','cancelled'=>'ملغى','in'=>'وارد','out'=>'صادر','adjust'=>'تسوية','pending'=>'بالانتظار','in_progress'=>'قيد التنفيذ','waiting_parts'=>'بانتظار قطع','completed'=>'مكتمل'];
$typeLabels = ['asset'=>'أصل','liability'=>'التزام','equity'=>'حقوق ملكية','revenue'=>'إيراد','expense'=>'مصروف'];
$sheets = [];

if ($type === 'reports') {
    $params = [];
    $where = $range('r.report_date', $params);
    $reports = $queryRows('SELECT r.*,s.name AS site_name,s.code AS site_code,u.full_name,reviewer.full_name AS reviewer_name FROM site_daily_reports r JOIN sites s ON s.id=r.site_id JOIN users u ON u.id=r.engineer_id LEFT JOIN users reviewer ON reviewer.id=r.approved_by' . $where . ' ORDER BY r.report_date DESC,r.id DESC', $params);
    $sheets[] = ['التقارير اليومية', ['رقم التقرير','التاريخ','رمز الموقع','الموقع','المهندس','الطقس','درجة الحرارة','عدد العمال','عدد الآليات','نسبة الإنجاز %','الأعمال المنجزة','المشاكل والعوائق','المواد المستخدمة','ملاحظات السلامة','الحالة','ملاحظات الإدارة','المراجع','وقت الإرسال','وقت المراجعة'], array_map(static fn(array $row): array => [(int)$row['id'],$row['report_date'],$row['site_code'],$row['site_name'],$row['full_name'],$row['weather'],$row['temperature'],(int)$row['workers_count'],(int)$row['machinery_count'],(int)$row['progress_percent'],$row['work_done'],$row['issues'],$row['materials_used'],$row['safety_notes'],$statusLabels[$row['status']] ?? $row['status'],$row['admin_notes'],$row['reviewer_name'],$row['created_at'],$row['approved_at']], $reports)];

    $params = [];
    $expenseWhere = $range('r.report_date', $params);
    $expenses = $queryRows('SELECT e.*,r.report_date,s.name AS site_name,u.full_name FROM report_expenses e JOIN site_daily_reports r ON r.id=e.report_id JOIN sites s ON s.id=r.site_id JOIN users u ON u.id=r.engineer_id' . $expenseWhere . ' ORDER BY r.report_date DESC,e.id', $params);
    $expenseLabels = ['materials'=>'مواد','labor'=>'عمالة','fuel'=>'وقود','equipment'=>'معدات','transport'=>'نقل','other'=>'أخرى'];
    $sheets[] = ['مصروفات التقارير', ['رقم التقرير','التاريخ','الموقع','المهندس','البند','التصنيف','الكمية','سعر الوحدة','الإجمالي','ملاحظات'], array_map(static fn(array $row): array => [(int)$row['report_id'],$row['report_date'],$row['site_name'],$row['full_name'],$row['item_name'],$expenseLabels[$row['category']] ?? $row['category'],(float)$row['quantity'],(float)$row['unit_price'],(float)$row['total'],$row['notes']], $expenses)];

    $params = [];
    $receiptWhere = $range('r.report_date', $params);
    $receipts = $queryRows('SELECT f.*,r.report_date,s.name AS site_name,u.full_name FROM report_receipts f JOIN site_daily_reports r ON r.id=f.report_id JOIN sites s ON s.id=r.site_id JOIN users u ON u.id=r.engineer_id' . $receiptWhere . ' ORDER BY r.report_date DESC,f.id', $params);
    $sheets[] = ['مرفقات التقارير', ['رقم التقرير','التاريخ','الموقع','المهندس','اسم الملف','نوع الملف','الحجم KB','مسار الملف','تاريخ الرفع'], array_map(static fn(array $row): array => [(int)$row['report_id'],$row['report_date'],$row['site_name'],$row['full_name'],$row['original_name'],$row['file_type'],round((int)$row['file_size']/1024,1),$row['file_path'],$row['uploaded_at']], $receipts)];
    $filename = 'maxlond-reports-' . date('Ymd') . '.xls';
} else {
    $accounts = $queryRows('SELECT a.code,a.name,a.type,a.balance,a.is_active,p.code AS parent_code,p.name AS parent_name FROM accounts a LEFT JOIN accounts p ON p.id=a.parent_id ORDER BY a.code');
    $sheets[] = ['دليل الحسابات', ['رمز الحساب','اسم الحساب','نوع الحساب','الرصيد','الحالة','رمز الحساب الأب','الحساب الأب'], array_map(static fn(array $row): array => [$row['code'],$row['name'],$typeLabels[$row['type']] ?? $row['type'],(float)$row['balance'],(int)$row['is_active'] ? 'نشط' : 'موقوف',$row['parent_code'],$row['parent_name']], $accounts)];
    $trialRows = $queryRows('SELECT code,name,type,balance FROM accounts ORDER BY code');
    $sheets[] = ['ميزان المراجعة', ['رمز الحساب','اسم الحساب','التصنيف','الرصيد'], array_map(static fn(array $row): array => [$row['code'],$row['name'],$typeLabels[$row['type']] ?? $row['type'],(float)$row['balance']], $trialRows)];
    $inventory = $queryRows('SELECT i.code,i.name,c.name AS category_name,i.unit,i.quantity,i.min_quantity,i.unit_price,(i.quantity*i.unit_price) AS stock_value,i.location,i.is_active FROM warehouse_items i LEFT JOIN warehouse_categories c ON c.id=i.category_id ORDER BY i.code');
    $sheets[] = ['أرصدة المخزون', ['رمز المادة','اسم المادة','الفئة','الوحدة','الرصيد','الحد الأدنى','سعر الوحدة','قيمة المخزون','موقع التخزين','الحالة'], array_map(static fn(array $row): array => [$row['code'],$row['name'],$row['category_name'],$row['unit'],(float)$row['quantity'],(float)$row['min_quantity'],(float)$row['unit_price'],(float)$row['stock_value'],$row['location'],(int)$row['is_active'] ? 'نشط' : 'موقوف'], $inventory)];

    $params = [];
    $where = $range('j.entry_date', $params);
    $journals = $queryRows('SELECT j.*,s.name AS site_name,u.full_name FROM journal_entries j LEFT JOIN sites s ON s.id=j.site_id LEFT JOIN users u ON u.id=j.created_by' . $where . ' ORDER BY j.entry_date DESC,j.id DESC', $params);
    $sheets[] = ['القيود اليومية', ['رقم القيد','التاريخ','الوصف','المرجع','الموقع','مدين','دائن','الحالة','أنشأه','وقت الإنشاء'], array_map(static fn(array $row): array => [$row['entry_number'],$row['entry_date'],$row['description'],$row['reference'],$row['site_name'],(float)$row['total_debit'],(float)$row['total_credit'],$statusLabels[$row['status']] ?? $row['status'],$row['full_name'],$row['created_at']], $journals)];

    $params = [];
    $lineWhere = $range('j.entry_date', $params);
    $lines = $queryRows('SELECT j.entry_number,j.entry_date,j.description AS entry_description,a.code,a.name,l.description,l.debit,l.credit FROM journal_entry_lines l JOIN journal_entries j ON j.id=l.entry_id JOIN accounts a ON a.id=l.account_id' . $lineWhere . ' ORDER BY j.entry_date DESC,j.id DESC,l.id', $params);
    $sheets[] = ['تفاصيل القيود', ['رقم القيد','التاريخ','وصف القيد','رمز الحساب','اسم الحساب','بيان البند','مدين','دائن'], array_map(static fn(array $row): array => [$row['entry_number'],$row['entry_date'],$row['entry_description'],$row['code'],$row['name'],$row['description'],(float)$row['debit'],(float)$row['credit']], $lines)];

    $params = [];
    $expenseWhere = $range('r.report_date', $params);
    $expenses = $queryRows('SELECT e.*,r.report_date,s.name AS site_name,u.full_name FROM report_expenses e JOIN site_daily_reports r ON r.id=e.report_id JOIN sites s ON s.id=r.site_id JOIN users u ON u.id=r.engineer_id' . $expenseWhere . ' ORDER BY r.report_date DESC,e.id', $params);
    $expenseLabels = ['materials'=>'مواد','labor'=>'عمالة','fuel'=>'وقود','equipment'=>'معدات','transport'=>'نقل','other'=>'أخرى'];
    $sheets[] = ['مصروفات التقارير', ['التاريخ','الموقع','المهندس','البند','التصنيف','الكمية','سعر الوحدة','الإجمالي','ملاحظات'], array_map(static fn(array $row): array => [$row['report_date'],$row['site_name'],$row['full_name'],$row['item_name'],$expenseLabels[$row['category']] ?? $row['category'],(float)$row['quantity'],(float)$row['unit_price'],(float)$row['total'],$row['notes']], $expenses)];

    $params = [];
    $moveWhere = $range('t.created_at', $params);
    $moves = $queryRows('SELECT t.*,i.code AS item_code,i.name AS item_name,i.unit,s.name AS site_name,u.full_name FROM warehouse_transactions t JOIN warehouse_items i ON i.id=t.item_id LEFT JOIN sites s ON s.id=t.site_id JOIN users u ON u.id=t.created_by' . $moveWhere . ' ORDER BY t.created_at DESC,t.id DESC', $params);
    $sheets[] = ['حركات المخزون', ['رقم الحركة','التاريخ','رمز المادة','المادة','النوع','الكمية','الوحدة','سعر الوحدة','القيمة','الموقع','المورد','رقم الفاتورة','السبب','المسجل'], array_map(static fn(array $row): array => [(int)$row['id'],$row['created_at'],$row['item_code'],$row['item_name'],$statusLabels[$row['type']] ?? $row['type'],(float)$row['quantity'],$row['unit'],(float)$row['unit_price'],(float)$row['total_price'],$row['site_name'],$row['supplier'],$row['invoice_number'],$row['reason'],$row['full_name']], $moves)];

    $params = [];
    $repairWhere = $range('m.created_at', $params);
    $repairs = $queryRows('SELECT m.*,x.code AS machine_code,x.name AS machine_name,u.full_name FROM machinery_repairs m JOIN machinery x ON x.id=m.machinery_id JOIN users u ON u.id=m.reported_by' . $repairWhere . ' ORDER BY m.created_at DESC,m.id DESC', $params);
    $sheets[] = ['تصليحات الآليات', ['رقم الطلب','تاريخ الطلب','رمز الآلية','الآلية','العطل','الحالة','الأولوية','الفني','الورشة','أجور العمل','كلفة القطع','الإجمالي','المسجل'], array_map(static fn(array $row): array => [(int)$row['id'],$row['created_at'],$row['machine_code'],$row['machine_name'],$row['title'],$statusLabels[$row['status']] ?? $row['status'],$row['priority'],$row['technician_name'],$row['workshop'],(float)$row['labor_cost'],(float)$row['parts_cost'],(float)$row['total_cost'],$row['full_name']], $repairs)];
    $params = [];
    $partWhere = $range('m.created_at', $params);
    $parts = $queryRows('SELECT m.id AS repair_id,m.created_at,x.name AS machine_name,m.title,p.part_name,p.quantity,p.unit_price,p.total FROM machinery_repair_parts p JOIN machinery_repairs m ON m.id=p.repair_id JOIN machinery x ON x.id=m.machinery_id' . $partWhere . ' ORDER BY m.created_at DESC,p.id', $params);
    $sheets[] = ['تفاصيل قطع الغيار', ['رقم طلب التصليح','تاريخ الطلب','الآلية','وصف العطل','قطعة الغيار','الكمية','سعر الوحدة','الإجمالي'], array_map(static fn(array $row): array => [(int)$row['repair_id'],$row['created_at'],$row['machine_name'],$row['title'],$row['part_name'],(float)$row['quantity'],(float)$row['unit_price'],(float)$row['total']], $parts)];
    $filename = 'maxlond-accounting-' . date('Ymd') . '.xls';
}

$xml = '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
$xml .= '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet" xmlns:x="urn:schemas-microsoft-com:office:excel"><Styles><Style ss:ID="Header"><Font ss:Bold="1" ss:Color="#FFFFFF"/><Interior ss:Color="#174B5B" ss:Pattern="Solid"/></Style></Styles>';
$xmlValue = static fn($value): string => htmlspecialchars((string) ($value ?? ''), ENT_XML1 | ENT_QUOTES, 'UTF-8');
foreach ($sheets as [$sheetName, $headers, $rows]) {
    $xml .= '<Worksheet ss:Name="' . $xmlValue($sheetName) . '"><Table><Row ss:StyleID="Header">';
    foreach ($headers as $header) $xml .= '<Cell><Data ss:Type="String">' . $xmlValue($header) . '</Data></Cell>';
    $xml .= '</Row>';
    foreach ($rows as $row) {
        $xml .= '<Row>';
        foreach ($row as $value) {
            $numeric = is_int($value) || is_float($value);
            $xml .= '<Cell><Data ss:Type="' . ($numeric ? 'Number' : 'String') . '">' . $xmlValue($value) . '</Data></Cell>';
        }
        $xml .= '</Row>';
    }
    $xml .= '</Table></Worksheet>';
}
$xml .= '</Workbook>';
audit('excel_export_' . $type, 'export', null, 'from=' . $from . ';to=' . $to);
header('Content-Type: application/vnd.ms-excel; charset=UTF-8');
header('Content-Disposition: attachment; filename="' . $filename . '"');
header('Cache-Control: no-store, no-cache, must-revalidate');
echo $xml;
exit;