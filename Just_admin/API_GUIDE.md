# Maxlond API for Flutter

## Base URL

Use the deployed application URL followed by `api.php`:

```text
https://your-domain.example/api.php?route=
```

For example, if the deployed Maxlond application URL is `https://maxlond.example`, the login URL is:

```text
https://maxlond.example/api/auth.php?route=login
```

All API responses are UTF-8 JSON. Normal responses use:

```json
{"success":true,"data":{}}
```

Errors use:

```json
{"success":false,"error":{"code":"validation_error","message":"..."}}
```

Send `Accept: application/json` on every request. Send `Content-Type: application/json` for JSON POST requests. Authenticated requests must include:

```text
Authorization: Bearer <token>
```

The API is stateless; it does not use the website's PHP session cookie or CSRF form token. The database stores only a SHA-256 hash of the bearer token. Tokens expire after 30 days. There is no refresh endpoint; sign in again when a token expires. Store tokens in Flutter secure storage, not shared preferences.

## Routes

New Flutter clients should use the section-specific entry points below. `api.php?route=...` remains available for backward compatibility.

| API file | Role | Main routes |
| --- | --- | --- |
| `/api/auth.php` | All | `login`, `me`, `logout` |
| `/api/management.php` | `admin` | `dashboard`, `sites`, `site-save`, `site-cancel`, `tasks`, `work-plan-save`, `work-plan-cancel`, `reports`, `report-review`, `users`, `user-save`, `user-status`, `machinery`, `machinery-save`, `machinery-status` |
| `/api/engineer.php` | `engineer` | `dashboard`, `sites`, `tasks`, `task-update`, `reports`, `report-receipt`, `notifications`, `notification-read`, `notification-read-all` |
| `/api/accounting.php` | `accountant` or `admin` | `dashboard`, `accounts`, `account-save`, `account-delete`, `journal`, `journal-entry`, `journal-create`, `financial` |
| `/api/warehouse.php` | `admin` | `warehouse-items`, `warehouse-item-save`, `warehouse-item-status`, `warehouse-categories`, `warehouse-category-save`, `warehouse-moves`, `warehouse-move-create` |
| `/api/maintenance.php` | `admin` | `machinery`, `machinery-save`, `machinery-status`, `repairs`, `repair-create`, `repair-update`, `repair-status` |

Existing databases must apply `migrations/20261003_add_accountant_role.sql` once before creating accountant users. Warehouse and maintenance clients currently use the admin role; no separate operator role exists yet.

| Method | Route | Auth | Description |
| --- | --- | --- | --- |
| POST | `?route=login` | No | Sign in and issue a token |
| GET | `?route=me` | Bearer | Current user profile |
| POST | `?route=logout` | Bearer | Revoke the current token |
| GET | `?route=dashboard` | Bearer | Role-specific dashboard counts; admin also gets today's top engineers |
| GET | `?route=sites` | Bearer | Sites visible to the current role |
| GET | `?route=machinery` | Bearer | Machinery list |
| GET | `?route=tasks` | Bearer | Work plans; optional `&site_id=ID` and `&status=pending` |
| POST | `?route=task-update` | Engineer | Update an assigned or broadcast task |
| GET | `?route=reports` | Bearer | Recent reports; engineers only see their own; optional `status` and `site_id` filters |
| GET | `?route=reports&id=ID` | Bearer | One report with expenses and receipt metadata |
| POST | `?route=reports` | Engineer | Create or update the engineer's report for a site/date |
| POST | `?route=report-review` | Admin | Approve or reject a submitted report, with optional notes |
| POST | `?route=report-receipt` | Bearer | Upload one receipt image or PDF |
| GET | `?route=notifications` | Bearer | Current user's latest notifications |
| POST | `?route=notification-read` | Bearer | Mark one notification as read |
| POST | `?route=notification-read-all` | Bearer | Mark all current user's notifications as read |

Engineers can only see sites assigned to them or sites without a manager. Admin tokens can see all sites and reports. New engineer accounts must be approved before API sign-in.

The admin dashboard includes `today_top_engineers`, ordered by the average progress reported in today's daily reports and task updates. Each row contains `engineer_id`, `full_name`, `score`, `activity_count`, and `completed_tasks` (top seven only).

## Request Examples

### Sign in

```http
POST /api.php?route=login
Content-Type: application/json
Accept: application/json
```

```json
{
  "username": "engineer.username",
  "password": "user password",
  "device_info": "Maxlond Flutter / Android"
}
```

The response contains `data.token`, `data.token_type`, `data.expires_in` (seconds), and the public `data.user` profile. Never log or print the token.

### Update task progress

`task-update` accepts JSON. Status values: `pending`, `in_progress`, `review`, `done`.

```json
{
  "task_id": 12,
  "progress": 65,
  "status": "in_progress",
  "note": "اكتمل صب الجزء الأول"
}
```

### Submit a daily report

`reports` accepts one JSON object. `report_date` must be `YYYY-MM-DD`. A second submission for the same engineer/site/date updates that report and replaces its expense rows. An already approved report returns HTTP 409. Upload receipts separately after the report is created.

```json
{
  "site_id": 4,
  "report_date": "2026-09-30",
  "weather": "مشمس",
  "temperature": 31.5,
  "workers_count": 12,
  "machinery_count": 2,
  "work_done": "صب الأساس للقطاع الشرقي",
  "issues": "",
  "materials_used": "أسمنت وحديد",
  "safety_notes": "معدات الوقاية مستخدمة",
  "progress_percent": 35,
  "expenses": [
    {
      "item_name": "أسمنت",
      "category": "materials",
      "quantity": 8,
      "unit_price": 9500,
      "notes": ""
    }
  ]
}
```

Expense categories: `materials`, `labor`, `fuel`, `equipment`, `transport`, `other`.

### Review a report (admin)

Send JSON to `POST ?route=report-review` with an admin Bearer token:

```json
{
  "report_id": 28,
  "decision": "approved",
  "admin_notes": "تمت مراجعة الإيصالات"
}
```

`decision` must be `approved` or `rejected`. Approving creates the expense journal entry when the required accounts exist. A report already reviewed returns HTTP 409.

To load a report and its child data, use `GET ?route=reports&id=28`. The response includes `data.expenses` and `data.receipts`; receipt `file_path` values are relative to the application root.

### Upload a receipt

Send `multipart/form-data` to `?route=report-receipt` with fields `report_id` and `receipt` (a single JPEG, PNG, WebP, or PDF file, up to 5 MB). The API checks MIME type and stores the upload under a random filename.

### Mark a notification read

```json
{"notification_id": 28}
```

Use `POST ?route=notification-read-all` with an authenticated request and no body to mark all current user's notifications as read. The response contains `data.updated_count`.

## Flutter HTTP Sketch

Use the Flutter team's chosen HTTP client and secure-storage package. Example with the `http` package:

```dart
final response = await http.get(
  Uri.parse('$baseUrl/api.php?route=tasks'),
  headers: {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  },
);
final body = jsonDecode(response.body) as Map<String, dynamic>;
if (response.statusCode < 200 || response.statusCode >= 300) {
  throw Exception(body['error']?['message'] ?? 'Request failed');
}
final tasks = body['data'] as List<dynamic>;
```

## HTTP Statuses

`200` success, `201` created, `204` CORS preflight, `400` malformed request, `401` missing/invalid token or credentials, `403` account/role restriction, `404` missing route/resource, `405` unsupported HTTP method, `409` report already reviewed/approved or missing accounting setup, `422` validation error, `429` login throttled, and `500` unexpected server error.

## Database

Fresh installs using `database.sql` include `api_tokens` and `api_logs`. Existing installs from `spacepoint.sql` already define both tables. Do not import the full `database.sql` over a populated database because it contains `DROP TABLE` statements. Apply `migrations/20261003_add_accountant_role.sql` once before creating accountant accounts.