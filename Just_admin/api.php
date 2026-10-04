<?php
declare(strict_types=1);

require_once __DIR__ . '/database.php';
require_once __DIR__ . '/security.php';
require_once __DIR__ . '/helpers.php';

date_default_timezone_set('Asia/Baghdad');
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Authorization, Content-Type');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$apiRoute = Security::clean($_GET['route'] ?? '', 40);
$apiUserId = null;
$apiAllowedRoutes = $GLOBALS['apiAllowedRoutes'] ?? null;
$apiRequiredRoles = $GLOBALS['apiRequiredRoles'] ?? null;

function apiRespond(int $status, array $payload): void
{
    global $apiRoute, $apiUserId;
    http_response_code($status);
    try {
        $log = db()->prepare('INSERT INTO api_logs (user_id, endpoint, method, status_code, ip_address, user_agent) VALUES (?, ?, ?, ?, ?, ?)');
        $log->execute([
            $apiUserId,
            '/api.php?route=' . Security::clean($apiRoute, 40),
            Security::clean($_SERVER['REQUEST_METHOD'] ?? 'GET', 10),
            $status,
            Security::getClientIp(),
            substr((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255),
        ]);
    } catch (Throwable $exception) {
        error_log('Maxlond API log error: ' . $exception->getMessage());
    }
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_INVALID_UTF8_SUBSTITUTE);
    exit;
}

function apiSuccess($data, int $status = 200): void
{
    apiRespond($status, ['success' => true, 'data' => $data]);
}

function apiError(int $status, string $code, string $message): void
{
    apiRespond($status, ['success' => false, 'error' => ['code' => $code, 'message' => $message]]);
}

function apiBody(): array
{
    if (isset($_POST['report_date']) || isset($_POST['receipt'])) {
        return $_POST;
    }
    $raw = file_get_contents('php://input');
    if ($raw === false || trim($raw) === '') {
        return [];
    }
    $decoded = json_decode($raw, true);
    if (!is_array($decoded) || json_last_error() !== JSON_ERROR_NONE) {
        apiError(400, 'invalid_json', 'صيغة JSON غير صالحة');
    }
    return $decoded;
}

function apiString(array $source, string $key, int $max = 5000): string
{
    $value = $source[$key] ?? '';
    return is_scalar($value) ? Security::clean((string) $value, $max) : '';
}

function apiRequireMethod(string $method): void
{
    if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== $method) {
        header('Allow: ' . $method . ', OPTIONS');
        apiError(405, 'method_not_allowed', 'طريقة الطلب غير مدعومة لهذا المسار');
    }
}

function apiCurrentUser(): array
{
    global $apiUserId;
    $header = (string) ($_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '');
    if ($header === '' && function_exists('getallheaders')) {
        $headers = getallheaders();
        foreach ($headers as $name => $value) {
            if (strcasecmp((string) $name, 'Authorization') === 0) {
                $header = (string) $value;
                break;
            }
        }
    }
    if (!preg_match('/^Bearer\s+([a-f0-9]{64})$/i', trim($header), $matches)) {
        apiError(401, 'unauthorized', 'أرسل توكن الدخول في ترويسة Authorization');
    }
    $tokenHash = hash('sha256', $matches[1]);
    $statement = db()->prepare("SELECT t.id AS token_id, u.id, u.full_name, u.username, u.email, u.role, u.phone, u.specialization FROM api_tokens t JOIN users u ON u.id=t.user_id WHERE t.refresh_token=? AND t.revoked_at IS NULL AND t.expires_at>NOW() AND u.is_active=1 AND u.approval_status='approved' LIMIT 1");
    $statement->execute([$tokenHash]);
    $user = $statement->fetch();
    if (!$user) {
        apiError(401, 'invalid_token', 'التوكن غير صالح أو منتهي الصلاحية');
    }
    $apiUserId = (int) $user['id'];
    $user['id'] = (int) $user['id'];
    $user['token_id'] = (int) $user['token_id'];
    return $user;
}

function apiUserSites(int $userId, bool $admin): array
{
    if ($admin) {
        return db()->query('SELECT id, code, name, client_name, work_date, start_time, end_time, location, status, description FROM sites ORDER BY created_at DESC LIMIT 500')->fetchAll();
    }
    $statement = db()->prepare("SELECT id, code, name, client_name, work_date, start_time, end_time, location, status, description FROM sites WHERE status IN ('planning','active','paused') AND (manager_id IS NULL OR manager_id=?) ORDER BY name LIMIT 500");
    $statement->execute([$userId]);
    return $statement->fetchAll();
}

function apiTodayEngineerRanking(): array
{
    $ranking = [];
    $reports = db()->query("SELECT r.engineer_id,u.full_name,AVG(r.progress_percent) AS average_progress,COUNT(*) AS activity_count FROM site_daily_reports r JOIN users u ON u.id=r.engineer_id WHERE r.report_date=CURRENT_DATE() AND r.status IN ('submitted','approved') GROUP BY r.engineer_id,u.full_name")->fetchAll();
    $updates = db()->query("SELECT x.engineer_id,u.full_name,AVG(x.new_progress) AS average_progress,COUNT(*) AS activity_count,SUM(x.new_status='done') AS completed_tasks FROM work_plan_updates x JOIN users u ON u.id=x.engineer_id WHERE x.created_at>=CURRENT_DATE() AND x.created_at<DATE_ADD(CURRENT_DATE(),INTERVAL 1 DAY) GROUP BY x.engineer_id,u.full_name")->fetchAll();
    foreach ([$reports, $updates] as $rows) {
        foreach ($rows as $row) {
            $engineerId = (int) $row['engineer_id'];
            if (!isset($ranking[$engineerId])) $ranking[$engineerId] = ['engineer_id'=>$engineerId,'full_name'=>$row['full_name'],'progress_total'=>0.0,'activity_count'=>0,'completed_tasks'=>0];
            $count = (int) $row['activity_count'];
            $ranking[$engineerId]['progress_total'] += (float) $row['average_progress'] * $count;
            $ranking[$engineerId]['activity_count'] += $count;
            $ranking[$engineerId]['completed_tasks'] += (int) ($row['completed_tasks'] ?? 0);
        }
    }
    foreach ($ranking as &$engineer) {
        $engineer['score'] = $engineer['activity_count'] ? (int) round($engineer['progress_total'] / $engineer['activity_count']) : 0;
        unset($engineer['progress_total']);
    }
    unset($engineer);
    usort($ranking, static fn(array $left, array $right): int => ($right['score'] <=> $left['score']) ?: ($right['activity_count'] <=> $left['activity_count']));
    return array_slice($ranking, 0, 7);
}

function apiLogInUser(array $body): void
{
    global $apiUserId;
    apiRequireMethod('POST');
    $ip = Security::getClientIp();
    $attempts = db()->prepare("SELECT COUNT(*) FROM api_logs WHERE endpoint='/api.php?route=login' AND method='POST' AND ip_address=? AND status_code IN (401,429) AND created_at>=DATE_SUB(NOW(), INTERVAL 15 MINUTE)");
    $attempts->execute([$ip]);
    if ((int) $attempts->fetchColumn() >= 5) {
        apiError(429, 'too_many_attempts', 'محاولات دخول كثيرة. حاول بعد 15 دقيقة');
    }

    $identity = apiString($body, 'username', 150);
    $passwordValue = $body['password'] ?? null;
    $password = is_string($passwordValue) ? $passwordValue : '';
    if ($identity === '' || $password === '' || strlen($password) > 1024) {
        apiError(422, 'validation_error', 'اسم المستخدم وكلمة المرور مطلوبان');
    }
    $statement = db()->prepare('SELECT id, full_name, username, email, password_hash, role, phone, specialization, is_active, approval_status FROM users WHERE username=? OR email=? LIMIT 1');
    $statement->execute([$identity, $identity]);
    $user = $statement->fetch();
    if (!$user || !password_verify($password, (string) $user['password_hash'])) {
        apiError(401, 'invalid_credentials', 'بيانات الدخول غير صحيحة');
    }
    if ((int) $user['is_active'] !== 1 || $user['approval_status'] !== 'approved') {
        apiError(403, 'account_unavailable', $user['approval_status'] === 'pending' ? 'الحساب بانتظار موافقة الإدارة' : 'الحساب غير متاح');
    }

    $plainToken = bin2hex(random_bytes(32));
    $tokenHash = hash('sha256', $plainToken);
    $device = apiString($body, 'device_info', 255);
    $insert = db()->prepare('INSERT INTO api_tokens (user_id, refresh_token, device_info, ip_address, expires_at) VALUES (?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY))');
    $insert->execute([(int) $user['id'], $tokenHash, $device, $ip]);
    db()->prepare('UPDATE users SET last_login=NOW() WHERE id=?')->execute([(int) $user['id']]);
    $apiUserId = (int) $user['id'];
    unset($user['password_hash'], $user['is_active'], $user['approval_status']);
    apiSuccess([
        'token' => $plainToken,
        'token_type' => 'Bearer',
        'expires_in' => 2592000,
        'user' => $user,
    ]);
}

try {
    if ($apiRoute === '') {
        apiError(400, 'route_required', 'حدد المسار في المتغير route');
    }
    if (is_array($apiAllowedRoutes) && !in_array($apiRoute, $apiAllowedRoutes, true)) {
        apiError(404, 'route_not_in_module', 'هذا المسار غير متاح في واجهة هذا القسم');
    }

    if ($apiRoute === 'login') {
        apiLogInUser(apiBody());
    }

    $user = apiCurrentUser();
    $userId = (int) $user['id'];
    if (is_array($apiRequiredRoles) && !in_array($user['role'], $apiRequiredRoles, true)) {
        apiError(403, 'role_not_allowed', 'دور الحساب لا يملك صلاحية استخدام واجهة هذا القسم');
    }
    $isAdmin = $user['role'] === 'admin';
    $isEngineer = $user['role'] === 'engineer';
    $isAccountant = $user['role'] === 'accountant';
    $canAccount = $isAdmin || $isAccountant;

    if ($apiRoute === 'me') {
        apiRequireMethod('GET');
        unset($user['token_id']);
        apiSuccess($user);
    }

    if ($apiRoute === 'logout') {
        apiRequireMethod('POST');
        db()->prepare('UPDATE api_tokens SET revoked_at=NOW() WHERE id=? AND user_id=?')->execute([$user['token_id'], $userId]);
        apiSuccess(['message' => 'تم تسجيل الخروج']);
    }

    if ($apiRoute === 'dashboard') {
        apiRequireMethod('GET');
        if ($isAdmin) {
            $data = [
                'sites' => (int) db()->query("SELECT COUNT(*) FROM sites WHERE status IN ('planning','active','paused')")->fetchColumn(),
                'engineers' => (int) db()->query("SELECT COUNT(*) FROM users WHERE role='engineer' AND is_active=1 AND approval_status='approved'")->fetchColumn(),
                'machinery' => (int) db()->query("SELECT COUNT(*) FROM machinery WHERE status<>'out_of_service'")->fetchColumn(),
                'pending_reports' => (int) db()->query("SELECT COUNT(*) FROM site_daily_reports WHERE status='submitted'")->fetchColumn(),
                'inventory_value' => (float) db()->query('SELECT COALESCE(SUM(quantity*unit_price),0) FROM warehouse_items WHERE is_active=1')->fetchColumn(),
                'today_top_engineers' => apiTodayEngineerRanking(),
            ];
        } elseif ($isEngineer) {
            $tasks = db()->prepare("SELECT SUM(status IN ('pending','in_progress','review')) AS open_count,SUM(status='done') AS done_count FROM work_plans WHERE assigned_to=? OR is_broadcast=1");
            $tasks->execute([$userId]);
            $taskCounts = $tasks->fetch() ?: [];
            $reports = db()->prepare("SELECT SUM(status='submitted') AS submitted,SUM(status='approved') AS approved FROM site_daily_reports WHERE engineer_id=?");
            $reports->execute([$userId]);
            $reportCounts = $reports->fetch() ?: [];
            $data = [
                'open_tasks' => (int) ($taskCounts['open_count'] ?? 0),
                'completed_tasks' => (int) ($taskCounts['done_count'] ?? 0),
                'pending_reports' => (int) ($reportCounts['submitted'] ?? 0),
                'approved_reports' => (int) ($reportCounts['approved'] ?? 0),
            ];
        } else {
            $totals = db()->query('SELECT type,SUM(balance) AS total FROM accounts WHERE is_active=1 GROUP BY type')->fetchAll();
            $balances = ['asset'=>0.0,'liability'=>0.0,'equity'=>0.0,'revenue'=>0.0,'expense'=>0.0];
            foreach ($totals as $row) $balances[$row['type']] = (float)$row['total'];
            $data = ['accounts_count'=>(int)db()->query('SELECT COUNT(*) FROM accounts WHERE is_active=1')->fetchColumn(),'assets'=>$balances['asset'],'liabilities'=>$balances['liability'],'equity'=>$balances['equity'],'revenue'=>$balances['revenue'],'expenses'=>$balances['expense'],'net_profit'=>$balances['revenue']-$balances['expense'],'posted_entries'=>(int)db()->query("SELECT COUNT(*) FROM journal_entries WHERE status='posted'")->fetchColumn()];
        }
        apiSuccess($data);
    }

    if (in_array($apiRoute, ['accounts','account-save','account-delete','journal','journal-entry','journal-create','financial'], true)) {
        if (!$canAccount) apiError(403,'role_not_allowed','هذه المسارات متاحة للمدير والمحاسب فقط');
        require_once __DIR__ . '/helpers.php';
        if ($apiRoute === 'accounts') {
            apiRequireMethod('GET');
            $rows = db()->query('SELECT a.id,a.code,a.name,a.type,a.parent_id,p.name AS parent_name,a.balance,a.description,a.is_active FROM accounts a LEFT JOIN accounts p ON p.id=a.parent_id ORDER BY a.code')->fetchAll();
            apiSuccess($rows);
        }
        if ($apiRoute === 'account-save') {
            apiRequireMethod('POST');
            $body = apiBody();
            $id = filter_var($body['id'] ?? null,FILTER_VALIDATE_INT) ?: 0;
            $code = apiString($body,'code',50);
            $name = apiString($body,'name',200);
            $type = apiString($body,'type',20);
            $description = apiString($body,'description',500);
            $parentId = filter_var($body['parent_id'] ?? null,FILTER_VALIDATE_INT) ?: null;
            if ($code === '' || $name === '' || !in_array($type,['asset','liability','equity','revenue','expense'],true)) apiError(422,'validation_error','رمز الحساب واسمه ونوعه مطلوبة');
            if ($parentId && $parentId === $id) apiError(422,'validation_error','لا يمكن جعل الحساب أباً لنفسه');
            if ($id) {
                $usage = db()->prepare('SELECT COUNT(*) FROM journal_entry_lines WHERE account_id=?');
                $usage->execute([$id]);
                $current = db()->prepare('SELECT type FROM accounts WHERE id=?');
                $current->execute([$id]);
                $currentType = $current->fetchColumn();
                if ($currentType === false) apiError(404,'account_not_found','الحساب غير موجود');
                if ($currentType !== $type && (int)$usage->fetchColumn() > 0) apiError(409,'account_type_locked','لا يمكن تغيير نوع حساب مستخدم في قيود');
                $isActive=array_key_exists('is_active',$body)?(int)(bool)$body['is_active']:1;
                db()->prepare('UPDATE accounts SET code=?,name=?,type=?,parent_id=?,description=?,is_active=? WHERE id=?')->execute([$code,$name,$type,$parentId,$description,$isActive,$id]);
                audit('account_updated','account',$id);
                apiSuccess(['account_id'=>$id,'updated'=>true]);
            }
            db()->prepare('INSERT INTO accounts (code,name,type,parent_id,description,is_active) VALUES (?,?,?,?,?,?)')->execute([$code,$name,$type,$parentId,$description,empty($body['is_active'])?1:(int)(bool)$body['is_active']]);
            $newId=(int)db()->lastInsertId();
            audit('account_created','account',$newId);
            apiSuccess(['account_id'=>$newId,'created'=>true],201);
        }
        if ($apiRoute === 'account-delete') {
            apiRequireMethod('POST');
            $body=apiBody();
            $id=filter_var($body['account_id'] ?? null,FILTER_VALIDATE_INT);
            if (!$id) apiError(422,'validation_error','account_id مطلوب');
            $check=db()->prepare('SELECT code,balance FROM accounts WHERE id=?');
            $check->execute([$id]);
            $account=$check->fetch();
            if (!$account) apiError(404,'account_not_found','الحساب غير موجود');
            $used=db()->prepare('SELECT COUNT(*) FROM journal_entry_lines WHERE account_id=?');
            $used->execute([$id]);
            if ((int)$used->fetchColumn()>0 || abs((float)$account['balance'])>0.005) apiError(409,'account_in_use','لا يمكن حذف حساب مستخدم في القيود أو له رصيد');
            db()->prepare('DELETE FROM accounts WHERE id=?')->execute([$id]);
            audit('account_deleted','account',(int)$id,'code='.$account['code']);
            apiSuccess(['account_id'=>(int)$id,'deleted'=>true]);
        }
        if ($apiRoute === 'journal') {
            apiRequireMethod('GET');
            $from=Security::clean($_GET['from'] ?? '',10); $to=Security::clean($_GET['to'] ?? '',10);
            $sql='SELECT j.id,j.entry_number,j.entry_date,j.description,j.reference,j.site_id,s.name AS site_name,j.total_debit,j.total_credit,j.status,j.created_at FROM journal_entries j LEFT JOIN sites s ON s.id=j.site_id';
            $conditions=[]; $params=[];
            foreach ([['j.entry_date',$from,'>='],['j.entry_date',$to,'<=']] as [$column,$value,$operator]) if ($value!=='') { $date=DateTime::createFromFormat('!Y-m-d',$value); if (!$date || $date->format('Y-m-d')!==$value) apiError(422,'validation_error','التاريخ يجب أن يكون YYYY-MM-DD'); $conditions[]="$column $operator ?"; $params[]=$value; }
            if ($conditions) $sql.=' WHERE '.implode(' AND ',$conditions);
            $sql.=' ORDER BY j.entry_date DESC,j.id DESC LIMIT 300';
            $query=db()->prepare($sql); $query->execute($params); apiSuccess($query->fetchAll());
        }
        if ($apiRoute === 'journal-entry') {
            apiRequireMethod('GET');
            $id=filter_input(INPUT_GET,'id',FILTER_VALIDATE_INT);
            if (!$id) apiError(422,'validation_error','id مطلوب');
            $query=db()->prepare('SELECT j.*,s.name AS site_name,u.full_name AS created_by_name FROM journal_entries j LEFT JOIN sites s ON s.id=j.site_id LEFT JOIN users u ON u.id=j.created_by WHERE j.id=?');
            $query->execute([$id]); $entry=$query->fetch();
            if (!$entry) apiError(404,'journal_entry_not_found','القيد غير موجود');
            $lines=db()->prepare('SELECT l.id,l.account_id,a.code AS account_code,a.name AS account_name,l.debit,l.credit,l.description FROM journal_entry_lines l JOIN accounts a ON a.id=l.account_id WHERE l.entry_id=? ORDER BY l.id');
            $lines->execute([$id]); $entry['lines']=$lines->fetchAll(); apiSuccess($entry);
        }
        if ($apiRoute === 'journal-create') {
            apiRequireMethod('POST');
            $body=apiBody(); $description=apiString($body,'description',500); $rawLines=$body['lines'] ?? [];
            if ($description==='' || !is_array($rawLines)) apiError(422,'validation_error','الوصف وقائمة بنود القيد مطلوبة');
            $lines=[];
            foreach ($rawLines as $line) {
                if (!is_array($line)) continue;
                $accountId=filter_var($line['account_id'] ?? null,FILTER_VALIDATE_INT);
                $debit=filter_var($line['debit'] ?? 0,FILTER_VALIDATE_FLOAT); $credit=filter_var($line['credit'] ?? 0,FILTER_VALIDATE_FLOAT);
                if (!$accountId || $debit===false || $credit===false) apiError(422,'validation_error','بيانات بند القيد غير صالحة');
                $lines[]=['account_id'=>(int)$accountId,'debit'=>(float)$debit,'credit'=>(float)$credit,'description'=>apiString($line,'description',500)];
            }
            try { $entryId=createJournalEntry($description,$lines,$userId,filter_var($body['site_id'] ?? null,FILTER_VALIDATE_INT) ?: null); }
            catch (InvalidArgumentException $exception) { apiError(422,'unbalanced_entry',$exception->getMessage()); }
            audit('journal_created','journal_entry',$entryId);
            apiSuccess(['entry_id'=>$entryId],201);
        }
        if ($apiRoute === 'financial') {
            apiRequireMethod('GET');
            $totals=db()->query('SELECT type,SUM(balance) AS total FROM accounts WHERE is_active=1 GROUP BY type')->fetchAll();
            $balances=['asset'=>0.0,'liability'=>0.0,'equity'=>0.0,'revenue'=>0.0,'expense'=>0.0];
            foreach ($totals as $row) $balances[$row['type']]=(float)$row['total'];
            $trial=db()->query('SELECT code,name,type,balance FROM accounts WHERE is_active=1 ORDER BY code')->fetchAll();
            apiSuccess(['balances'=>$balances,'net_profit'=>$balances['revenue']-$balances['expense'],'trial_balance'=>$trial]);
        }
    }

    if ($apiRoute === 'sites') {
        apiRequireMethod('GET');
        if ($isAccountant) apiError(403,'role_not_allowed','المواقع غير متاحة في واجهة المحاسب');
        apiSuccess(apiUserSites($userId, $isAdmin));
    }

    if ($apiRoute === 'site-save') {
        apiRequireMethod('POST');
        if (!$isAdmin) apiError(403,'role_not_allowed','إدارة المواقع متاحة للمدير فقط');
        $body=apiBody(); $id=filter_var($body['id'] ?? null,FILTER_VALIDATE_INT) ?: 0;
        $name=apiString($body,'name',200); $status=apiString($body,'status',20);
        if ($name==='' || !in_array($status,['planning','active','paused','completed','cancelled'],true)) apiError(422,'validation_error','اسم الموقع وحالة صحيحة مطلوبان');
        $managerId=filter_var($body['manager_id'] ?? null,FILTER_VALIDATE_INT) ?: null;
        if ($managerId) { $engineer=db()->prepare("SELECT id FROM users WHERE id=? AND role='engineer' AND is_active=1 AND approval_status='approved'"); $engineer->execute([$managerId]); if (!$engineer->fetchColumn()) apiError(422,'invalid_manager','المهندس المسؤول غير متاح'); }
        $values=[$name,apiString($body,'client_name',200),apiString($body,'work_date',10) ?: null,apiString($body,'start_time',8) ?: null,apiString($body,'end_time',8) ?: null,apiString($body,'location',255),max(0,(float)($body['budget'] ?? 0)),$status,$managerId,apiString($body,'description',5000)];
        if ($id) {
            $exists=db()->prepare('SELECT id FROM sites WHERE id=?'); $exists->execute([$id]); if (!$exists->fetchColumn()) apiError(404,'site_not_found','الموقع غير موجود');
            db()->prepare('UPDATE sites SET name=?,client_name=?,work_date=?,start_time=?,end_time=?,location=?,budget=?,status=?,manager_id=?,description=? WHERE id=?')->execute(array_merge($values,[$id]));
            audit('site_updated','site',$id); apiSuccess(['site_id'=>$id,'updated'=>true]);
        }
        $codeQuery=db()->prepare("SELECT COALESCE(MAX(CAST(SUBSTRING_INDEX(code,'-',-1) AS UNSIGNED)),0) FROM sites WHERE code LIKE ?"); $codeQuery->execute(['SP-'.date('Ymd').'-%']);
        $code='SP-'.date('Ymd').'-'.str_pad((string)((int)$codeQuery->fetchColumn()+1),3,'0',STR_PAD_LEFT);
        db()->prepare('INSERT INTO sites (code,name,client_name,work_date,start_time,end_time,location,budget,status,manager_id,description,created_by) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)')->execute(array_merge([$code],$values,[$userId]));
        $newId=(int)db()->lastInsertId(); audit('site_created','site',$newId); apiSuccess(['site_id'=>$newId,'code'=>$code],201);
    }

    if ($apiRoute === 'site-cancel') {
        apiRequireMethod('POST');
        if (!$isAdmin) apiError(403,'role_not_allowed','إدارة المواقع متاحة للمدير فقط');
        $body=apiBody(); $id=filter_var($body['site_id'] ?? null,FILTER_VALIDATE_INT); if (!$id) apiError(422,'validation_error','site_id مطلوب');
        $update=db()->prepare("UPDATE sites SET status='cancelled' WHERE id=? AND status<>'cancelled'"); $update->execute([$id]);
        if (!$update->rowCount()) apiError(404,'site_not_found','الموقع غير موجود أو ملغى مسبقاً');
        audit('site_cancelled','site',(int)$id); apiSuccess(['site_id'=>(int)$id,'status'=>'cancelled']);
    }

    if ($apiRoute === 'machinery') {
        apiRequireMethod('GET');
        if (!$isAdmin) apiError(403,'role_not_allowed','قائمة الآليات متاحة للمدير فقط');
        $rows = db()->query('SELECT id,code,name,plate_number,operator_name,status,hourly_cost FROM machinery ORDER BY name LIMIT 500')->fetchAll();
        apiSuccess($rows);
    }

    if (in_array($apiRoute,['warehouse-items','warehouse-categories','warehouse-moves','warehouse-item-save','warehouse-item-status','warehouse-move-create','warehouse-category-save'],true)) {
        apiRequireMethod(in_array($apiRoute,['warehouse-items','warehouse-categories','warehouse-moves'],true) ? 'GET' : 'POST');
        if (!$isAdmin) apiError(403,'role_not_allowed','إدارة المخزون متاحة للمدير فقط');
        require_once __DIR__ . '/helpers.php';
        if ($apiRoute==='warehouse-items') {
            $sql='SELECT i.id,i.code,i.name,i.category_id,c.name AS category_name,i.unit,i.quantity,i.min_quantity,i.unit_price,i.location,i.notes,i.is_active FROM warehouse_items i LEFT JOIN warehouse_categories c ON c.id=i.category_id';
            $conditions=[]; $params=[];
            if (($_GET['low'] ?? '')==='1') $conditions[]='i.is_active=1 AND i.quantity<=i.min_quantity';
            elseif (($_GET['active'] ?? '')!=='all') $conditions[]='i.is_active=1';
            $category=filter_input(INPUT_GET,'category_id',FILTER_VALIDATE_INT); if ($category) {$conditions[]='i.category_id=?';$params[]=$category;}
            if ($conditions) $sql.=' WHERE '.implode(' AND ',$conditions);
            $sql.=' ORDER BY i.name LIMIT 500'; $query=db()->prepare($sql);$query->execute($params);apiSuccess($query->fetchAll());
        }
        if ($apiRoute==='warehouse-categories') { apiSuccess(db()->query('SELECT id,name,description FROM warehouse_categories ORDER BY name')->fetchAll()); }
        if ($apiRoute==='warehouse-moves') {
            $sql='SELECT t.id,t.item_id,i.code AS item_code,i.name AS item_name,t.type,t.quantity,i.unit,t.unit_price,t.total_price,t.site_id,s.name AS site_name,t.supplier,t.invoice_number,t.reason,t.created_at,u.full_name AS created_by FROM warehouse_transactions t JOIN warehouse_items i ON i.id=t.item_id LEFT JOIN sites s ON s.id=t.site_id JOIN users u ON u.id=t.created_by';
            $params=[]; $itemId=filter_input(INPUT_GET,'item_id',FILTER_VALIDATE_INT); if ($itemId) {$sql.=' WHERE t.item_id=?';$params[]=$itemId;}
            $sql.=' ORDER BY t.created_at DESC,t.id DESC LIMIT 300'; $query=db()->prepare($sql);$query->execute($params);apiSuccess($query->fetchAll());
        }
        if ($apiRoute==='warehouse-item-save') {
            $body=apiBody(); $id=filter_var($body['id'] ?? null,FILTER_VALIDATE_INT) ?: 0;
            $code=apiString($body,'code',50);$name=apiString($body,'name',200);$unit=apiString($body,'unit',30) ?: 'قطعة';
            if ($code==='' || $name==='') apiError(422,'validation_error','رمز المادة واسمها مطلوبان');
            $category=filter_var($body['category_id'] ?? null,FILTER_VALIDATE_INT) ?: null;
            $values=[$code,$name,$category,$unit,max(0,(float)($body['min_quantity'] ?? 0)),max(0,(float)($body['unit_price'] ?? 0)),apiString($body,'location',100),apiString($body,'notes',5000)];
            if ($id) {db()->prepare('UPDATE warehouse_items SET code=?,name=?,category_id=?,unit=?,min_quantity=?,unit_price=?,location=?,notes=? WHERE id=?')->execute(array_merge($values,[$id]));audit('warehouse_item_updated','warehouse_item',$id);apiSuccess(['item_id'=>$id,'updated'=>true]);}
            db()->prepare('INSERT INTO warehouse_items (code,name,category_id,unit,quantity,min_quantity,unit_price,location,notes) VALUES (?,?,?,?,0,?,?,?,?)')->execute($values);$newId=(int)db()->lastInsertId();audit('warehouse_item_created','warehouse_item',$newId);apiSuccess(['item_id'=>$newId],201);
        }
        if ($apiRoute==='warehouse-item-status') {
            $body=apiBody();$id=filter_var($body['item_id'] ?? null,FILTER_VALIDATE_INT);$active=filter_var($body['is_active'] ?? null,FILTER_VALIDATE_INT);
            if (!$id || !in_array($active,[0,1],true)) apiError(422,'validation_error','item_id وis_active مطلوبان');
            db()->prepare('UPDATE warehouse_items SET is_active=? WHERE id=?')->execute([$active,$id]);audit('warehouse_item_status','warehouse_item',(int)$id);apiSuccess(['item_id'=>(int)$id,'is_active'=>(bool)$active]);
        }
        if ($apiRoute==='warehouse-category-save') {
            $body=apiBody();$id=filter_var($body['id'] ?? null,FILTER_VALIDATE_INT) ?: 0;$name=apiString($body,'name',100);
            if ($name==='') apiError(422,'validation_error','اسم الفئة مطلوب');
            if ($id) {db()->prepare('UPDATE warehouse_categories SET name=?,description=? WHERE id=?')->execute([$name,apiString($body,'description',500),$id]);apiSuccess(['category_id'=>$id,'updated'=>true]);}
            db()->prepare('INSERT INTO warehouse_categories (name,description) VALUES (?,?)')->execute([$name,apiString($body,'description',500)]);apiSuccess(['category_id'=>(int)db()->lastInsertId()],201);
        }
        if ($apiRoute==='warehouse-move-create') {
            $body=apiBody();$itemId=filter_var($body['item_id'] ?? null,FILTER_VALIDATE_INT);$type=apiString($body,'type',10);$quantity=filter_var($body['quantity'] ?? null,FILTER_VALIDATE_FLOAT);
            if (!$itemId || !in_array($type,['in','out','adjust'],true) || $quantity===false || $quantity<=0) apiError(422,'validation_error','تحقق من المادة ونوع الحركة والكمية');
            $pdo=db();$pdo->beginTransaction();
            try {
                $itemQuery=$pdo->prepare('SELECT * FROM warehouse_items WHERE id=? AND is_active=1 FOR UPDATE');$itemQuery->execute([$itemId]);$item=$itemQuery->fetch();if (!$item) throw new DomainException('المادة غير متاحة');
                $current=(float)$item['quantity'];if ($type==='out' && $quantity>$current) throw new DomainException('الكمية المطلوبة أكبر من الرصيد المتاح');
                $next=$type==='in'?$current+$quantity:($type==='out'?$current-$quantity:$quantity);$price=max(0,(float)($body['unit_price'] ?? 0));$effective=$price>0?$price:(float)$item['unit_price'];$total=$type==='adjust'?abs($next-$current)*$effective:$quantity*$effective;
                $siteId=filter_var($body['site_id'] ?? null,FILTER_VALIDATE_INT) ?: null;
                $pdo->prepare('UPDATE warehouse_items SET quantity=?,unit_price=? WHERE id=?')->execute([$next,$effective,$itemId]);
                $pdo->prepare('INSERT INTO warehouse_transactions (item_id,type,quantity,unit_price,total_price,site_id,supplier,invoice_number,reason,created_by) VALUES (?,?,?,?,?,?,?,?,?,?)')->execute([$itemId,$type,$quantity,$effective,$total,$siteId,apiString($body,'supplier',200),apiString($body,'invoice_number',100),apiString($body,'reason',500),$userId]);
                if ($type!=='adjust' && $total>0) { $codes=$type==='in'?['1300','1100']:['5100','1300'];$account=$pdo->prepare('SELECT id FROM accounts WHERE code=?');$account->execute([$codes[0]]);$debit=(int)$account->fetchColumn();$account->execute([$codes[1]]);$credit=(int)$account->fetchColumn();if ($debit && $credit) createJournalEntry('حركة مخزن '.statusLabel($type).' · '.$item['name'],[['account_id'=>$debit,'debit'=>$total,'credit'=>0],['account_id'=>$credit,'debit'=>0,'credit'=>$total]],$userId,$siteId); }
                $pdo->commit();
            } catch (DomainException $exception) {if ($pdo->inTransaction())$pdo->rollBack();apiError(422,'warehouse_conflict',$exception->getMessage());}
            catch (Throwable $exception) {if ($pdo->inTransaction())$pdo->rollBack();throw $exception;}
            audit('warehouse_'.$type,'warehouse_item',(int)$itemId);apiSuccess(['item_id'=>(int)$itemId,'quantity'=>(float)$next,'type'=>$type],201);
        }
    }

    if (in_array($apiRoute,['repairs','repair-create','repair-update','repair-status'],true)) {
        apiRequireMethod($apiRoute==='repairs'?'GET':'POST');
        if (!$isAdmin) apiError(403,'role_not_allowed','إدارة الصيانة متاحة للمدير فقط');
        require_once __DIR__ . '/helpers.php';
        if ($apiRoute==='repairs') {
            $id=filter_input(INPUT_GET,'id',FILTER_VALIDATE_INT);$sql='SELECT r.*,m.code AS machinery_code,m.name AS machinery_name,u.full_name AS reported_by FROM machinery_repairs r JOIN machinery m ON m.id=r.machinery_id JOIN users u ON u.id=r.reported_by';$params=[];
            if ($id) {$sql.=' WHERE r.id=?';$params[]=$id;}$sql.=' ORDER BY r.created_at DESC LIMIT 300';$query=db()->prepare($sql);$query->execute($params);$rows=$query->fetchAll();
            if ($id) {if (!$rows)apiError(404,'repair_not_found','طلب الصيانة غير موجود');$parts=db()->prepare('SELECT id,part_name,quantity,unit_price,total FROM machinery_repair_parts WHERE repair_id=? ORDER BY id');$parts->execute([$id]);$rows[0]['parts']=$parts->fetchAll();apiSuccess($rows[0]);} apiSuccess($rows);
        }
        if ($apiRoute==='repair-create' || $apiRoute==='repair-update') {
            $body=apiBody();$id=filter_var($body['id'] ?? null,FILTER_VALIDATE_INT) ?: 0;$machineryId=filter_var($body['machinery_id'] ?? null,FILTER_VALIDATE_INT);$title=apiString($body,'title',200);
            $problem=apiString($body,'problem_type',20) ?: 'mechanical';$priority=apiString($body,'priority',10) ?: 'medium';$parts=$body['parts'] ?? [];
            if (!$machineryId || $title==='' || !in_array($problem,['mechanical','electrical','body','tires','other'],true) || !in_array($priority,['low','medium','high','urgent'],true) || !is_array($parts)) apiError(422,'validation_error','تحقق من بيانات طلب التصليح');
            $rows=[];$partsCost=0.0;foreach($parts as $part){if(!is_array($part))continue;$partName=apiString($part,'part_name',200);if($partName==='')continue;$qty=max(0,(float)($part['quantity']??0));$price=max(0,(float)($part['unit_price']??0));$total=$qty*$price;$partsCost+=$total;$rows[]=[$partName,$qty,$price,$total];}
            $labor=max(0,(float)($body['labor_cost']??0));$pdo=db();$pdo->beginTransaction();
            try {
                if ($apiRoute==='repair-create') {$pdo->prepare("INSERT INTO machinery_repairs (machinery_id,title,description,problem_type,status,priority,technician_name,workshop,labor_cost,parts_cost,total_cost,reported_by,started_at,notes) VALUES (?,?,?,?,'pending',?,?,?,?,?,?,?,NOW(),?)")->execute([$machineryId,$title,apiString($body,'description',5000),$problem,$priority,apiString($body,'technician_name',150),apiString($body,'workshop',200),$labor,$partsCost,$labor+$partsCost,$userId,apiString($body,'notes',5000)]);$repairId=(int)$pdo->lastInsertId();$pdo->prepare("UPDATE machinery SET status='maintenance' WHERE id=?")->execute([$machineryId]);}
                else {$lock=$pdo->prepare("SELECT status FROM machinery_repairs WHERE id=? AND status IN ('pending','in_progress','waiting_parts') FOR UPDATE");$lock->execute([$id]);if (!$lock->fetchColumn())throw new DomainException('طلب التصليح غير موجود أو مغلق');$existing=$pdo->prepare('SELECT COUNT(*) FROM journal_entries WHERE reference=?');$existing->execute(['repair-'.$id]);if ((int)$existing->fetchColumn())throw new DomainException('طلب التصليح مرتبط بقيد محاسبي');$repairId=$id;$pdo->prepare('UPDATE machinery_repairs SET machinery_id=?,title=?,description=?,problem_type=?,priority=?,technician_name=?,workshop=?,labor_cost=?,parts_cost=?,total_cost=?,notes=? WHERE id=?')->execute([$machineryId,$title,apiString($body,'description',5000),$problem,$priority,apiString($body,'technician_name',150),apiString($body,'workshop',200),$labor,$partsCost,$labor+$partsCost,apiString($body,'notes',5000),$id]);$pdo->prepare('DELETE FROM machinery_repair_parts WHERE repair_id=?')->execute([$id]);}
                $insert=$pdo->prepare('INSERT INTO machinery_repair_parts (repair_id,part_name,quantity,unit_price,total) VALUES (?,?,?,?,?)');foreach($rows as $part)$insert->execute(array_merge([$repairId],$part));$pdo->commit();
            } catch (DomainException $exception) {if($pdo->inTransaction())$pdo->rollBack();apiError(409,'repair_locked',$exception->getMessage());}
            catch(Throwable $exception){if($pdo->inTransaction())$pdo->rollBack();throw $exception;}
            audit($apiRoute==='repair-create'?'repair_created':'repair_updated','machinery_repair',(int)$repairId);apiSuccess(['repair_id'=>(int)$repairId,'total_cost'=>$labor+$partsCost],$apiRoute==='repair-create'?201:200);
        }
        if ($apiRoute==='repair-status') {
            $body=apiBody();$id=filter_var($body['repair_id'] ?? null,FILTER_VALIDATE_INT);$status=apiString($body,'status',20);
            if (!$id || !in_array($status,['pending','in_progress','waiting_parts','completed','cancelled'],true))apiError(422,'validation_error','repair_id وحالة صحيحة مطلوبان');
            $pdo=db();$pdo->beginTransaction();
            try {$pdo->prepare('UPDATE machinery_repairs SET status=?,started_at=IF(?="in_progress" AND started_at IS NULL,NOW(),started_at),completed_at=IF(?="completed",NOW(),completed_at) WHERE id=?')->execute([$status,$status,$status,$id]);$query=$pdo->prepare('SELECT machinery_id,title,total_cost FROM machinery_repairs WHERE id=?');$query->execute([$id]);$repair=$query->fetch();if(!$repair)throw new DomainException('طلب التصليح غير موجود');
                if($status==='completed' && (float)$repair['total_cost']>0){$reference='repair-'.$id;$exists=$pdo->prepare('SELECT id FROM journal_entries WHERE reference=?');$exists->execute([$reference]);if(!$exists->fetchColumn()){$acct=$pdo->prepare('SELECT id FROM accounts WHERE code=?');$acct->execute(['5400']);$expense=(int)$acct->fetchColumn();$acct->execute(['1100']);$cash=(int)$acct->fetchColumn();if($expense&&$cash)createJournalEntry('تكلفة تصليح · '.$repair['title'],[['account_id'=>$expense,'debit'=>(float)$repair['total_cost'],'credit'=>0],['account_id'=>$cash,'debit'=>0,'credit'=>(float)$repair['total_cost']]],$userId,null,null,$reference);}}
                if(in_array($status,['completed','cancelled'],true)){$open=$pdo->prepare("SELECT COUNT(*) FROM machinery_repairs WHERE machinery_id=? AND status IN ('pending','in_progress','waiting_parts')");$open->execute([(int)$repair['machinery_id']]);$machineStatus=(int)$open->fetchColumn()?'maintenance':'available';}else $machineStatus='maintenance';
                $pdo->prepare('UPDATE machinery SET status=? WHERE id=?')->execute([$machineStatus,(int)$repair['machinery_id']]);$pdo->commit();
            } catch(DomainException $exception){if($pdo->inTransaction())$pdo->rollBack();apiError(404,'repair_not_found',$exception->getMessage());}
            catch(Throwable $exception){if($pdo->inTransaction())$pdo->rollBack();throw $exception;}
            audit('repair_status_updated','machinery_repair',(int)$id,$status);apiSuccess(['repair_id'=>(int)$id,'status'=>$status]);
        }
    }

    if ($apiRoute === 'machinery-save') {
        apiRequireMethod('POST');
        if (!$isAdmin) apiError(403,'role_not_allowed','إدارة الآليات متاحة للمدير فقط');
        $body=apiBody(); $id=filter_var($body['id'] ?? null,FILTER_VALIDATE_INT) ?: 0;
        $code=apiString($body,'code',50); $name=apiString($body,'name',200); $status=apiString($body,'status',30);
        if ($code==='' || $name==='' || !in_array($status,['available','in_use','maintenance','out_of_service'],true)) apiError(422,'validation_error','رمز الآلية واسمها وحالتها مطلوبة');
        $values=[$code,$name,apiString($body,'plate_number',50),apiString($body,'operator_name',150),$status,max(0,(float)($body['hourly_cost'] ?? 0)),apiString($body,'notes',5000)];
        if ($id) { db()->prepare('UPDATE machinery SET code=?,name=?,plate_number=?,operator_name=?,status=?,hourly_cost=?,notes=? WHERE id=?')->execute(array_merge($values,[$id])); audit('machinery_updated','machinery',$id); apiSuccess(['machinery_id'=>$id,'updated'=>true]); }
        db()->prepare('INSERT INTO machinery (code,name,plate_number,operator_name,status,hourly_cost,notes) VALUES (?,?,?,?,?,?,?)')->execute($values); $newId=(int)db()->lastInsertId(); audit('machinery_created','machinery',$newId); apiSuccess(['machinery_id'=>$newId],201);
    }

    if ($apiRoute === 'machinery-status') {
        apiRequireMethod('POST');
        if (!$isAdmin) apiError(403,'role_not_allowed','إدارة الآليات متاحة للمدير فقط');
        $body=apiBody(); $id=filter_var($body['machinery_id'] ?? null,FILTER_VALIDATE_INT); $status=apiString($body,'status',30);
        if (!$id || !in_array($status,['available','in_use','maintenance','out_of_service'],true)) apiError(422,'validation_error','machinery_id وحالة صحيحة مطلوبان');
        $update=db()->prepare('UPDATE machinery SET status=? WHERE id=?'); $update->execute([$status,$id]); if (!$update->rowCount()) apiError(404,'machinery_not_found','الآلية غير موجودة أو حالتها لم تتغير');
        audit('machinery_status_updated','machinery',(int)$id); apiSuccess(['machinery_id'=>(int)$id,'status'=>$status]);
    }

    if ($apiRoute === 'users') {
        apiRequireMethod('GET');
        if (!$isAdmin) apiError(403,'role_not_allowed','إدارة المستخدمين متاحة للمدير فقط');
        $rows=db()->query('SELECT id,full_name,username,email,role,phone,specialization,is_active,approval_status,last_login,created_at FROM users ORDER BY role,full_name')->fetchAll();
        apiSuccess($rows);
    }

    if ($apiRoute === 'user-save') {
        apiRequireMethod('POST');
        if (!$isAdmin) apiError(403,'role_not_allowed','إدارة المستخدمين متاحة للمدير فقط');
        $body=apiBody(); $id=filter_var($body['id'] ?? null,FILTER_VALIDATE_INT) ?: 0;
        $name=apiString($body,'full_name',150); $username=apiString($body,'username',80); $email=apiString($body,'email',150);
        $role=apiString($body,'role',20); $phone=apiString($body,'phone',30); $specialization=apiString($body,'specialization',100);
        if ($name==='' || !preg_match('/^[A-Za-z0-9_.-]{3,80}$/',$username) || !filter_var($email,FILTER_VALIDATE_EMAIL) || !in_array($role,['engineer','accountant'],true)) apiError(422,'validation_error','تحقق من الاسم واسم المستخدم والبريد الإلكتروني والدور');
        if ($id) {
            $existing=db()->prepare('SELECT role FROM users WHERE id=?'); $existing->execute([$id]); $oldRole=$existing->fetchColumn(); if ($oldRole===false || $oldRole==='admin') apiError(404,'user_not_found','المستخدم غير موجود أو محمي');
            $dupe=db()->prepare('SELECT COUNT(*) FROM users WHERE (username=? OR email=?) AND id<>?'); $dupe->execute([$username,$email,$id]); if ((int)$dupe->fetchColumn()) apiError(409,'user_conflict','اسم المستخدم أو البريد مستخدم');
            db()->prepare('UPDATE users SET full_name=?,username=?,email=?,role=?,phone=?,specialization=? WHERE id=?')->execute([$name,$username,$email,$role,$phone,$specialization,$id]); audit('user_updated','user',$id); apiSuccess(['user_id'=>$id,'updated'=>true]);
        }
        $password=$body['password'] ?? null; if (!is_string($password) || strlen($password)<10 || strlen($password)>1024) apiError(422,'validation_error','كلمة المرور يجب ألا تقل عن 10 أحرف');
        $dupe=db()->prepare('SELECT COUNT(*) FROM users WHERE username=? OR email=?'); $dupe->execute([$username,$email]); if ((int)$dupe->fetchColumn()) apiError(409,'user_conflict','اسم المستخدم أو البريد مستخدم');
        db()->prepare("INSERT INTO users (full_name,username,email,password_hash,role,phone,specialization,is_active,approval_status) VALUES (?,?,?,?,?,?,?,1,'approved')")->execute([$name,$username,$email,password_hash($password,PASSWORD_DEFAULT),$role,$phone,$specialization]);
        $newId=(int)db()->lastInsertId(); audit('user_created','user',$newId); apiSuccess(['user_id'=>$newId,'role'=>$role],201);
    }

    if ($apiRoute === 'user-status') {
        apiRequireMethod('POST');
        if (!$isAdmin) apiError(403,'role_not_allowed','إدارة المستخدمين متاحة للمدير فقط');
        $body=apiBody(); $id=filter_var($body['user_id'] ?? null,FILTER_VALIDATE_INT); $active=filter_var($body['is_active'] ?? null,FILTER_VALIDATE_INT);
        if (!$id || !in_array($active,[0,1],true) || $id===$userId) apiError(422,'validation_error','user_id وحالة صالحة مطلوبة ولا يمكن تعطيل حسابك الحالي');
        $update=db()->prepare("UPDATE users SET is_active=? WHERE id=? AND role<>'admin'"); $update->execute([$active,$id]); if (!$update->rowCount()) apiError(404,'user_not_found','المستخدم غير موجود أو محمي');
        if (!$active) db()->prepare('UPDATE api_tokens SET revoked_at=NOW() WHERE user_id=? AND revoked_at IS NULL')->execute([$id]);
        audit('user_status_updated','user',(int)$id,$active?'active':'inactive'); apiSuccess(['user_id'=>(int)$id,'is_active'=>(bool)$active]);
    }

    if ($apiRoute === 'tasks') {
        apiRequireMethod('GET');
        if (!$isAdmin && !$isEngineer) apiError(403,'role_not_allowed','المهام متاحة للمدير والمهندس فقط');
        $sql = 'SELECT p.id,p.site_id,s.name AS site_name,p.title,p.description,p.assigned_to,p.is_broadcast,p.priority,p.status,p.progress,p.created_at,p.updated_at FROM work_plans p JOIN sites s ON s.id=p.site_id';
        $conditions = [];
        $parameters = [];
        if (!$isAdmin) {
            $conditions[] = '(p.assigned_to=? OR p.is_broadcast=1)';
            $parameters[] = $userId;
        }
        $siteId = filter_input(INPUT_GET, 'site_id', FILTER_VALIDATE_INT);
        if ($siteId) {
            $conditions[] = 'p.site_id=?';
            $parameters[] = $siteId;
        }
        $status = Security::clean($_GET['status'] ?? '', 30);
        if ($status !== '' && in_array($status, ['pending','in_progress','review','done','cancelled'], true)) {
            $conditions[] = 'p.status=?';
            $parameters[] = $status;
        }
        if ($conditions !== []) $sql .= ' WHERE ' . implode(' AND ', $conditions);
        $sql .= " ORDER BY FIELD(p.priority,'urgent','high','medium','low'),p.updated_at DESC LIMIT 200";
        $statement = db()->prepare($sql);
        $statement->execute($parameters);
        apiSuccess($statement->fetchAll());
    }

    if ($apiRoute === 'work-plan-save') {
        apiRequireMethod('POST');
        if (!$isAdmin) apiError(403,'role_not_allowed','إدارة خطط العمل متاحة للمدير فقط');
        $body=apiBody(); $id=filter_var($body['id'] ?? null,FILTER_VALIDATE_INT) ?: 0;
        $siteId=filter_var($body['site_id'] ?? null,FILTER_VALIDATE_INT); $title=apiString($body,'title',255);
        $priority=apiString($body,'priority',10); $broadcast=!empty($body['is_broadcast']) ? 1 : 0;
        $assigned=$broadcast ? null : (filter_var($body['assigned_to'] ?? null,FILTER_VALIDATE_INT) ?: null);
        if (!$siteId || $title==='' || !in_array($priority,['low','medium','high','urgent'],true)) apiError(422,'validation_error','الموقع والعنوان والأولوية مطلوبة');
        $siteCheck=db()->prepare("SELECT id FROM sites WHERE id=? AND status NOT IN ('completed','cancelled')"); $siteCheck->execute([$siteId]); if (!$siteCheck->fetchColumn()) apiError(422,'invalid_site','الموقع غير متاح لخطة عمل');
        if ($assigned) { $engineer=db()->prepare("SELECT id FROM users WHERE id=? AND role='engineer' AND is_active=1 AND approval_status='approved'"); $engineer->execute([$assigned]); if (!$engineer->fetchColumn()) apiError(422,'invalid_engineer','المهندس غير متاح'); }
        $description=apiString($body,'description',5000);
        if ($id) {
            db()->prepare('UPDATE work_plans SET site_id=?,title=?,description=?,assigned_to=?,is_broadcast=?,priority=? WHERE id=?')->execute([$siteId,$title,$description,$assigned,$broadcast,$priority,$id]);
            audit('work_plan_updated','work_plan',$id); $planId=$id;
        } else {
            db()->prepare('INSERT INTO work_plans (site_id,title,description,assigned_to,is_broadcast,priority,created_by) VALUES (?,?,?,?,?,?,?)')->execute([$siteId,$title,$description,$assigned,$broadcast,$priority,$userId]);
            $planId=(int)db()->lastInsertId(); audit('work_plan_created','work_plan',$planId);
        }
        if ($broadcast) db()->prepare("INSERT INTO notifications (user_id,title,message,type,link) SELECT id,'خطة عمل جديدة',?,'info','engineer/tasks.php' FROM users WHERE role='engineer' AND is_active=1 AND approval_status='approved'")->execute([$title]);
        elseif ($assigned) db()->prepare('INSERT INTO notifications (user_id,title,message,type,link) VALUES (?,?,?,?,?)')->execute([$assigned,'خطة عمل جديدة',$title,'info','engineer/tasks.php']);
        apiSuccess(['task_id'=>$planId,'created'=>!$id],$id ? 200 : 201);
    }

    if ($apiRoute === 'work-plan-cancel') {
        apiRequireMethod('POST');
        if (!$isAdmin) apiError(403,'role_not_allowed','إدارة خطط العمل متاحة للمدير فقط');
        $body=apiBody(); $id=filter_var($body['task_id'] ?? null,FILTER_VALIDATE_INT); if (!$id) apiError(422,'validation_error','task_id مطلوب');
        $update=db()->prepare("UPDATE work_plans SET status='cancelled' WHERE id=? AND status<>'cancelled'"); $update->execute([$id]);
        if (!$update->rowCount()) apiError(404,'task_not_found','المهمة غير موجودة أو ملغاة مسبقاً');
        audit('work_plan_cancelled','work_plan',(int)$id); apiSuccess(['task_id'=>(int)$id,'status'=>'cancelled']);
    }

    if ($apiRoute === 'task-update') {
        apiRequireMethod('POST');
        if (!$isEngineer) apiError(403, 'role_not_allowed', 'هذا المسار مخصص للمهندس');
        $body = apiBody();
        $planId = filter_var($body['task_id'] ?? null, FILTER_VALIDATE_INT);
        $progress = filter_var($body['progress'] ?? null, FILTER_VALIDATE_INT);
        $status = apiString($body, 'status', 20);
        $note = apiString($body, 'note', 3000);
        if (!$planId || $progress === false || $progress < 0 || $progress > 100 || !in_array($status, ['pending','in_progress','review','done'], true)) {
            apiError(422, 'validation_error', 'تحقق من رقم المهمة والتقدم والحالة');
        }
        $pdo = db();
        $pdo->beginTransaction();
        try {
            $select = $pdo->prepare('SELECT id,title,progress,status FROM work_plans WHERE id=? AND (assigned_to=? OR is_broadcast=1) FOR UPDATE');
            $select->execute([$planId, $userId]);
            $task = $select->fetch();
            if (!$task) {
                $pdo->rollBack();
                apiError(404, 'task_not_found', 'المهمة غير موجودة أو غير مسندة إليك');
            }
            if ($status === 'done') $progress = 100;
            $pdo->prepare('UPDATE work_plans SET progress=?,status=? WHERE id=?')->execute([$progress,$status,$planId]);
            $pdo->prepare('INSERT INTO work_plan_updates (work_plan_id,engineer_id,old_progress,new_progress,old_status,new_status,note) VALUES (?,?,?,?,?,?,?)')->execute([$planId,$userId,(int)$task['progress'],$progress,$task['status'],$status,$note]);
            $pdo->commit();
        } catch (Throwable $exception) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            throw $exception;
        }
        $notify = db()->prepare("INSERT INTO notifications (user_id,title,message,type,link) SELECT id,?,?,?,? FROM users WHERE role='admin' AND is_active=1 AND approval_status='approved'");
        $notify->execute(['تحديث على خطة عمل', $user['full_name'] . ' حدّث المهمة: ' . $task['title'], 'info', 'admin/work_updates.php?plan=' . $planId]);
        apiSuccess(['task_id' => (int) $planId, 'progress' => (int) $progress, 'status' => $status]);
    }

    if ($apiRoute === 'reports') {
        if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'GET') {
            if (!$isAdmin && !$isEngineer) apiError(403,'role_not_allowed','التقارير متاحة للمدير والمهندس فقط');
            $sql = 'SELECT r.id,r.site_id,s.name AS site_name,r.engineer_id,u.full_name AS engineer_name,r.report_date,r.weather,r.temperature,r.workers_count,r.machinery_count,r.work_done,r.issues,r.materials_used,r.safety_notes,r.progress_percent,r.status,r.admin_notes,r.approved_by,r.approved_at,r.created_at FROM site_daily_reports r JOIN sites s ON s.id=r.site_id JOIN users u ON u.id=r.engineer_id';
            $conditions = [];
            $parameters = [];
            if (!$isAdmin) {
                $conditions[] = 'r.engineer_id=?';
                $parameters[] = $userId;
            }
            $reportId = filter_input(INPUT_GET, 'id', FILTER_VALIDATE_INT);
            if ($reportId) { $conditions[] = 'r.id=?'; $parameters[] = $reportId; }
            $siteId = filter_input(INPUT_GET, 'site_id', FILTER_VALIDATE_INT);
            if ($siteId) { $conditions[] = 'r.site_id=?'; $parameters[] = $siteId; }
            $status = Security::clean($_GET['status'] ?? '', 20);
            if ($status !== '') {
                if (!in_array($status, ['draft','submitted','approved','rejected'], true)) apiError(422,'validation_error','حالة التقرير غير صالحة');
                $conditions[] = 'r.status=?';
                $parameters[] = $status;
            }
            if ($conditions !== []) $sql .= ' WHERE ' . implode(' AND ', $conditions);
            $sql .= ' ORDER BY r.report_date DESC,r.created_at DESC LIMIT 100';
            $statement = db()->prepare($sql);
            $statement->execute($parameters);
            $reports = $statement->fetchAll();
            if ($reportId) {
                if (!$reports) apiError(404,'report_not_found','التقرير غير موجود');
                $expenseQuery = db()->prepare('SELECT id,item_name,category,quantity,unit_price,total,notes FROM report_expenses WHERE report_id=? ORDER BY id');
                $expenseQuery->execute([(int)$reportId]);
                $receiptQuery = db()->prepare('SELECT id,file_path,original_name,file_type,file_size,uploaded_at FROM report_receipts WHERE report_id=? ORDER BY id');
                $receiptQuery->execute([(int)$reportId]);
                $reports[0]['expenses'] = $expenseQuery->fetchAll();
                $reports[0]['receipts'] = $receiptQuery->fetchAll();
                apiSuccess($reports[0]);
            }
            apiSuccess($reports);
        }
        apiRequireMethod('POST');
        if (!$isEngineer) apiError(403, 'role_not_allowed', 'إنشاء التقارير متاح للمهندس فقط');
        $body = apiBody();
        $siteId = filter_var($body['site_id'] ?? null, FILTER_VALIDATE_INT);
        $reportDate = apiString($body, 'report_date', 10);
        $date = DateTime::createFromFormat('!Y-m-d', $reportDate);
        if (!$siteId || !$date || $date->format('Y-m-d') !== $reportDate) {
            apiError(422, 'validation_error', 'الموقع وتاريخ التقرير بصيغة YYYY-MM-DD مطلوبان');
        }
        $siteCheck = db()->prepare("SELECT id FROM sites WHERE id=? AND status IN ('planning','active','paused') AND (manager_id IS NULL OR manager_id=?)");
        $siteCheck->execute([$siteId,$userId]);
        if (!$siteCheck->fetchColumn()) apiError(403, 'site_not_allowed', 'لا تملك صلاحية إعداد تقرير لهذا الموقع');

        $pdo = db();
        $pdo->beginTransaction();
        try {
            $existing = $pdo->prepare('SELECT id,status FROM site_daily_reports WHERE site_id=? AND report_date=? AND engineer_id=? FOR UPDATE');
            $existing->execute([$siteId,$reportDate,$userId]);
            $previous = $existing->fetch();
            if ($previous && $previous['status'] === 'approved') {
                $pdo->rollBack();
                apiError(409, 'report_already_approved', 'تم اعتماد تقرير هذا اليوم ولا يمكن تعديله');
            }
            $insert = $pdo->prepare("INSERT INTO site_daily_reports (site_id,report_date,engineer_id,weather,temperature,workers_count,machinery_count,work_done,issues,materials_used,safety_notes,progress_percent,status) VALUES (?,?,?,?,?,?,?,?,?,?,?,?, 'submitted') ON DUPLICATE KEY UPDATE id=LAST_INSERT_ID(id),weather=VALUES(weather),temperature=VALUES(temperature),workers_count=VALUES(workers_count),machinery_count=VALUES(machinery_count),work_done=VALUES(work_done),issues=VALUES(issues),materials_used=VALUES(materials_used),safety_notes=VALUES(safety_notes),progress_percent=VALUES(progress_percent),status='submitted',admin_notes=NULL,approved_by=NULL,approved_at=NULL");
            $temperature = isset($body['temperature']) && is_numeric($body['temperature']) ? (float) $body['temperature'] : null;
            $insert->execute([
                (int) $siteId,
                $reportDate,
                $userId,
                apiString($body,'weather',80),
                $temperature,
                max(0, (int) ($body['workers_count'] ?? 0)),
                max(0, (int) ($body['machinery_count'] ?? 0)),
                apiString($body,'work_done'),
                apiString($body,'issues'),
                apiString($body,'materials_used'),
                apiString($body,'safety_notes'),
                max(0,min(100,(int)($body['progress_percent'] ?? 0))),
            ]);
            $reportId = (int) $pdo->lastInsertId();
            $expenses = $body['expenses'] ?? [];
            if (!is_array($expenses)) throw new InvalidArgumentException('المصروفات يجب أن تكون قائمة');
            $pdo->prepare('DELETE FROM report_expenses WHERE report_id=?')->execute([$reportId]);
            $expenseInsert = $pdo->prepare('INSERT INTO report_expenses (report_id,item_name,category,quantity,unit_price,total,notes) VALUES (?,?,?,?,?,?,?)');
            foreach ($expenses as $expense) {
                if (!is_array($expense)) continue;
                $name = apiString($expense,'item_name',200);
                if ($name === '') continue;
                $category = apiString($expense,'category',20);
                if (!in_array($category,['materials','labor','fuel','equipment','transport','other'],true)) $category='other';
                $quantity = max(0,(float)($expense['quantity'] ?? 0));
                $price = max(0,(float)($expense['unit_price'] ?? 0));
                $expenseInsert->execute([$reportId,$name,$category,$quantity,$price,$quantity*$price,apiString($expense,'notes',500)]);
            }
            $pdo->commit();
        } catch (Throwable $exception) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            if ($exception instanceof InvalidArgumentException) apiError(422,'validation_error',$exception->getMessage());
            throw $exception;
        }
        $notify = db()->prepare("INSERT INTO notifications (user_id,title,message,type,link) SELECT id,?,?,?,? FROM users WHERE role='admin' AND is_active=1 AND approval_status='approved'");
        $notify->execute(['تقرير يومي جديد','تم إرسال تقرير من ' . $user['full_name'],'info','admin/reports.php?status=submitted']);
        apiSuccess(['report_id'=>$reportId,'status'=>'submitted'], $previous ? 200 : 201);
    }

    if ($apiRoute === 'report-review') {
        apiRequireMethod('POST');
        if (!$isAdmin) apiError(403,'role_not_allowed','مراجعة التقارير متاحة للمدير فقط');
        require_once __DIR__ . '/helpers.php';
        $body = apiBody();
        $reportId = filter_var($body['report_id'] ?? null, FILTER_VALIDATE_INT);
        $decision = apiString($body,'decision',10);
        $notes = apiString($body,'admin_notes',5000);
        if (!$reportId || !in_array($decision,['approved','rejected'],true)) apiError(422,'validation_error','report_id وdecision بقيمة approved أو rejected مطلوبان');
        $pdo = db();
        $pdo->beginTransaction();
        try {
            $select = $pdo->prepare("SELECT r.engineer_id,r.site_id,r.status,s.name AS site_name FROM site_daily_reports r JOIN sites s ON s.id=r.site_id WHERE r.id=? FOR UPDATE");
            $select->execute([$reportId]);
            $report = $select->fetch();
            if (!$report) {
                $pdo->rollBack();
                apiError(404,'report_not_found','التقرير غير موجود');
            }
            if ($report['status'] !== 'submitted') {
                $pdo->rollBack();
                apiError(409,'report_already_reviewed','تمت مراجعة التقرير مسبقاً');
            }
            $pdo->prepare('UPDATE site_daily_reports SET status=?,admin_notes=?,approved_by=?,approved_at=NOW() WHERE id=? AND status="submitted"')->execute([$decision,$notes,$userId,$reportId]);
            if ($decision === 'approved') {
                $expenseQuery = $pdo->prepare('SELECT category,SUM(total) AS total FROM report_expenses WHERE report_id=? GROUP BY category');
                $expenseQuery->execute([$reportId]);
                $accountCodes = ['materials'=>'5100','labor'=>'5200','fuel'=>'5300','equipment'=>'5400','transport'=>'5500','other'=>'5600'];
                $accountQuery = $pdo->prepare('SELECT id FROM accounts WHERE code=?');
                $lines = [];
                $sum = 0.0;
                foreach ($expenseQuery->fetchAll() as $expense) {
                    $amount = round((float)$expense['total'],2);
                    if ($amount <= 0) continue;
                    $accountQuery->execute([$accountCodes[$expense['category']] ?? '5600']);
                    $accountId = (int)$accountQuery->fetchColumn();
                    if (!$accountId) throw new DomainException('حساب المصروفات غير موجود');
                    $lines[] = ['account_id'=>$accountId,'debit'=>$amount,'credit'=>0,'description'=>'مصروفات تقرير الموقع'];
                    $sum += $amount;
                }
                if ($sum > 0) {
                    $accountQuery->execute(['1100']);
                    $cashId = (int)$accountQuery->fetchColumn();
                    if (!$cashId) throw new DomainException('حساب النقدية غير موجود');
                    $lines[] = ['account_id'=>$cashId,'debit'=>0,'credit'=>$sum,'description'=>'صرف مصروفات التقرير'];
                    createJournalEntry('مصروفات التقرير اليومي · ' . $report['site_name'],$lines,$userId,(int)$report['site_id'],(int)$reportId,'report-' . $reportId);
                }
            }
            $pdo->commit();
        } catch (DomainException $exception) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            apiError(409,'account_setup_required',$exception->getMessage());
        } catch (Throwable $exception) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            throw $exception;
        }
        try {
            $notify = $pdo->prepare('INSERT INTO notifications (user_id,title,message,type,link) VALUES (?,?,?,?,?)');
            $notify->execute([(int)$report['engineer_id'],$decision === 'approved' ? 'تم اعتماد التقرير' : 'تم رفض التقرير',$report['site_name'] . ($notes !== '' ? ' · ' . $notes : ''),$decision === 'approved' ? 'success' : 'danger','engineer/dashboard.php']);
        } catch (Throwable $exception) {
            error_log('Maxlond API report notification error: ' . $exception->getMessage());
        }
        apiSuccess(['report_id'=>(int)$reportId,'status'=>$decision,'admin_notes'=>$notes]);
    }

    if ($apiRoute === 'report-receipt') {
        apiRequireMethod('POST');
        if (!$isAdmin && !$isEngineer) apiError(403,'role_not_allowed','رفع مرفقات التقارير متاح للمدير والمهندس فقط');
        $reportId = filter_var($_POST['report_id'] ?? null, FILTER_VALIDATE_INT);
        if (!$reportId || !isset($_FILES['receipt'])) apiError(422,'validation_error','report_id والملف receipt مطلوبان');
        $reportQuery = db()->prepare('SELECT id,engineer_id,status FROM site_daily_reports WHERE id=?');
        $reportQuery->execute([$reportId]);
        $report = $reportQuery->fetch();
        if (!$report || (!$isAdmin && (int)$report['engineer_id'] !== $userId)) apiError(404,'report_not_found','التقرير غير موجود');
        if ($report['status'] === 'approved') apiError(409,'report_locked','لا يمكن تعديل تقرير معتمد');
        if (!defined('UPLOAD_PATH')) define('UPLOAD_PATH', __DIR__ . '/uploads/');
        if (!defined('MAX_FILE_SIZE')) define('MAX_FILE_SIZE', 5242880);
        try {
            $file = Security::uploadReceipt($_FILES['receipt']);
        } catch (Throwable $exception) {
            apiError(422,'invalid_file',$exception->getMessage());
        }
        if (!$file) apiError(422,'invalid_file','لم يتم استلام ملف');
        db()->prepare('INSERT INTO report_receipts (report_id,file_path,original_name,file_type,file_size) VALUES (?,?,?,?,?)')->execute([$reportId,$file['path'],$file['name'],$file['mime'],$file['size']]);
        apiSuccess(['report_id'=>(int)$reportId,'file_path'=>$file['path'],'original_name'=>$file['name']],201);
    }

    if ($apiRoute === 'notifications') {
        apiRequireMethod('GET');
        $statement = db()->prepare('SELECT id,title,message,type,link,is_read,created_at FROM notifications WHERE user_id=? ORDER BY created_at DESC LIMIT 100');
        $statement->execute([$userId]);
        apiSuccess($statement->fetchAll());
    }

    if ($apiRoute === 'notification-read') {
        apiRequireMethod('POST');
        $body = apiBody();
        $notificationId = filter_var($body['notification_id'] ?? null, FILTER_VALIDATE_INT);
        if (!$notificationId) apiError(422,'validation_error','notification_id مطلوب');
        db()->prepare('UPDATE notifications SET is_read=1 WHERE id=? AND user_id=?')->execute([$notificationId,$userId]);
        apiSuccess(['notification_id'=>(int)$notificationId,'is_read'=>true]);
    }

    if ($apiRoute === 'notification-read-all') {
        apiRequireMethod('POST');
        $statement = db()->prepare('UPDATE notifications SET is_read=1 WHERE user_id=? AND is_read=0');
        $statement->execute([$userId]);
        apiSuccess(['updated_count'=>$statement->rowCount()]);
    }

    apiError(404, 'route_not_found', 'مسار API غير موجود');
} catch (Throwable $exception) {
    error_log('Maxlond API error: ' . $exception->getMessage());
    apiError(500, 'server_error', 'حدث خطأ داخلي في الخادم');
}