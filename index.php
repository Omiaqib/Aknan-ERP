<?php
// ============================================================
// AKNAN ERP — PHP REST API  (api/index.php)
// All API routes handled here via .htaccess routing
// ============================================================

require_once __DIR__ . '/../config.php';

// ── Headers ─────────────────────────────────────────────────
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: ' . APP_URL);
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

session_start();

// ── Helpers ──────────────────────────────────────────────────
$METHOD = $_SERVER['REQUEST_METHOD'];
$PATH   = trim($_GET['path'] ?? '', '/');
$PARTS  = $PATH !== '' ? explode('/', $PATH) : [];

function res(array $data, int $status = 200): void {
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}
function body(): array {
    return json_decode(file_get_contents('php://input'), true) ?? [];
}
function auth(): void {
    if (empty($_SESSION['user_id'])) res(['error' => 'Authentication required', 'code' => 'AUTH_REQUIRED'], 401);
}
function admin(): void {
    auth();
    if (($_SESSION['role_id'] ?? '') !== 'super_admin') res(['error' => 'Admin access required'], 403);
}
function perm(string $module, string $action = 'view'): void {
    auth();
    if (($_SESSION['role_id'] ?? '') === 'super_admin') return;
    $col = 'can_' . $action;
    $db  = get_db();
    $st  = $db->prepare("SELECT $col FROM module_permissions WHERE role_id=? AND module_id=?");
    $st->execute([$_SESSION['role_id'], $module]);
    $row = $st->fetch();
    if (!$row || !$row[$col]) res(['error' => "Permission denied: $action on $module"], 403);
}
function uid(): ?int { return $_SESSION['user_id'] ?? null; }
function gen_ref(string $prefix): string {
    return $prefix . '-' . date('Ymd') . '-' . strtoupper(bin2hex(random_bytes(2)));
}
function audit(string $action, string $module = null, int $rid = null): void {
    if (!uid()) return;
    try {
        $db = get_db();
        $db->prepare("INSERT INTO audit_log(user_id,action,module,record_id,ip_address) VALUES(?,?,?,?,?)")
           ->execute([uid(), $action, $module, $rid, $_SERVER['REMOTE_ADDR'] ?? null]);
    } catch (Exception $e) { /* non-fatal */ }
}
function fmt_last_login(?string $dt): string {
    if (!$dt) return 'Never';
    $ts   = strtotime($dt);
    $diff = time() - $ts;
    if ($diff < 120)   return 'Just now';
    if ($diff < 3600)  return intdiv($diff, 60) . ' minutes ago';
    if ($diff < 86400) return 'Today, ' . date('h:i A', $ts);
    if ($diff < 172800)return 'Yesterday, ' . date('h:i A', $ts);
    return intdiv($diff, 86400) . ' days ago';
}
function initials(string $name): string {
    $parts = array_filter(explode(' ', $name));
    return strtoupper(substr($parts[0] ?? '', 0, 1) . substr($parts[1] ?? '', 0, 1));
}

// ── Router ───────────────────────────────────────────────────
$r0 = $PARTS[0] ?? '';
$r1 = $PARTS[1] ?? '';
$r2 = $PARTS[2] ?? null;
$ID  = is_numeric($r1) ? (int)$r1 : (is_numeric($r2) ? (int)$r2 : null);

switch ($r0) {
    case 'auth':         handle_auth($r1);         break;
    case 'users':        handle_users($ID);        break;
    case 'roles':        handle_roles();            break;
    case 'permissions':  handle_permissions($r1);  break;
    case 'dashboard':    handle_dashboard();        break;
    case 'customers':    handle_customers($ID);     break;
    case 'vendors':      handle_vendors($ID);       break;
    case 'employees':    handle_employees($ID);     break;
    case 'distributors': handle_distributors($ID);  break;
    case 'bank-accounts':handle_banks($ID);         break;
    case 'sub-skus':     handle_sub_skus();         break;
    case 'parent-skus':  handle_parent_skus();      break;
    case 'raw-materials':handle_raw_materials();    break;
    case 'purchase':     handle_purchase($r1, $ID); break;
    case 'sales':        handle_sales($r1, $ID);    break;
    case 'expenses':     handle_expenses($ID);      break;
    case 'expense-categories': handle_expense_categories(); break;
    case 'delivery':     handle_delivery($r1, $ID); break;
    case 'production':   handle_production($r1);    break;
    case 'hr':           handle_hr($r1);            break;
    case 'accounts':     handle_accounts($r1);      break;
    case 'audit':        handle_audit();            break;
    default:             res(['error' => 'Endpoint not found'], 404);
}

// ── AUTH ─────────────────────────────────────────────────────
function handle_auth(string $sub): void {
    global $METHOD;
    $db = get_db();

    if ($sub === 'login' && $METHOD === 'POST') {
        $d = body();
        $email = strtolower(trim($d['email'] ?? ''));
        $pass  = $d['password'] ?? '';
        if (!$email || !$pass) res(['error' => 'Email and password required'], 400);

        $st = $db->prepare("SELECT u.*, r.name as role_name, r.tag, r.color, r.bg_color
                             FROM users u JOIN roles r ON u.role_id=r.id
                             WHERE LOWER(u.email)=? AND u.status='Active'");
        $st->execute([$email]);
        $u = $st->fetch();
        if (!$u || !password_verify($pass, $u['password_hash'])) {
            res(['error' => 'Invalid email or password'], 401);
        }
        session_regenerate_id(true);
        $_SESSION['user_id'] = $u['id'];
        $_SESSION['name']    = $u['name'];
        $_SESSION['email']   = $u['email'];
        $_SESSION['role_id'] = $u['role_id'];

        $db->prepare("UPDATE users SET last_login=NOW() WHERE id=?")->execute([$u['id']]);
        audit('LOGIN');
        res(['success' => true, 'user' => [
            'id'        => $u['id'],
            'name'      => $u['name'],
            'email'     => $u['email'],
            'role_id'   => $u['role_id'],
            'role_name' => $u['role_name'],
            'tag'       => $u['tag'],
            'color'     => $u['color'],
            'bg'        => $u['bg_color'],
            'initials'  => initials($u['name']),
        ]]);
    }

    if ($sub === 'logout' && $METHOD === 'POST') {
        audit('LOGOUT');
        session_destroy();
        res(['success' => true]);
    }

    if ($sub === 'me' && $METHOD === 'GET') {
        auth();
        $st = $db->prepare("SELECT u.id,u.name,u.email,u.role_id,u.phone,
                             r.name as role_name,r.tag,r.color,r.bg_color
                             FROM users u JOIN roles r ON u.role_id=r.id WHERE u.id=?");
        $st->execute([uid()]);
        $u = $st->fetch();
        if (!$u) { session_destroy(); res(['error' => 'Session expired'], 401); }
        $u['initials'] = initials($u['name']);
        res(['user' => $u]);
    }

    if ($sub === 'change-password' && $METHOD === 'POST') {
        auth();
        $d  = body();
        $st = $db->prepare("SELECT password_hash FROM users WHERE id=?");
        $st->execute([uid()]);
        $row = $st->fetch();
        if (!password_verify($d['current_password'] ?? '', $row['password_hash']))
            res(['error' => 'Current password is incorrect'], 400);
        if (strlen($d['new_password'] ?? '') < 6)
            res(['error' => 'New password must be at least 6 characters'], 400);
        $db->prepare("UPDATE users SET password_hash=? WHERE id=?")
           ->execute([password_hash($d['new_password'], PASSWORD_DEFAULT), uid()]);
        audit('CHANGE_PASSWORD');
        res(['success' => true]);
    }

    res(['error' => 'Not found'], 404);
}

// ── USERS ────────────────────────────────────────────────────
function handle_users(?int $id): void {
    global $METHOD;
    admin();
    $db = get_db();

    if ($METHOD === 'GET' && !$id) {
        $rows = $db->query("SELECT u.id,u.name,u.email,u.phone,u.role_id,u.status,u.last_login,
                            r.name as role_name,r.color,r.bg_color,r.tag
                            FROM users u JOIN roles r ON u.role_id=r.id ORDER BY u.id")->fetchAll();
        foreach ($rows as &$u) {
            $u['initials']       = initials($u['name']);
            $u['last_login_fmt'] = fmt_last_login($u['last_login']);
        }
        res(['users' => $rows]);
    }

    if ($METHOD === 'POST') {
        $d = body();
        foreach (['name','email','role_id'] as $f)
            if (empty($d[$f])) res(['error' => "$f is required"], 400);
        $tmp  = $d['password'] ?? bin2hex(random_bytes(6));
        $hash = password_hash($tmp, PASSWORD_DEFAULT);
        try {
            $db->prepare("INSERT INTO users(name,email,password_hash,phone,role_id,status) VALUES(?,?,?,?,?,?)")
               ->execute([$d['name'], strtolower($d['email']), $hash, $d['phone'] ?? '', $d['role_id'], $d['status'] ?? 'Active']);
            $new_id = (int)$db->lastInsertId();
            audit('CREATE_USER', 'users', $new_id);
            res(['success' => true, 'user_id' => $new_id, 'temp_password' => $tmp], 201);
        } catch (PDOException $e) {
            res(['error' => 'Email address already exists'], 400);
        }
    }

    if ($id) {
        if ($METHOD === 'DELETE') {
            if ($id === 1) res(['error' => 'Cannot delete the system administrator'], 400);
            if ($id === uid()) res(['error' => 'Cannot delete your own account'], 400);
            $db->prepare("DELETE FROM users WHERE id=?")->execute([$id]);
            audit('DELETE_USER', 'users', $id);
            res(['success' => true]);
        }
        if ($METHOD === 'PUT') {
            $d = body();
            $sets = []; $vals = [];
            foreach (['name','phone','role_id','status'] as $f)
                if (isset($d[$f])) { $sets[] = "$f=?"; $vals[] = $d[$f]; }
            if (isset($d['email'])) { $sets[] = "email=?"; $vals[] = strtolower($d['email']); }
            if (!empty($d['password'])) { $sets[] = "password_hash=?"; $vals[] = password_hash($d['password'], PASSWORD_DEFAULT); }
            if (!$sets) res(['error' => 'Nothing to update'], 400);
            $vals[] = $id;
            $db->prepare("UPDATE users SET " . implode(',', $sets) . " WHERE id=?")->execute($vals);
            audit('UPDATE_USER', 'users', $id);
            res(['success' => true]);
        }
    }
    res(['error' => 'Not found'], 404);
}

// ── ROLES ─────────────────────────────────────────────────────
function handle_roles(): void {
    auth();
    $rows = get_db()->query("SELECT r.*, COUNT(mp.id) as module_access_count,
                             COUNT(u.id) as user_count
                             FROM roles r
                             LEFT JOIN module_permissions mp ON mp.role_id=r.id AND mp.can_view=1
                             LEFT JOIN users u ON u.role_id=r.id
                             GROUP BY r.id
                             ORDER BY FIELD(r.id,'super_admin') DESC, r.name")->fetchAll();
    res(['roles' => $rows]);
}

// ── PERMISSIONS ───────────────────────────────────────────────
function handle_permissions(string $role_id = ''): void {
    global $METHOD;
    auth();
    $db = get_db();

    if ($METHOD === 'GET') {
        $rows = $db->query("SELECT * FROM module_permissions")->fetchAll();
        $out  = [];
        foreach ($rows as $p) {
            $out[$p['role_id']][$p['module_id']] = [
                'view'   => (bool)$p['can_view'],
                'add'    => (bool)$p['can_add'],
                'edit'   => (bool)$p['can_edit'],
                'delete' => (bool)$p['can_delete'],
            ];
        }
        res(['permissions' => $out]);
    }

    if ($METHOD === 'PUT' && $role_id) {
        admin();
        if ($role_id === 'super_admin') res(['error' => 'Super Admin permissions are locked'], 400);
        $d  = body();
        $st = $db->prepare("INSERT INTO module_permissions(role_id,module_id,can_view,can_add,can_edit,can_delete)
                             VALUES(?,?,?,?,?,?)
                             ON DUPLICATE KEY UPDATE
                             can_view=VALUES(can_view),can_add=VALUES(can_add),
                             can_edit=VALUES(can_edit),can_delete=VALUES(can_delete)");
        foreach ($d as $mod => $p) {
            $st->execute([$role_id, $mod,
                          (int)($p['view'] ?? 0), (int)($p['add'] ?? 0),
                          (int)($p['edit'] ?? 0), (int)($p['delete'] ?? 0)]);
        }
        audit('UPDATE_PERMISSIONS', 'permissions');
        res(['success' => true]);
    }
    res(['error' => 'Not found'], 404);
}

// ── DASHBOARD ─────────────────────────────────────────────────
function handle_dashboard(): void {
    auth();
    $db = get_db();
    $stats = [];
    foreach (['users'=>'users','customers'=>'customers','vendors'=>'vendors',
              'employees'=>'employees','distributors'=>'distributors','sub_skus'=>'sub_skus'] as $k => $tbl) {
        $col = ($tbl === 'users') ? "status='Active'" : "status='Active'";
        $stats[$k] = (int)$db->query("SELECT COUNT(*) FROM `$tbl` WHERE $col")->fetchColumn();
    }
    $logs = $db->query("SELECT a.action,a.module,a.created_at,u.name as user_name
                        FROM audit_log a LEFT JOIN users u ON a.user_id=u.id
                        ORDER BY a.created_at DESC LIMIT 10")->fetchAll();
    res(['stats' => $stats, 'recent_activity' => $logs]);
}

// ── GENERIC CRUD FACTORY ──────────────────────────────────────
function simple_list(string $sql): void {
    res([array_key_last(['x' => null]) ?? 'data' => get_db()->query($sql)->fetchAll()]);
}

// ── CUSTOMERS ─────────────────────────────────────────────────
function handle_customers(?int $id): void {
    global $METHOD;
    perm('sales', $METHOD === 'GET' ? 'view' : ($METHOD === 'DELETE' ? 'delete' : ($METHOD === 'POST' ? 'add' : 'edit')));
    $db = get_db();

    if ($METHOD === 'GET' && !$id)
        res(['customers' => $db->query("SELECT * FROM customers ORDER BY id DESC")->fetchAll()]);

    if ($METHOD === 'POST') {
        $d = body();
        if (empty($d['name']) || empty($d['customer_code'])) res(['error' => 'Customer code and name required'], 400);
        try {
            $db->prepare("INSERT INTO customers(customer_code,name,contact_person,phone,email,address,city,country,
                          payment_type,credit_limit,credit_term_days,tax_number,notes,created_by) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
               ->execute([$d['customer_code'],$d['name'],$d['contact_person']??null,$d['phone']??null,
                          $d['email']??null,$d['address']??null,$d['city']??null,$d['country']??'Saudi Arabia',
                          $d['payment_type']??'Credit',$d['credit_limit']??0,$d['credit_term_days']??30,
                          $d['tax_number']??null,$d['notes']??null, uid()]);
            $new_id = (int)$db->lastInsertId();
            audit('CREATE','customers',$new_id);
            res(['success'=>true,'id'=>$new_id],201);
        } catch (PDOException $e) { res(['error'=>'Customer code already exists'],400); }
    }

    if ($id) {
        if ($METHOD === 'GET') res(['customer' => $db->prepare("SELECT * FROM customers WHERE id=?")->execute([$id]) ? $db->query("SELECT * FROM customers WHERE id=$id")->fetch() : null]);
        if ($METHOD === 'DELETE') { $db->prepare("UPDATE customers SET status='Inactive' WHERE id=?")->execute([$id]); res(['success'=>true]); }
        if ($METHOD === 'PUT') {
            $d = body();
            $db->prepare("UPDATE customers SET name=?,contact_person=?,phone=?,email=?,address=?,city=?,
                          payment_type=?,credit_limit=?,credit_term_days=?,status=? WHERE id=?")
               ->execute([$d['name']??null,$d['contact_person']??null,$d['phone']??null,$d['email']??null,
                          $d['address']??null,$d['city']??null,$d['payment_type']??'Credit',
                          $d['credit_limit']??0,$d['credit_term_days']??30,$d['status']??'Active',$id]);
            res(['success'=>true]);
        }
    }
    res(['error'=>'Not found'],404);
}

// ── VENDORS ───────────────────────────────────────────────────
function handle_vendors(?int $id): void {
    global $METHOD;
    perm('purchase', $METHOD==='GET'?'view':($METHOD==='POST'?'add':'edit'));
    $db = get_db();
    if ($METHOD==='GET'&&!$id) res(['vendors'=>$db->query("SELECT * FROM vendors ORDER BY id DESC")->fetchAll()]);
    if ($METHOD==='POST') {
        $d=body();
        if(empty($d['name'])||empty($d['vendor_code'])) res(['error'=>'Vendor code and name required'],400);
        try {
            $db->prepare("INSERT INTO vendors(vendor_code,name,contact_person,phone,email,address,city,country,
                          payment_type,credit_limit,credit_term_days,bank_name,bank_account,iban,tax_number,notes,created_by)
                          VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
               ->execute([$d['vendor_code'],$d['name'],$d['contact_person']??null,$d['phone']??null,$d['email']??null,
                          $d['address']??null,$d['city']??null,$d['country']??'Saudi Arabia',
                          $d['payment_type']??'Credit',$d['credit_limit']??0,$d['credit_term_days']??45,
                          $d['bank_name']??null,$d['bank_account']??null,$d['iban']??null,
                          $d['tax_number']??null,$d['notes']??null,uid()]);
            res(['success'=>true,'id'=>(int)$db->lastInsertId()],201);
        } catch(PDOException $e){ res(['error'=>'Vendor code already exists'],400); }
    }
    if($id&&$METHOD==='PUT'){
        $d=body();
        $db->prepare("UPDATE vendors SET name=?,contact_person=?,phone=?,email=?,payment_type=?,
                      credit_limit=?,credit_term_days=?,status=? WHERE id=?")
           ->execute([$d['name']??null,$d['contact_person']??null,$d['phone']??null,$d['email']??null,
                      $d['payment_type']??'Credit',$d['credit_limit']??0,$d['credit_term_days']??45,$d['status']??'Active',$id]);
        res(['success'=>true]);
    }
    res(['error'=>'Not found'],404);
}

// ── EMPLOYEES ─────────────────────────────────────────────────
function handle_employees(?int $id): void {
    global $METHOD;
    perm('hr', $METHOD==='GET'?'view':($METHOD==='POST'?'add':'edit'));
    $db=get_db();
    if($METHOD==='GET'&&!$id)
        res(['employees'=>$db->query("SELECT * FROM employees WHERE status!='Terminated' ORDER BY id DESC")->fetchAll()]);
    if($METHOD==='POST'){
        $d=body();
        if(empty($d['name'])||empty($d['employee_code'])) res(['error'=>'Employee code and name required'],400);
        try{
            $db->prepare("INSERT INTO employees(employee_code,name,name_ar,national_id,nationality,date_of_birth,gender,
                          phone,personal_email,department,job_title,employment_type,join_date,contract_expiry,
                          basic_salary,housing_allowance,transport_allowance,other_allowance,bank_name,bank_account,
                          iban,emergency_contact,emergency_phone,notes,created_by)
                          VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
               ->execute([$d['employee_code'],$d['name'],$d['name_ar']??null,$d['national_id']??null,$d['nationality']??null,
                          $d['date_of_birth']??null,$d['gender']??null,$d['phone']??null,$d['personal_email']??null,
                          $d['department']??null,$d['job_title']??null,$d['employment_type']??'Full-Time',
                          $d['join_date']??null,$d['contract_expiry']??null,$d['basic_salary']??0,
                          $d['housing_allowance']??0,$d['transport_allowance']??0,$d['other_allowance']??0,
                          $d['bank_name']??null,$d['bank_account']??null,$d['iban']??null,
                          $d['emergency_contact']??null,$d['emergency_phone']??null,$d['notes']??null,uid()]);
            res(['success'=>true,'id'=>(int)$db->lastInsertId()],201);
        } catch(PDOException $e){ res(['error'=>'Employee code already exists'],400); }
    }
    res(['error'=>'Not found'],404);
}

// ── DISTRIBUTORS ──────────────────────────────────────────────
function handle_distributors(?int $id): void {
    global $METHOD;
    perm('distributor',$METHOD==='GET'?'view':($METHOD==='POST'?'add':'edit'));
    $db=get_db();
    if($METHOD==='GET'&&!$id)
        res(['distributors'=>$db->query("SELECT * FROM distributors ORDER BY id DESC")->fetchAll()]);
    if($METHOD==='POST'){
        $d=body();
        if(empty($d['name'])||empty($d['distributor_code'])) res(['error'=>'Distributor code and name required'],400);
        try{
            $db->prepare("INSERT INTO distributors(distributor_code,name,contact_person,phone,email,address,city,region,
                          payment_type,credit_limit,credit_term_days,delivery_type,assigned_area,bank_name,bank_account,
                          iban,tax_number,notes,created_by) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
               ->execute([$d['distributor_code'],$d['name'],$d['contact_person']??'',$d['phone']??'',
                          $d['email']??null,$d['address']??null,$d['city']??null,$d['region']??'',
                          $d['payment_type']??'Credit',$d['credit_limit']??0,$d['credit_term_days']??30,
                          $d['delivery_type']??'Both',$d['assigned_area']??null,$d['bank_name']??null,
                          $d['bank_account']??null,$d['iban']??null,$d['tax_number']??null,$d['notes']??null,uid()]);
            res(['success'=>true,'id'=>(int)$db->lastInsertId()],201);
        } catch(PDOException $e){ res(['error'=>'Distributor code already exists'],400); }
    }
    res(['error'=>'Not found'],404);
}

// ── BANK ACCOUNTS ─────────────────────────────────────────────
function handle_banks(?int $id): void {
    global $METHOD; auth(); $db=get_db();
    if($METHOD==='GET')
        res(['bank_accounts'=>$db->query("SELECT * FROM bank_accounts WHERE is_active=1 ORDER BY id")->fetchAll()]);
    if($METHOD==='POST'){
        $d=body();
        if(empty($d['bank_name'])) res(['error'=>'Bank name required'],400);
        $db->prepare("INSERT INTO bank_accounts(bank_name,account_number,iban,account_type,currency,opening_balance) VALUES(?,?,?,?,?,?)")
           ->execute([$d['bank_name'],$d['account_number']??null,$d['iban']??null,$d['account_type']??'Current',$d['currency']??'SAR',$d['opening_balance']??0]);
        res(['success'=>true,'id'=>(int)$db->lastInsertId()],201);
    }
    res(['error'=>'Not found'],404);
}

// ── PRODUCTS ──────────────────────────────────────────────────
function handle_parent_skus(): void { auth(); res(['parent_skus'=>get_db()->query("SELECT * FROM parent_skus ORDER BY id")->fetchAll()]); }
function handle_sub_skus(): void { auth(); res(['sub_skus'=>get_db()->query("SELECT s.*,p.name as parent_name FROM sub_skus s LEFT JOIN parent_skus p ON s.parent_sku_id=p.id ORDER BY s.id")->fetchAll()]); }
function handle_raw_materials(): void { auth(); res(['raw_materials'=>get_db()->query("SELECT * FROM raw_materials ORDER BY id")->fetchAll()]); }

// ── PURCHASE ORDERS ───────────────────────────────────────────
function handle_purchase(string $sub, ?int $id): void {
    global $METHOD;
    if($sub!=='orders') res(['error'=>'Not found'],404);
    perm('purchase',$METHOD==='GET'?'view':($METHOD==='POST'?'add':'edit'));
    $db=get_db();
    if($METHOD==='GET')
        res(['purchase_orders'=>$db->query("SELECT po.*,v.name as vendor_name FROM purchase_orders po LEFT JOIN vendors v ON po.vendor_id=v.id ORDER BY po.id DESC")->fetchAll()]);
    if($METHOD==='POST'){
        $d=body();
        if(empty($d['vendor_id'])||empty($d['order_date'])) res(['error'=>'Vendor and order date required'],400);
        $po_num=gen_ref('PO');
        $db->prepare("INSERT INTO purchase_orders(po_number,vendor_id,order_date,expected_delivery,payment_method,bank_account_id,subtotal,tax_rate,tax_amount,total_amount,notes,created_by) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)")
           ->execute([$po_num,$d['vendor_id'],$d['order_date'],$d['expected_delivery']??null,$d['payment_method']??null,$d['bank_account_id']??null,$d['subtotal']??0,$d['tax_rate']??15,$d['tax_amount']??0,$d['total_amount']??0,$d['notes']??null,uid()]);
        $pid=(int)$db->lastInsertId();
        foreach(($d['items']??[]) as $item){
            $db->prepare("INSERT INTO purchase_order_items(po_id,raw_material_id,quantity,unit_price,line_total) VALUES(?,?,?,?,?)")
               ->execute([$pid,$item['raw_material_id'],$item['quantity'],$item['unit_price'],$item['quantity']*$item['unit_price']]);
        }
        audit('CREATE','purchase',$pid);
        res(['success'=>true,'id'=>$pid,'po_number'=>$po_num],201);
    }
    res(['error'=>'Not found'],404);
}

// ── SALES ORDERS ──────────────────────────────────────────────
function handle_sales(string $sub, ?int $id): void {
    global $METHOD;
    if($sub!=='orders') res(['error'=>'Not found'],404);
    perm('sales',$METHOD==='GET'?'view':($METHOD==='POST'?'add':'edit'));
    $db=get_db();
    if($METHOD==='GET')
        res(['sales_orders'=>$db->query("SELECT so.*,c.name as customer_name,d.name as distributor_name FROM sales_orders so LEFT JOIN customers c ON so.customer_id=c.id LEFT JOIN distributors d ON so.distributor_id=d.id ORDER BY so.id DESC")->fetchAll()]);
    if($METHOD==='POST'){
        $d=body();
        if(empty($d['order_date'])) res(['error'=>'Order date required'],400);
        $so_num=gen_ref('SO');
        $db->prepare("INSERT INTO sales_orders(so_number,customer_id,distributor_id,order_date,delivery_date,order_type,payment_method,bank_account_id,subtotal,tax_rate,tax_amount,discount,total_amount,notes,created_by) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
           ->execute([$so_num,$d['customer_id']??null,$d['distributor_id']??null,$d['order_date'],$d['delivery_date']??null,$d['order_type']??'Sales Order',$d['payment_method']??null,$d['bank_account_id']??null,$d['subtotal']??0,$d['tax_rate']??15,$d['tax_amount']??0,$d['discount']??0,$d['total_amount']??0,$d['notes']??null,uid()]);
        $sid=(int)$db->lastInsertId();
        foreach(($d['items']??[]) as $item){
            $db->prepare("INSERT INTO sales_order_items(so_id,sub_sku_id,quantity,unit_price,discount_pct,line_total) VALUES(?,?,?,?,?,?)")
               ->execute([$sid,$item['sub_sku_id'],$item['quantity'],$item['unit_price'],$item['discount_pct']??0,$item['quantity']*$item['unit_price']]);
        }
        res(['success'=>true,'id'=>$sid,'so_number'=>$so_num],201);
    }
    res(['error'=>'Not found'],404);
}

// ── EXPENSES ──────────────────────────────────────────────────
function handle_expenses(?int $id): void {
    global $METHOD;
    perm('expense',$METHOD==='GET'?'view':($METHOD==='POST'?'add':'edit'));
    $db=get_db();
    if($METHOD==='GET'&&!$id)
        res(['expenses'=>$db->query("SELECT e.*,ec.name as category_name,ba.bank_name FROM expenses e LEFT JOIN expense_categories ec ON e.category_id=ec.id LEFT JOIN bank_accounts ba ON e.bank_account_id=ba.id ORDER BY e.id DESC")->fetchAll()]);
    if($METHOD==='POST'){
        $d=body();
        if(empty($d['description'])||empty($d['amount'])||empty($d['expense_date'])) res(['error'=>'Description, amount and date required'],400);
        $num=gen_ref('EXP');
        $db->prepare("INSERT INTO expenses(expense_number,category_id,expense_date,description,amount,payment_method,bank_account_id,department,notes,created_by) VALUES(?,?,?,?,?,?,?,?,?,?)")
           ->execute([$num,$d['category_id']??null,$d['expense_date'],$d['description'],$d['amount'],$d['payment_method']??'Cash',$d['bank_account_id']??null,$d['department']??null,$d['notes']??null,uid()]);
        res(['success'=>true,'id'=>(int)$db->lastInsertId(),'expense_number'=>$num],201);
    }
    res(['error'=>'Not found'],404);
}

// ── PRODUCTION ────────────────────────────────────────────────
function handle_production(string $sub): void {
    global $METHOD;
    if($sub!=='entries') res(['error'=>'Not found'],404);
    perm('production',$METHOD==='GET'?'view':($METHOD==='POST'?'add':'edit'));
    $db=get_db();
    if($METHOD==='GET')
        res(['entries'=>$db->query("SELECT pe.*,m.machine_name,m.machine_code,p.name as parent_sku_name FROM production_entries pe LEFT JOIN machines m ON pe.machine_id=m.id LEFT JOIN parent_skus p ON pe.parent_sku_id=p.id ORDER BY pe.production_date DESC")->fetchAll()]);
    if($METHOD==='POST'){
        $d=body();
        if(empty($d['machine_id'])||empty($d['production_date'])) res(['error'=>'Machine and production date required'],400);
        $check=$db->prepare("SELECT id FROM production_entries WHERE machine_id=? AND production_date=?");
        $check->execute([$d['machine_id'],$d['production_date']]);
        if($check->fetch()) res(['error'=>'Entry already exists for this machine on '.$d['production_date']],400);
        $num=gen_ref('PE');
        $db->prepare("INSERT INTO production_entries(entry_number,machine_id,parent_sku_id,production_date,shift,downtime_minutes,downtime_reason,submitted_by) VALUES(?,?,?,?,?,?,?,?)")
           ->execute([$num,$d['machine_id'],$d['parent_sku_id']??null,$d['production_date'],$d['shift']??null,$d['downtime_minutes']??0,$d['downtime_reason']??null,uid()]);
        $eid=(int)$db->lastInsertId();
        foreach(($d['items']??[]) as $item){
            $db->prepare("INSERT INTO production_entry_items(production_entry_id,sub_sku_id,quantity_produced,waste_quantity,rejection_reason) VALUES(?,?,?,?,?)")
               ->execute([$eid,$item['sub_sku_id'],$item['quantity_produced'],$item['waste_quantity']??0,$item['rejection_reason']??null]);
            $db->prepare("UPDATE sub_skus SET current_stock=current_stock+? WHERE id=?")
               ->execute([$item['quantity_produced'],$item['sub_sku_id']]);
        }
        res(['success'=>true,'id'=>$eid,'entry_number'=>$num],201);
    }
    res(['error'=>'Not found'],404);
}

// ── HR — ATTENDANCE IMPORT ────────────────────────────────────
function handle_hr(string $sub): void {
    global $METHOD;
    if($sub!=='attendance'||$METHOD!=='POST') res(['error'=>'Not found'],404);
    perm('hr','add');
    $d=$_GET['action']??'import';
    $data=body();
    $records=$data['records']??[];
    if(!$records) res(['error'=>'No records provided'],400);
    $db=get_db();
    $batch='IMP-'.date('YmdHis');
    $inserted=$skipped=0; $errors=[];
    foreach($records as $r){
        if(empty($r['employee_id'])||empty($r['attendance_date'])){ $errors[]="Missing fields"; continue; }
        $emp=$db->prepare("SELECT id FROM employees WHERE employee_code=?");
        $emp->execute([$r['employee_id']]);
        $e=$emp->fetch();
        if(!$e){ $errors[]="Employee not found: ".$r['employee_id']; $skipped++; continue; }
        try{
            $db->prepare("INSERT INTO attendance(employee_id,attendance_date,day_of_week,check_in,check_out,working_hours,status,late_minutes,early_leave_minutes,overtime_hours,import_batch,remarks) VALUES(?,?,?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE check_in=VALUES(check_in),check_out=VALUES(check_out),status=VALUES(status),import_batch=VALUES(import_batch)")
               ->execute([$e['id'],$r['attendance_date'],$r['day']??null,$r['check_in']??null,$r['check_out']??null,$r['working_hours']??null,$r['status']??'Present',$r['late_minutes']??0,$r['early_leave_minutes']??0,$r['overtime_hours']??0,$batch,$r['remarks']??null]);
            $inserted++;
        } catch(Exception $ex){ $errors[]=substr($ex->getMessage(),0,80); }
    }
    audit('ATTENDANCE_IMPORT','hr');
    res(['success'=>true,'batch'=>$batch,'inserted'=>$inserted,'skipped'=>$skipped,'errors'=>array_slice($errors,0,10)]);
}

// ── ACCOUNTS ─────────────────────────────────────────────────
function handle_accounts(string $sub): void {
    perm('accounts','view');
    if($sub==='coa') res(['accounts'=>get_db()->query("SELECT * FROM chart_of_accounts ORDER BY account_code")->fetchAll()]);
    res(['error'=>'Not found'],404);
}

// ── EXPENSE CATEGORIES ────────────────────────────────────────
function handle_expense_categories(): void {
    auth();
    res(['categories' => get_db()->query("SELECT * FROM expense_categories WHERE is_active=1 ORDER BY name")->fetchAll()]);
}

// ── DELIVERY ORDERS ───────────────────────────────────────────
function handle_delivery(string $sub, ?int $id): void {
    global $METHOD;
    if ($sub !== 'orders') res(['error' => 'Not found'], 404);
    perm('delivery', $METHOD === 'GET' ? 'view' : ($METHOD === 'POST' ? 'add' : 'edit'));
    $db = get_db();

    if ($METHOD === 'GET') {
        $rows = $db->query("SELECT d.*,
            dist.name as distributor_name,
            CONCAT(e.name) as driver_name,
            v.plate_number as vehicle_plate
            FROM delivery_orders d
            LEFT JOIN distributors dist ON d.distributor_id = dist.id
            LEFT JOIN employees e ON d.driver_id = e.id
            LEFT JOIN company_vehicles v ON d.vehicle_id = v.id
            ORDER BY d.id DESC")->fetchAll();
        res(['delivery_orders' => $rows]);
    }

    if ($METHOD === 'POST') {
        $d = body();
        if (empty($d['delivery_date'])) res(['error' => 'Delivery date required'], 400);
        $num = gen_ref('DEL');
        $trip = ($d['fuel_cost'] ?? 0) + ($d['driver_allowance'] ?? 0) + ($d['tolls'] ?? 0) + ($d['misc_cost'] ?? 0);
        $db->prepare("INSERT INTO delivery_orders
            (delivery_number,so_id,distributor_id,delivery_date,delivery_type,vehicle_id,driver_id,
             tpl_company,tpl_driver_name,tpl_vehicle_details,waybill_number,
             fuel_cost,driver_allowance,tolls,misc_cost,total_trip_cost,notes,created_by)
            VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
           ->execute([$num, $d['so_id'] ?? null, $d['distributor_id'] ?? null, $d['delivery_date'],
                      $d['delivery_type'] ?? 'Company Vehicle',
                      $d['vehicle_id'] ?? null, $d['driver_id'] ?? null,
                      $d['tpl_company'] ?? null, $d['tpl_driver_name'] ?? null, $d['tpl_vehicle_details'] ?? null,
                      $d['waybill_number'] ?? null,
                      $d['fuel_cost'] ?? 0, $d['driver_allowance'] ?? 0, $d['tolls'] ?? 0, $d['misc_cost'] ?? 0,
                      $trip, $d['notes'] ?? null, uid()]);
        $did = (int)$db->lastInsertId();
        audit('CREATE', 'delivery', $did);
        res(['success' => true, 'id' => $did, 'delivery_number' => $num], 201);
    }

    if ($id && $METHOD === 'PUT') {
        $d = body();
        $db->prepare("UPDATE delivery_orders SET status=?, notes=? WHERE id=?")
           ->execute([$d['status'] ?? 'Pending', $d['notes'] ?? null, $id]);
        res(['success' => true]);
    }
    res(['error' => 'Not found'], 404);
}

// ── AUDIT LOG ─────────────────────────────────────────────────
function handle_audit(): void {
    admin();
    $rows=get_db()->query("SELECT a.*,u.name as user_name FROM audit_log a LEFT JOIN users u ON a.user_id=u.id ORDER BY a.created_at DESC LIMIT 100")->fetchAll();
    res(['logs'=>$rows]);
}
