-- ================================================================
-- AKNAN ERP — MySQL Database Schema v1.0
-- Character Set: utf8mb4 (supports Arabic)
-- ================================================================
-- HOW TO USE:
-- 1. Create a MySQL database in cPanel → MySQL Databases
-- 2. Open phpMyAdmin, select your database
-- 3. Click "Import" tab → choose this file → Go
-- ================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- ACCESS CONTROL
-- ============================================================
CREATE TABLE IF NOT EXISTS `roles` (
  `id`          VARCHAR(50)  NOT NULL,
  `name`        VARCHAR(100) NOT NULL,
  `tag`         VARCHAR(5)   NOT NULL,
  `color`       VARCHAR(10)  DEFAULT '#1F3864',
  `bg_color`    VARCHAR(10)  DEFAULT '#E8EEF7',
  `description` TEXT,
  `is_locked`   TINYINT(1)   DEFAULT 0,
  `created_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `users` (
  `id`           INT          NOT NULL AUTO_INCREMENT,
  `name`         VARCHAR(150) NOT NULL,
  `email`        VARCHAR(150) NOT NULL,
  `password_hash`VARCHAR(255) NOT NULL,
  `phone`        VARCHAR(30),
  `role_id`      VARCHAR(50),
  `status`       ENUM('Active','Inactive') DEFAULT 'Active',
  `last_login`   TIMESTAMP    NULL,
  `created_at`   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  `updated_at`   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  FOREIGN KEY (`role_id`) REFERENCES `roles`(`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `module_permissions` (
  `id`         INT         NOT NULL AUTO_INCREMENT,
  `role_id`    VARCHAR(50) NOT NULL,
  `module_id`  VARCHAR(50) NOT NULL,
  `can_view`   TINYINT(1)  DEFAULT 0,
  `can_add`    TINYINT(1)  DEFAULT 0,
  `can_edit`   TINYINT(1)  DEFAULT 0,
  `can_delete` TINYINT(1)  DEFAULT 0,
  `updated_at` TIMESTAMP   DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `role_module` (`role_id`,`module_id`),
  FOREIGN KEY (`role_id`) REFERENCES `roles`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `audit_log` (
  `id`         INT          NOT NULL AUTO_INCREMENT,
  `user_id`    INT,
  `action`     VARCHAR(100) NOT NULL,
  `module`     VARCHAR(50),
  `record_id`  INT,
  `old_values` TEXT,
  `new_values` TEXT,
  `ip_address` VARCHAR(45),
  `created_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- MASTER DATA — FINANCIAL
-- ============================================================
CREATE TABLE IF NOT EXISTS `bank_accounts` (
  `id`              INT            NOT NULL AUTO_INCREMENT,
  `bank_name`       VARCHAR(100)   NOT NULL,
  `account_number`  VARCHAR(50),
  `iban`            VARCHAR(50),
  `account_type`    VARCHAR(30)    DEFAULT 'Current',
  `currency`        VARCHAR(5)     DEFAULT 'SAR',
  `opening_balance` DECIMAL(15,2)  DEFAULT 0.00,
  `current_balance` DECIMAL(15,2)  DEFAULT 0.00,
  `is_active`       TINYINT(1)     DEFAULT 1,
  `created_at`      TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `chart_of_accounts` (
  `id`                 INT          NOT NULL AUTO_INCREMENT,
  `account_code`       VARCHAR(20)  NOT NULL,
  `account_name`       VARCHAR(150) NOT NULL,
  `account_name_ar`    VARCHAR(150),
  `account_type`       ENUM('Asset','Liability','Equity','Revenue','Expense'),
  `parent_code`        VARCHAR(20),
  `is_group`           TINYINT(1)   DEFAULT 0,
  `opening_balance_dr` DECIMAL(15,2) DEFAULT 0.00,
  `opening_balance_cr` DECIMAL(15,2) DEFAULT 0.00,
  `currency`           VARCHAR(5)   DEFAULT 'SAR',
  `is_active`          TINYINT(1)   DEFAULT 1,
  `created_at`         TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `account_code` (`account_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- MASTER DATA — PARTIES
-- ============================================================
CREATE TABLE IF NOT EXISTS `customers` (
  `id`               INT           NOT NULL AUTO_INCREMENT,
  `customer_code`    VARCHAR(30)   NOT NULL,
  `name`             VARCHAR(150)  NOT NULL,
  `contact_person`   VARCHAR(100),
  `phone`            VARCHAR(30),
  `email`            VARCHAR(150),
  `address`          TEXT,
  `city`             VARCHAR(80),
  `country`          VARCHAR(80)   DEFAULT 'Saudi Arabia',
  `payment_type`     ENUM('Cash','Credit') DEFAULT 'Credit',
  `credit_limit`     DECIMAL(15,2) DEFAULT 0.00,
  `credit_term_days` INT           DEFAULT 30,
  `tax_number`       VARCHAR(30),
  `status`           ENUM('Active','Inactive') DEFAULT 'Active',
  `notes`            TEXT,
  `created_by`       INT,
  `created_at`       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `customer_code` (`customer_code`),
  FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `vendors` (
  `id`               INT           NOT NULL AUTO_INCREMENT,
  `vendor_code`      VARCHAR(30)   NOT NULL,
  `name`             VARCHAR(150)  NOT NULL,
  `contact_person`   VARCHAR(100),
  `phone`            VARCHAR(30),
  `email`            VARCHAR(150),
  `address`          TEXT,
  `city`             VARCHAR(80),
  `country`          VARCHAR(80)   DEFAULT 'Saudi Arabia',
  `payment_type`     ENUM('Cash','Credit','Bank Transfer') DEFAULT 'Credit',
  `credit_limit`     DECIMAL(15,2) DEFAULT 0.00,
  `credit_term_days` INT           DEFAULT 45,
  `bank_name`        VARCHAR(100),
  `bank_account`     VARCHAR(50),
  `iban`             VARCHAR(50),
  `tax_number`       VARCHAR(30),
  `status`           ENUM('Active','Inactive') DEFAULT 'Active',
  `notes`            TEXT,
  `created_by`       INT,
  `created_at`       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `vendor_code` (`vendor_code`),
  FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `distributors` (
  `id`               INT           NOT NULL AUTO_INCREMENT,
  `distributor_code` VARCHAR(30)   NOT NULL,
  `name`             VARCHAR(150)  NOT NULL,
  `contact_person`   VARCHAR(100)  NOT NULL,
  `phone`            VARCHAR(30)   NOT NULL,
  `email`            VARCHAR(150),
  `address`          TEXT,
  `city`             VARCHAR(80),
  `region`           VARCHAR(100)  NOT NULL,
  `payment_type`     ENUM('Cash','Credit','Both') DEFAULT 'Credit',
  `credit_limit`     DECIMAL(15,2) DEFAULT 0.00,
  `credit_term_days` INT           DEFAULT 30,
  `delivery_type`    ENUM('Company Vehicle','3PL','Both') DEFAULT 'Both',
  `assigned_area`    VARCHAR(150),
  `bank_name`        VARCHAR(100),
  `bank_account`     VARCHAR(50),
  `iban`             VARCHAR(50),
  `tax_number`       VARCHAR(30),
  `status`           ENUM('Active','Inactive','On Hold') DEFAULT 'Active',
  `notes`            TEXT,
  `created_by`       INT,
  `created_at`       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `distributor_code` (`distributor_code`),
  FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- MASTER DATA — PRODUCTS
-- ============================================================
CREATE TABLE IF NOT EXISTS `parent_skus` (
  `id`            INT          NOT NULL AUTO_INCREMENT,
  `sku_code`      VARCHAR(30)  NOT NULL,
  `name`          VARCHAR(150) NOT NULL,
  `description`   TEXT,
  `material_type` VARCHAR(50),
  `status`        ENUM('Active','Inactive') DEFAULT 'Active',
  `created_at`    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sku_code` (`sku_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `machines` (
  `id`            INT          NOT NULL AUTO_INCREMENT,
  `machine_code`  VARCHAR(30)  NOT NULL,
  `machine_name`  VARCHAR(100) NOT NULL,
  `parent_sku_id` INT,
  `description`   TEXT,
  `status`        ENUM('Active','Inactive','Maintenance') DEFAULT 'Active',
  `created_at`    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `machine_code` (`machine_code`),
  FOREIGN KEY (`parent_sku_id`) REFERENCES `parent_skus`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sub_skus` (
  `id`              INT           NOT NULL AUTO_INCREMENT,
  `sku_code`        VARCHAR(30)   NOT NULL,
  `parent_sku_id`   INT,
  `name`            VARCHAR(150)  NOT NULL,
  `description`     TEXT,
  `size_dimension`  VARCHAR(50),
  `material_type`   VARCHAR(50),
  `pressure_rating` VARCHAR(30),
  `length_m`        DECIMAL(8,2),
  `unit_of_measure` VARCHAR(20)   DEFAULT 'Meter',
  `selling_price`   DECIMAL(15,2) DEFAULT 0.00,
  `cost_price`      DECIMAL(15,2) DEFAULT 0.00,
  `reorder_level`   DECIMAL(10,2) DEFAULT 0.00,
  `current_stock`   DECIMAL(10,2) DEFAULT 0.00,
  `status`          ENUM('Active','Inactive','Discontinued') DEFAULT 'Active',
  `created_at`      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sku_code` (`sku_code`),
  FOREIGN KEY (`parent_sku_id`) REFERENCES `parent_skus`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `raw_materials` (
  `id`              INT           NOT NULL AUTO_INCREMENT,
  `material_code`   VARCHAR(30)   NOT NULL,
  `name`            VARCHAR(150)  NOT NULL,
  `description`     TEXT,
  `unit_of_measure` VARCHAR(20)   DEFAULT 'Kg',
  `cost_per_unit`   DECIMAL(15,2) DEFAULT 0.00,
  `current_stock`   DECIMAL(10,2) DEFAULT 0.00,
  `reorder_level`   DECIMAL(10,2) DEFAULT 0.00,
  `status`          ENUM('Active','Inactive') DEFAULT 'Active',
  `created_at`      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `material_code` (`material_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bill_of_materials` (
  `id`               INT           NOT NULL AUTO_INCREMENT,
  `sub_sku_id`       INT           NOT NULL,
  `raw_material_id`  INT           NOT NULL,
  `quantity_required`DECIMAL(10,4) NOT NULL,
  `unit_of_measure`  VARCHAR(20),
  `version`          INT           DEFAULT 1,
  `is_active`        TINYINT(1)    DEFAULT 1,
  `created_at`       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sku_material_ver` (`sub_sku_id`,`raw_material_id`,`version`),
  FOREIGN KEY (`sub_sku_id`)      REFERENCES `sub_skus`(`id`)      ON DELETE CASCADE,
  FOREIGN KEY (`raw_material_id`) REFERENCES `raw_materials`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- MASTER DATA — HR
-- ============================================================
CREATE TABLE IF NOT EXISTS `employees` (
  `id`                  INT           NOT NULL AUTO_INCREMENT,
  `employee_code`       VARCHAR(30)   NOT NULL,
  `name`                VARCHAR(150)  NOT NULL,
  `name_ar`             VARCHAR(150),
  `national_id`         VARCHAR(30),
  `nationality`         VARCHAR(50),
  `date_of_birth`       DATE,
  `gender`              ENUM('Male','Female'),
  `phone`               VARCHAR(30),
  `personal_email`      VARCHAR(150),
  `department`          VARCHAR(80),
  `job_title`           VARCHAR(100),
  `employment_type`     ENUM('Full-Time','Part-Time','Contract','Seasonal') DEFAULT 'Full-Time',
  `join_date`           DATE,
  `contract_expiry`     DATE,
  `basic_salary`        DECIMAL(12,2) DEFAULT 0.00,
  `housing_allowance`   DECIMAL(12,2) DEFAULT 0.00,
  `transport_allowance` DECIMAL(12,2) DEFAULT 0.00,
  `other_allowance`     DECIMAL(12,2) DEFAULT 0.00,
  `bank_name`           VARCHAR(100),
  `bank_account`        VARCHAR(50),
  `iban`                VARCHAR(50),
  `emergency_contact`   VARCHAR(100),
  `emergency_phone`     VARCHAR(30),
  `status`              ENUM('Active','Inactive','Terminated') DEFAULT 'Active',
  `notes`               TEXT,
  `created_by`          INT,
  `created_at`          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `employee_code` (`employee_code`),
  FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `attendance` (
  `id`                    INT           NOT NULL AUTO_INCREMENT,
  `employee_id`           INT           NOT NULL,
  `attendance_date`       DATE          NOT NULL,
  `day_of_week`           VARCHAR(15),
  `check_in`              TIME,
  `check_out`             TIME,
  `working_hours`         DECIMAL(5,2),
  `status`                ENUM('Present','Absent','Late','Half Day','Leave','Public Holiday','Weekly Off'),
  `late_minutes`          INT           DEFAULT 0,
  `early_leave_minutes`   INT           DEFAULT 0,
  `overtime_hours`        DECIMAL(5,2)  DEFAULT 0,
  `import_batch`          VARCHAR(50),
  `remarks`               TEXT,
  `created_at`            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `emp_date` (`employee_id`,`attendance_date`),
  FOREIGN KEY (`employee_id`) REFERENCES `employees`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TRANSACTIONS — PURCHASE
-- ============================================================
CREATE TABLE IF NOT EXISTS `purchase_orders` (
  `id`                INT           NOT NULL AUTO_INCREMENT,
  `po_number`         VARCHAR(30)   NOT NULL,
  `vendor_id`         INT,
  `order_date`        DATE          NOT NULL,
  `expected_delivery` DATE,
  `status`            ENUM('Pending','Approved','Partial','Received','Closed','Cancelled') DEFAULT 'Pending',
  `payment_method`    ENUM('Cash','Bank Transfer'),
  `bank_account_id`   INT,
  `subtotal`          DECIMAL(15,2) DEFAULT 0.00,
  `tax_rate`          DECIMAL(5,2)  DEFAULT 15.00,
  `tax_amount`        DECIMAL(15,2) DEFAULT 0.00,
  `total_amount`      DECIMAL(15,2) DEFAULT 0.00,
  `notes`             TEXT,
  `created_by`        INT,
  `created_at`        TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `po_number` (`po_number`),
  FOREIGN KEY (`vendor_id`)       REFERENCES `vendors`(`id`)       ON DELETE SET NULL,
  FOREIGN KEY (`bank_account_id`) REFERENCES `bank_accounts`(`id`) ON DELETE SET NULL,
  FOREIGN KEY (`created_by`)      REFERENCES `users`(`id`)         ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `purchase_order_items` (
  `id`              INT           NOT NULL AUTO_INCREMENT,
  `po_id`           INT           NOT NULL,
  `raw_material_id` INT,
  `quantity`        DECIMAL(10,2) NOT NULL,
  `unit_price`      DECIMAL(15,2) NOT NULL,
  `line_total`      DECIMAL(15,2) DEFAULT 0.00,
  `received_qty`    DECIMAL(10,2) DEFAULT 0.00,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`po_id`)           REFERENCES `purchase_orders`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`raw_material_id`) REFERENCES `raw_materials`(`id`)   ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TRANSACTIONS — SALES
-- ============================================================
CREATE TABLE IF NOT EXISTS `sales_orders` (
  `id`              INT           NOT NULL AUTO_INCREMENT,
  `so_number`       VARCHAR(30)   NOT NULL,
  `customer_id`     INT,
  `distributor_id`  INT,
  `order_date`      DATE          NOT NULL,
  `delivery_date`   DATE,
  `order_type`      ENUM('Proforma','Sales Order') DEFAULT 'Sales Order',
  `status`          ENUM('Draft','Confirmed','Invoiced','Delivered','Cancelled') DEFAULT 'Draft',
  `payment_method`  ENUM('Cash','Bank Transfer','Credit'),
  `bank_account_id` INT,
  `subtotal`        DECIMAL(15,2) DEFAULT 0.00,
  `tax_rate`        DECIMAL(5,2)  DEFAULT 15.00,
  `tax_amount`      DECIMAL(15,2) DEFAULT 0.00,
  `discount`        DECIMAL(15,2) DEFAULT 0.00,
  `total_amount`    DECIMAL(15,2) DEFAULT 0.00,
  `notes`           TEXT,
  `created_by`      INT,
  `created_at`      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `so_number` (`so_number`),
  FOREIGN KEY (`customer_id`)    REFERENCES `customers`(`id`)    ON DELETE SET NULL,
  FOREIGN KEY (`distributor_id`) REFERENCES `distributors`(`id`) ON DELETE SET NULL,
  FOREIGN KEY (`bank_account_id`)REFERENCES `bank_accounts`(`id`)ON DELETE SET NULL,
  FOREIGN KEY (`created_by`)     REFERENCES `users`(`id`)        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sales_order_items` (
  `id`           INT           NOT NULL AUTO_INCREMENT,
  `so_id`        INT           NOT NULL,
  `sub_sku_id`   INT,
  `quantity`     DECIMAL(10,2) NOT NULL,
  `unit_price`   DECIMAL(15,2) NOT NULL,
  `discount_pct` DECIMAL(5,2)  DEFAULT 0.00,
  `line_total`   DECIMAL(15,2) DEFAULT 0.00,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`so_id`)      REFERENCES `sales_orders`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`sub_sku_id`) REFERENCES `sub_skus`(`id`)     ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `invoices` (
  `id`              INT           NOT NULL AUTO_INCREMENT,
  `invoice_number`  VARCHAR(30)   NOT NULL,
  `so_id`           INT,
  `customer_id`     INT,
  `distributor_id`  INT,
  `invoice_date`    DATE          NOT NULL,
  `due_date`        DATE,
  `status`          ENUM('Unpaid','Partial','Paid','Cancelled') DEFAULT 'Unpaid',
  `payment_method`  ENUM('Cash','Bank Transfer','Credit'),
  `bank_account_id` INT,
  `subtotal`        DECIMAL(15,2) DEFAULT 0.00,
  `tax_rate`        DECIMAL(5,2)  DEFAULT 15.00,
  `tax_amount`      DECIMAL(15,2) DEFAULT 0.00,
  `total_amount`    DECIMAL(15,2) DEFAULT 0.00,
  `paid_amount`     DECIMAL(15,2) DEFAULT 0.00,
  `created_by`      INT,
  `created_at`      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `invoice_number` (`invoice_number`),
  FOREIGN KEY (`so_id`)          REFERENCES `sales_orders`(`id`)  ON DELETE SET NULL,
  FOREIGN KEY (`customer_id`)    REFERENCES `customers`(`id`)     ON DELETE SET NULL,
  FOREIGN KEY (`distributor_id`) REFERENCES `distributors`(`id`)  ON DELETE SET NULL,
  FOREIGN KEY (`bank_account_id`)REFERENCES `bank_accounts`(`id`) ON DELETE SET NULL,
  FOREIGN KEY (`created_by`)     REFERENCES `users`(`id`)         ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TRANSACTIONS — EXPENSES
-- ============================================================
CREATE TABLE IF NOT EXISTS `expense_categories` (
  `id`        INT         NOT NULL AUTO_INCREMENT,
  `name`      VARCHAR(80) NOT NULL,
  `coa_code`  VARCHAR(20),
  `is_active` TINYINT(1)  DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `expenses` (
  `id`              INT           NOT NULL AUTO_INCREMENT,
  `expense_number`  VARCHAR(30)   NOT NULL,
  `category_id`     INT,
  `expense_date`    DATE          NOT NULL,
  `description`     VARCHAR(255)  NOT NULL,
  `amount`          DECIMAL(15,2) NOT NULL,
  `payment_method`  ENUM('Cash','Bank Transfer') NOT NULL,
  `bank_account_id` INT,
  `department`      VARCHAR(80),
  `status`          ENUM('Draft','Submitted','Approved','Posted','Rejected') DEFAULT 'Draft',
  `receipt_ref`     VARCHAR(100),
  `notes`           TEXT,
  `created_by`      INT,
  `created_at`      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `expense_number` (`expense_number`),
  FOREIGN KEY (`category_id`)    REFERENCES `expense_categories`(`id`) ON DELETE SET NULL,
  FOREIGN KEY (`bank_account_id`)REFERENCES `bank_accounts`(`id`)      ON DELETE SET NULL,
  FOREIGN KEY (`created_by`)     REFERENCES `users`(`id`)               ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TRANSACTIONS — DELIVERY
-- ============================================================
CREATE TABLE IF NOT EXISTS `company_vehicles` (
  `id`           INT         NOT NULL AUTO_INCREMENT,
  `vehicle_code` VARCHAR(30) NOT NULL,
  `plate_number` VARCHAR(30) NOT NULL,
  `vehicle_type` VARCHAR(50),
  `make`         VARCHAR(50),
  `model`        VARCHAR(50),
  `year`         YEAR,
  `status`       ENUM('Active','Inactive') DEFAULT 'Active',
  `created_at`   TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `vehicle_code` (`vehicle_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `delivery_orders` (
  `id`                  INT           NOT NULL AUTO_INCREMENT,
  `delivery_number`     VARCHAR(30)   NOT NULL,
  `so_id`               INT,
  `distributor_id`      INT,
  `delivery_date`       DATE          NOT NULL,
  `delivery_type`       ENUM('Company Vehicle','3PL'),
  `vehicle_id`          INT,
  `driver_id`           INT,
  `tpl_company`         VARCHAR(100),
  `tpl_driver_name`     VARCHAR(100),
  `tpl_vehicle_details` VARCHAR(150),
  `waybill_number`      VARCHAR(50),
  `status`              ENUM('Pending','Dispatched','Delivered','Returned','Cancelled') DEFAULT 'Pending',
  `fuel_cost`           DECIMAL(12,2) DEFAULT 0.00,
  `driver_allowance`    DECIMAL(12,2) DEFAULT 0.00,
  `tolls`               DECIMAL(12,2) DEFAULT 0.00,
  `misc_cost`           DECIMAL(12,2) DEFAULT 0.00,
  `total_trip_cost`     DECIMAL(12,2) DEFAULT 0.00,
  `notes`               TEXT,
  `created_by`          INT,
  `created_at`          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `delivery_number` (`delivery_number`),
  FOREIGN KEY (`so_id`)          REFERENCES `sales_orders`(`id`)   ON DELETE SET NULL,
  FOREIGN KEY (`distributor_id`) REFERENCES `distributors`(`id`)   ON DELETE SET NULL,
  FOREIGN KEY (`vehicle_id`)     REFERENCES `company_vehicles`(`id`)ON DELETE SET NULL,
  FOREIGN KEY (`driver_id`)      REFERENCES `employees`(`id`)      ON DELETE SET NULL,
  FOREIGN KEY (`created_by`)     REFERENCES `users`(`id`)          ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TRANSACTIONS — PRODUCTION
-- ============================================================
CREATE TABLE IF NOT EXISTS `production_entries` (
  `id`               INT         NOT NULL AUTO_INCREMENT,
  `entry_number`     VARCHAR(30) NOT NULL,
  `machine_id`       INT,
  `parent_sku_id`    INT,
  `production_date`  DATE        NOT NULL,
  `shift`            VARCHAR(30),
  `downtime_minutes` INT         DEFAULT 0,
  `downtime_reason`  TEXT,
  `status`           ENUM('Draft','Submitted','Locked') DEFAULT 'Draft',
  `submitted_by`     INT,
  `created_at`       TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP   DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `entry_number` (`entry_number`),
  UNIQUE KEY `machine_date` (`machine_id`,`production_date`),
  FOREIGN KEY (`machine_id`)    REFERENCES `machines`(`id`)     ON DELETE SET NULL,
  FOREIGN KEY (`parent_sku_id`) REFERENCES `parent_skus`(`id`)  ON DELETE SET NULL,
  FOREIGN KEY (`submitted_by`)  REFERENCES `users`(`id`)        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `production_entry_items` (
  `id`                  INT           NOT NULL AUTO_INCREMENT,
  `production_entry_id` INT           NOT NULL,
  `sub_sku_id`          INT,
  `quantity_produced`   DECIMAL(10,2) NOT NULL,
  `waste_quantity`      DECIMAL(10,2) DEFAULT 0.00,
  `rejection_reason`    VARCHAR(255),
  PRIMARY KEY (`id`),
  FOREIGN KEY (`production_entry_id`) REFERENCES `production_entries`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`sub_sku_id`)          REFERENCES `sub_skus`(`id`)           ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `stock_movements` (
  `id`              INT           NOT NULL AUTO_INCREMENT,
  `movement_date`   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `movement_type`   ENUM('GRN In','Production In','Production Out','Sale Out','Adjustment','Return In'),
  `reference_type`  VARCHAR(50),
  `reference_id`    INT,
  `item_type`       ENUM('sub_sku','raw_material'),
  `sub_sku_id`      INT,
  `raw_material_id` INT,
  `qty_in`          DECIMAL(10,2) DEFAULT 0.00,
  `qty_out`         DECIMAL(10,2) DEFAULT 0.00,
  `balance_after`   DECIMAL(10,2),
  `notes`           TEXT,
  `created_by`      INT,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`sub_sku_id`)      REFERENCES `sub_skus`(`id`)      ON DELETE SET NULL,
  FOREIGN KEY (`raw_material_id`) REFERENCES `raw_materials`(`id`) ON DELETE SET NULL,
  FOREIGN KEY (`created_by`)      REFERENCES `users`(`id`)         ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TRANSACTIONS — ACCOUNTS
-- ============================================================
CREATE TABLE IF NOT EXISTS `payments` (
  `id`               INT           NOT NULL AUTO_INCREMENT,
  `payment_number`   VARCHAR(30)   NOT NULL,
  `payment_date`     DATE          NOT NULL,
  `payment_type`     ENUM('Received','Made'),
  `entity_type`      ENUM('Customer','Distributor','Vendor'),
  `customer_id`      INT,
  `distributor_id`   INT,
  `vendor_id`        INT,
  `amount`           DECIMAL(15,2) NOT NULL,
  `payment_method`   ENUM('Cash','Bank Transfer') NOT NULL,
  `bank_account_id`  INT,
  `reference_number` VARCHAR(80),
  `notes`            TEXT,
  `created_by`       INT,
  `created_at`       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `payment_number` (`payment_number`),
  FOREIGN KEY (`customer_id`)    REFERENCES `customers`(`id`)    ON DELETE SET NULL,
  FOREIGN KEY (`distributor_id`) REFERENCES `distributors`(`id`) ON DELETE SET NULL,
  FOREIGN KEY (`vendor_id`)      REFERENCES `vendors`(`id`)      ON DELETE SET NULL,
  FOREIGN KEY (`bank_account_id`)REFERENCES `bank_accounts`(`id`)ON DELETE SET NULL,
  FOREIGN KEY (`created_by`)     REFERENCES `users`(`id`)        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- DEFAULT DATA
-- ============================================================

-- Roles
INSERT IGNORE INTO `roles` (`id`,`name`,`tag`,`color`,`bg_color`,`description`,`is_locked`) VALUES
('super_admin',    'Super Admin',           'SA','#1F3864','#E8EEF7','Full unrestricted access. Cannot be modified.',1),
('purchase_officer','Purchase Officer',     'PO','#1C5D86','#E3F0F9','Manages purchase orders and vendor records.',0),
('sales_officer',  'Sales Officer',         'SO','#375623','#E5F0E0','Manages customer orders and invoicing.',0),
('accounts',       'Accounts / Finance',    'AF','#7B5C00','#F9F2E0','Full access to financial data and reports.',0),
('hr_manager',     'HR Manager',            'HR','#7B2C2C','#F9E8E8','Manages employee data, attendance and payroll.',0),
('warehouse',      'Store / Warehouse',     'WH','#566270','#EEF0F2','Manages inventory and production stock.',0),
('production_sup', 'Production Supervisor', 'PS','#2E75B6','#E6F0FA','Enters daily production data per machine.',0),
('delivery_mgr',   'Delivery Manager',      'DM','#4A4A8A','#EEEEF7','Manages deliveries, drivers and fleet costs.',0),
('viewer',         'Management / Viewer',   'MV','#595959','#F2F2F2','Read-only access to all reports.',0);

-- Admin user  (password: admin123)
INSERT IGNORE INTO `users` (`name`,`email`,`password_hash`,`phone`,`role_id`,`status`) VALUES
('System Administrator','admin@aknan.com','$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi','+966 12 000 0001','super_admin','Active');

-- Module permissions (9 roles × 8 modules = 72 rows)
INSERT IGNORE INTO `module_permissions` (`role_id`,`module_id`,`can_view`,`can_add`,`can_edit`,`can_delete`) VALUES
('super_admin','purchase',1,1,1,1),('super_admin','expense',1,1,1,1),('super_admin','sales',1,1,1,1),
('super_admin','accounts',1,1,1,1),('super_admin','hr',1,1,1,1),('super_admin','delivery',1,1,1,1),
('super_admin','distributor',1,1,1,1),('super_admin','production',1,1,1,1),
('purchase_officer','purchase',1,1,1,0),('purchase_officer','expense',1,0,0,0),('purchase_officer','sales',0,0,0,0),
('purchase_officer','accounts',0,0,0,0),('purchase_officer','hr',0,0,0,0),('purchase_officer','delivery',0,0,0,0),
('purchase_officer','distributor',0,0,0,0),('purchase_officer','production',0,0,0,0),
('sales_officer','purchase',0,0,0,0),('sales_officer','expense',0,0,0,0),('sales_officer','sales',1,1,1,0),
('sales_officer','accounts',0,0,0,0),('sales_officer','hr',0,0,0,0),('sales_officer','delivery',1,0,0,0),
('sales_officer','distributor',1,1,1,0),('sales_officer','production',0,0,0,0),
('accounts','purchase',1,0,0,0),('accounts','expense',1,1,1,0),('accounts','sales',1,0,0,0),
('accounts','accounts',1,1,1,0),('accounts','hr',0,0,0,0),('accounts','delivery',0,0,0,0),
('accounts','distributor',1,0,0,0),('accounts','production',0,0,0,0),
('hr_manager','purchase',0,0,0,0),('hr_manager','expense',0,0,0,0),('hr_manager','sales',0,0,0,0),
('hr_manager','accounts',0,0,0,0),('hr_manager','hr',1,1,1,0),('hr_manager','delivery',0,0,0,0),
('hr_manager','distributor',0,0,0,0),('hr_manager','production',0,0,0,0),
('warehouse','purchase',1,0,0,0),('warehouse','expense',0,0,0,0),('warehouse','sales',0,0,0,0),
('warehouse','accounts',0,0,0,0),('warehouse','hr',0,0,0,0),('warehouse','delivery',0,0,0,0),
('warehouse','distributor',0,0,0,0),('warehouse','production',1,1,1,0),
('production_sup','purchase',0,0,0,0),('production_sup','expense',0,0,0,0),('production_sup','sales',0,0,0,0),
('production_sup','accounts',0,0,0,0),('production_sup','hr',0,0,0,0),('production_sup','delivery',0,0,0,0),
('production_sup','distributor',0,0,0,0),('production_sup','production',1,1,1,0),
('delivery_mgr','purchase',0,0,0,0),('delivery_mgr','expense',0,0,0,0),('delivery_mgr','sales',1,0,0,0),
('delivery_mgr','accounts',0,0,0,0),('delivery_mgr','hr',0,0,0,0),('delivery_mgr','delivery',1,1,1,0),
('delivery_mgr','distributor',1,0,0,0),('delivery_mgr','production',0,0,0,0),
('viewer','purchase',1,0,0,0),('viewer','expense',1,0,0,0),('viewer','sales',1,0,0,0),
('viewer','accounts',1,0,0,0),('viewer','hr',1,0,0,0),('viewer','delivery',1,0,0,0),
('viewer','distributor',1,0,0,0),('viewer','production',1,0,0,0);

-- Bank accounts
INSERT IGNORE INTO `bank_accounts` (`bank_name`,`currency`) VALUES
('Al Rajhi Bank','SAR'),('NCB / AlAhli Bank','SAR'),('Riyad Bank','SAR'),('Cash Account','SAR');

-- Chart of Accounts
INSERT IGNORE INTO `chart_of_accounts` (`account_code`,`account_name`,`account_type`,`parent_code`,`is_group`) VALUES
('1000','ASSETS','Asset',NULL,1),('1100','Current Assets','Asset','1000',1),
('1110','Cash in Hand','Asset','1100',0),('1120','Bank Accounts','Asset','1100',1),
('1121','Al Rajhi Bank - SAR','Asset','1120',0),('1122','NCB / AlAhli Bank - SAR','Asset','1120',0),
('1123','Riyad Bank - SAR','Asset','1120',0),('1130','Accounts Receivable','Asset','1100',0),
('1140','Inventory - Finished Goods','Asset','1100',0),('1150','Inventory - Raw Materials','Asset','1100',0),
('1200','Fixed Assets','Asset','1000',1),('1210','Plant & Machinery','Asset','1200',0),
('1220','Vehicles','Asset','1200',0),
('2000','LIABILITIES','Liability',NULL,1),('2100','Current Liabilities','Liability','2000',1),
('2110','Accounts Payable','Liability','2100',0),('2120','VAT Payable','Liability','2100',0),
('3000','EQUITY','Equity',NULL,1),('3100','Owner Capital','Equity','3000',0),
('3200','Retained Earnings','Equity','3000',0),
('4000','REVENUE','Revenue',NULL,1),('4100','Sales Revenue','Revenue','4000',0),
('4200','Other Income','Revenue','4000',0),
('5000','COST OF GOODS SOLD','Expense',NULL,1),('5100','Raw Material Cost','Expense','5000',0),
('5200','Production Labour','Expense','5000',0),
('6000','OPERATING EXPENSES','Expense',NULL,1),('6100','Salaries & Wages','Expense','6000',0),
('6200','Delivery Expense','Expense','6000',0),('6300','Fuel Expense','Expense','6000',0),
('6400','Utilities','Expense','6000',0),('6500','Rent','Expense','6000',0),
('6600','Maintenance','Expense','6000',0),('6700','Marketing & Advertising','Expense','6000',0),
('6800','Miscellaneous Expense','Expense','6000',0);

-- Expense categories
INSERT IGNORE INTO `expense_categories` (`name`,`coa_code`) VALUES
('Salaries & Wages','6100'),('Fuel Expense','6300'),('Delivery Expense','6200'),
('Utilities','6400'),('Rent','6500'),('Maintenance','6600'),
('Marketing','6700'),('Office Supplies','6800'),('Miscellaneous','6800');
