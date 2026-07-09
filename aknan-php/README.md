# Aknan ERP — PHP + MySQL Deployment Guide
# Subdomain: app.aknans.sa

## Overview
- Language:  PHP (runs natively on any cPanel server)
- Database:  MySQL (managed via cPanel + phpMyAdmin)
- Frontend:  React (single HTML file, no build step)
- Upload:    FileZilla or cPanel File Manager

---

## STEP 1 — Create the MySQL Database in cPanel

1. Log into cPanel
2. Go to **MySQL Databases** (under Databases section)
3. Under **Create New Database**, type a name — e.g. `aknan_erp` → click **Create Database**
4. Under **MySQL Users → Add New User**, create a user:
   - Username: `aknan_admin`
   - Password: a strong password (click **Generate** or type your own) — note it down
5. Under **Add User to Database**, select your user and your database → click **Add**
6. On the permissions screen, tick **All Privileges** → **Make Changes**

You now have:
- Database name: `youraccount_aknan_erp` (cPanel adds your account prefix)
- Username: `youraccount_aknan_admin`
- Password: what you set
- Host: `localhost`

---

## STEP 2 — Import the Database Schema

1. In cPanel, go to **phpMyAdmin**
2. On the left panel, click your database (`youraccount_aknan_erp`)
3. Click the **Import** tab at the top
4. Click **Choose File** → select `database.sql` from this package
5. Leave all settings as default → click **Go** at the bottom
6. You should see a green success message — all tables and default data are created

---

## STEP 3 — Upload Files via FileZilla

### Connect FileZilla to your server
- Host: `ftp.aknans.sa` (or your server IP)
- Username: your cPanel FTP username
- Password: your cPanel password
- Port: `21`

### Navigate on the server
In FileZilla right panel:
- Go to `public_html` → open `app.aknans.sa` folder

### Upload all files
Select everything in this package folder and upload:

```
app.aknans.sa/         ← upload these files here directly
├── index.html
├── .htaccess
├── config.php
├── database.sql
├── README.md
├── api/
│   └── index.php
├── static/
└── uploads/
```

> In FileZilla → Server menu → tick **Force showing hidden files** to see .htaccess

---

## STEP 4 — Edit config.php with Your Database Details

After uploading, open `config.php` in File Manager:

1. cPanel → File Manager → navigate to `app.aknans.sa`
2. Right-click `config.php` → **Edit**
3. Fill in your MySQL details:

```php
define('DB_HOST',   'localhost');
define('DB_NAME',   'youraccount_aknan_erp');    // your actual db name
define('DB_USER',   'youraccount_aknan_admin');  // your actual db user
define('DB_PASS',   'your-db-password');          // your actual password
define('APP_URL',   'https://app.aknans.sa');
define('SECRET_KEY','put-a-long-random-string-here-minimum-32-chars');
```

4. Save and close

---

## STEP 5 — Test

Open your browser → **https://app.aknans.sa**

You should see the Aknan ERP login screen.

**Default login:**
| Field    | Value            |
|----------|------------------|
| Email    | admin@aknan.com  |
| Password | admin123         |

**Change the admin password immediately after first login.**

---

## STEP 6 — Enable SSL (if not already active)

1. cPanel → SSL/TLS → AutoSSL
2. Click **Run AutoSSL** — `app.aknans.sa` will get a free certificate
3. Takes 2–5 minutes

---

## Troubleshooting

**Login says "Database connection failed"**
- Check config.php — make sure DB_NAME, DB_USER, DB_PASS are correct
- The database name in cPanel has your account prefix (e.g. `john_aknan_erp` not just `aknan_erp`)

**White page or 500 error**
- Check cPanel → Error Logs (under Metrics section)
- Make sure `.htaccess` uploaded correctly (enable hidden files in FileZilla)

**404 on /api/ routes**
- `.htaccess` may not have uploaded. Try: Server → Force showing hidden files → re-upload

**Data shows but won't save**
- Check user permissions in MySQL Databases — user must have ALL PRIVILEGES on the database

---

## File Reference

| File | Purpose |
|------|---------|
| `index.html` | React frontend — served to all users |
| `.htaccess` | Routes /api/* requests to PHP |
| `config.php` | Database credentials — fill in your details |
| `api/index.php` | Complete PHP REST API (all 30+ endpoints) |
| `database.sql` | Import once in phpMyAdmin to create all tables |
| `static/` | CSS, images (empty for now) |
| `uploads/` | Uploaded files (empty for now) |
