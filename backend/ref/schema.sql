-- ============================================================
-- VITALINK IP LAB - DATABASE SCHEMA
-- Auto-generated from TypeScript Models
-- For Database Diagram Creation
-- ============================================================

-- ============================================================
-- 1. USERS TABLE (Central User Management)
-- ============================================================
CREATE TABLE users (
  id VARCHAR(24) PRIMARY KEY COMMENT 'MongoDB ObjectId converted to string',
  login_id VARCHAR(255) NOT NULL UNIQUE COMMENT 'Unique login identifier',
  password VARCHAR(255) NOT NULL COMMENT 'Hashed password',
  salt VARCHAR(255) NOT NULL COMMENT 'Password salt for hashing',
  user_type ENUM('ADMIN', 'DOCTOR', 'PATIENT') NOT NULL COMMENT 'Type of user',
  profile_id VARCHAR(24) NOT NULL COMMENT 'Foreign key to respective profile (AdminProfile, DoctorProfile, PatientProfile)',
  user_type_model VARCHAR(50) NOT NULL COMMENT 'Model reference: AdminProfile, DoctorProfile, PatientProfile',
  is_active BOOLEAN DEFAULT TRUE COMMENT 'User account status',
  must_change_password BOOLEAN DEFAULT FALSE COMMENT 'Force password change on next login',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_login_id (login_id),
  INDEX idx_user_type (user_type),
  INDEX idx_profile_id (profile_id),
  INDEX idx_is_active (is_active),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Central user management table with polymorphic profile references';


-- ============================================================
-- 2. ADMIN PROFILES TABLE
-- ============================================================
CREATE TABLE admin_profiles (
  id VARCHAR(24) PRIMARY KEY COMMENT 'MongoDB ObjectId converted to string',
  permission ENUM('FULL_ACCESS', 'READ_ONLY', 'LIMITED_ACCESS') DEFAULT 'FULL_ACCESS' COMMENT 'Admin permission level',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_permission (permission),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Administrative user profiles with permission levels';


-- ============================================================
-- 3. DOCTOR PROFILES TABLE
-- ============================================================
CREATE TABLE doctor_profiles (
  id VARCHAR(24) PRIMARY KEY COMMENT 'MongoDB ObjectId converted to string',
  name VARCHAR(255) NOT NULL COMMENT 'Doctor full name',
  department VARCHAR(100) DEFAULT 'Cardiology' COMMENT 'Medical department',
  contact_number VARCHAR(20) COMMENT 'Doctor contact phone number',
  profile_picture_url VARCHAR(500) COMMENT 'URL to doctor profile picture',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_name (name),
  INDEX idx_department (department),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Doctor profile information including contact and department details';


-- ============================================================
-- 4. PATIENT PROFILES TABLE
-- ============================================================
CREATE TABLE patient_profiles (
  id VARCHAR(24) PRIMARY KEY COMMENT 'MongoDB ObjectId converted to string',
  assigned_doctor_id VARCHAR(24) COMMENT 'Reference to assigned doctor user',
  
  -- Demographics
  patient_name VARCHAR(255) NOT NULL COMMENT 'Patient full name',
  age INT COMMENT 'Patient age in years',
  gender ENUM('Male', 'Female', 'Other') COMMENT 'Patient gender',
  phone VARCHAR(20) COMMENT 'Patient contact phone number',
  
  -- Next of Kin
  next_of_kin_name VARCHAR(255) COMMENT 'Emergency contact name',
  next_of_kin_relation VARCHAR(100) COMMENT 'Relationship to patient',
  next_of_kin_phone VARCHAR(20) COMMENT 'Emergency contact phone number',
  
  -- Medical Configuration
  diagnosis VARCHAR(500) COMMENT 'Patient diagnosis',
  therapy_drug VARCHAR(255) COMMENT 'Prescribed therapy drug (e.g., Warfarin)',
  therapy_start_date DATE COMMENT 'Date therapy started',
  target_inr_min DECIMAL(4, 2) DEFAULT 2.0 COMMENT 'Target INR minimum value',
  target_inr_max DECIMAL(4, 2) DEFAULT 3.0 COMMENT 'Target INR maximum value',
  next_review_date DATE COMMENT 'Scheduled next review date',
  instructions JSON COMMENT 'Array of medical instructions',
  taken_doses JSON COMMENT 'Array of timestamps when doses were taken',
  
  -- Account Status
  account_status ENUM('Active', 'Discharged', 'Deceased') DEFAULT 'Active' COMMENT 'Patient account status',
  profile_picture_url VARCHAR(500) COMMENT 'URL to patient profile picture',
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (assigned_doctor_id) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_assigned_doctor_id (assigned_doctor_id),
  INDEX idx_patient_name (patient_name),
  INDEX idx_account_status (account_status),
  INDEX idx_created_at (created_at),
  INDEX idx_therapy_start_date (therapy_start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Patient profile with demographics, medical configuration, and therapy details';


-- ============================================================
-- 5. PATIENT MEDICAL HISTORY TABLE
-- ============================================================
CREATE TABLE patient_medical_history (
  id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id VARCHAR(24) NOT NULL COMMENT 'Reference to patient profile',
  diagnosis VARCHAR(500) NOT NULL COMMENT 'Historical diagnosis',
  duration_value INT COMMENT 'Duration of condition',
  duration_unit ENUM('Days', 'Weeks', 'Months', 'Years') COMMENT 'Time unit for duration',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (patient_id) REFERENCES patient_profiles(id) ON DELETE CASCADE,
  INDEX idx_patient_id (patient_id),
  INDEX idx_diagnosis (diagnosis)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Patient medical history with diagnoses and conditions';


-- ============================================================
-- 6. WEEKLY DOSAGE SCHEDULE TABLE
-- ============================================================
CREATE TABLE dosage_schedules (
  id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id VARCHAR(24) NOT NULL UNIQUE COMMENT 'Reference to patient profile',
  monday DECIMAL(6, 2) DEFAULT 0 COMMENT 'Monday dosage amount',
  tuesday DECIMAL(6, 2) DEFAULT 0 COMMENT 'Tuesday dosage amount',
  wednesday DECIMAL(6, 2) DEFAULT 0 COMMENT 'Wednesday dosage amount',
  thursday DECIMAL(6, 2) DEFAULT 0 COMMENT 'Thursday dosage amount',
  friday DECIMAL(6, 2) DEFAULT 0 COMMENT 'Friday dosage amount',
  saturday DECIMAL(6, 2) DEFAULT 0 COMMENT 'Saturday dosage amount',
  sunday DECIMAL(6, 2) DEFAULT 0 COMMENT 'Sunday dosage amount',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (patient_id) REFERENCES patient_profiles(id) ON DELETE CASCADE,
  INDEX idx_patient_id (patient_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Weekly medication dosage schedule for patients';


-- ============================================================
-- 7. INR (INTERNATIONAL NORMALIZED RATIO) LOGS TABLE
-- ============================================================
CREATE TABLE inr_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id VARCHAR(24) NOT NULL COMMENT 'Reference to patient profile',
  test_date DATE NOT NULL COMMENT 'Date of INR test',
  uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When result was uploaded to system',
  inr_value DECIMAL(4, 2) NOT NULL COMMENT 'INR test result value',
  is_critical BOOLEAN DEFAULT FALSE COMMENT 'Flag if INR value is critical',
  file_url VARCHAR(500) COMMENT 'URL to attached test report/file',
  notes TEXT COMMENT 'Additional notes about the test result',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (patient_id) REFERENCES patient_profiles(id) ON DELETE CASCADE,
  INDEX idx_patient_id (patient_id),
  INDEX idx_test_date (test_date),
  INDEX idx_inr_value (inr_value),
  INDEX idx_is_critical (is_critical),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='INR test results and laboratory values for patients';


-- ============================================================
-- 8. HEALTH LOGS TABLE
-- ============================================================
CREATE TABLE health_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id VARCHAR(24) NOT NULL COMMENT 'Reference to patient profile',
  log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Date of health event',
  type VARCHAR(100) NOT NULL COMMENT 'Type of health log entry',
  description TEXT NOT NULL COMMENT 'Description of health event',
  feedback VARCHAR(500) COMMENT 'Feedback or notes from patient',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (patient_id) REFERENCES patient_profiles(id) ON DELETE CASCADE,
  INDEX idx_patient_id (patient_id),
  INDEX idx_type (type),
  INDEX idx_log_date (log_date),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Patient health event logs and daily health updates';


-- ============================================================
-- 9. AUDIT LOGS TABLE
-- ============================================================
CREATE TABLE audit_logs (
  id VARCHAR(24) PRIMARY KEY COMMENT 'MongoDB ObjectId converted to string',
  user_id VARCHAR(24) NOT NULL COMMENT 'Reference to user who performed action',
  user_type VARCHAR(50) NOT NULL COMMENT 'Type of user performing action',
  action VARCHAR(100) NOT NULL COMMENT 'Type of action performed',
  description TEXT NOT NULL COMMENT 'Detailed description of action',
  resource_type VARCHAR(100) COMMENT 'Type of resource affected',
  resource_id VARCHAR(24) COMMENT 'ID of resource affected',
  previous_data JSON COMMENT 'Data before change (JSON)',
  new_data JSON COMMENT 'Data after change (JSON)',
  ip_address VARCHAR(45) COMMENT 'IP address of requester',
  user_agent VARCHAR(500) COMMENT 'User agent string from request',
  success BOOLEAN DEFAULT TRUE COMMENT 'Whether action succeeded',
  error_message TEXT COMMENT 'Error message if action failed',
  metadata JSON COMMENT 'Additional metadata (JSON)',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id_created_at (user_id, created_at),
  INDEX idx_action_created_at (action, created_at),
  INDEX idx_resource_type_id (resource_type, resource_id),
  INDEX idx_success_created_at (success, created_at),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='System audit trail for user actions and changes';


-- ============================================================
-- 10. NOTIFICATIONS TABLE
-- ============================================================
CREATE TABLE notifications (
  id VARCHAR(24) PRIMARY KEY COMMENT 'MongoDB ObjectId converted to string',
  user_id VARCHAR(24) NOT NULL COMMENT 'Reference to user receiving notification',
  notification_type VARCHAR(50) NOT NULL COMMENT 'Type of notification (e.g., INR_REMINDER, CRITICAL_ALERT)',
  priority ENUM('LOW', 'MEDIUM', 'HIGH', 'URGENT') DEFAULT 'MEDIUM' COMMENT 'Priority level of notification',
  title VARCHAR(255) NOT NULL COMMENT 'Notification title',
  message TEXT NOT NULL COMMENT 'Notification message content',
  notification_data JSON COMMENT 'Additional data (JSON)',
  is_read BOOLEAN DEFAULT FALSE COMMENT 'Whether notification has been read',
  read_at TIMESTAMP NULL COMMENT 'Timestamp when notification was read',
  action_url VARCHAR(500) COMMENT 'URL for action associated with notification',
  expires_at TIMESTAMP NULL COMMENT 'Expiration timestamp (auto-delete after this)',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_user_is_read_created_at (user_id, is_read, created_at),
  INDEX idx_notification_type (notification_type),
  INDEX idx_priority (priority),
  INDEX idx_expires_at (expires_at),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='User notifications for reminders, alerts, and system messages';


-- ============================================================
-- 11. SYSTEM CONFIG TABLE
-- ============================================================
CREATE TABLE system_config (
  id VARCHAR(24) PRIMARY KEY COMMENT 'MongoDB ObjectId converted to string',
  
  -- INR Thresholds
  inr_critical_low DECIMAL(4, 2) DEFAULT 1.5 COMMENT 'Critical low INR threshold',
  inr_critical_high DECIMAL(4, 2) DEFAULT 4.5 COMMENT 'Critical high INR threshold',
  
  -- Session Settings
  session_timeout_minutes INT DEFAULT 30 COMMENT 'Session timeout in minutes',
  
  -- Rate Limiting
  rate_limit_max_requests INT DEFAULT 100 COMMENT 'Max requests in rate limit window',
  rate_limit_window_minutes INT DEFAULT 15 COMMENT 'Rate limit window duration in minutes',
  
  -- Feature Flags
  registration_enabled BOOLEAN DEFAULT TRUE COMMENT 'Enable new user registration',
  maintenance_mode BOOLEAN DEFAULT FALSE COMMENT 'System maintenance mode flag',
  beta_features BOOLEAN DEFAULT FALSE COMMENT 'Enable beta features',
  
  -- General Settings
  is_active BOOLEAN DEFAULT TRUE COMMENT 'Configuration is active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_is_active (is_active),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='System-wide configuration and settings';


-- ============================================================
-- VIEWS FOR EASIER QUERYING
-- ============================================================

-- View: User with Profile Details
CREATE OR REPLACE VIEW user_profiles_view AS
SELECT 
  u.id,
  u.login_id,
  u.user_type,
  u.is_active,
  u.created_at,
  CASE 
    WHEN u.user_type = 'ADMIN' THEN ap.permission
    WHEN u.user_type = 'DOCTOR' THEN dp.department
    WHEN u.user_type = 'PATIENT' THEN pp.account_status
  END AS role_specific_field,
  CASE 
    WHEN u.user_type = 'DOCTOR' THEN dp.name
    WHEN u.user_type = 'PATIENT' THEN pp.patient_name
    ELSE NULL
  END AS person_name
FROM users u
LEFT JOIN admin_profiles ap ON u.profile_id = ap.id AND u.user_type = 'ADMIN'
LEFT JOIN doctor_profiles dp ON u.profile_id = dp.id AND u.user_type = 'DOCTOR'
LEFT JOIN patient_profiles pp ON u.profile_id = pp.id AND u.user_type = 'PATIENT';

-- View: Patient Health Dashboard
CREATE OR REPLACE VIEW patient_health_dashboard AS
SELECT 
  pp.id AS patient_id,
  pp.patient_name,
  pp.diagnosis,
  pp.therapy_drug,
  pp.account_status,
  dp.name AS assigned_doctor_name,
  il.inr_value AS latest_inr,
  il.test_date AS latest_inr_date,
  il.is_critical AS inr_is_critical,
  ds.monday + ds.tuesday + ds.wednesday + ds.thursday + ds.friday + ds.saturday + ds.sunday AS weekly_total_dosage,
  pp.target_inr_min,
  pp.target_inr_max,
  pp.next_review_date
FROM patient_profiles pp
LEFT JOIN users du ON pp.assigned_doctor_id = du.id
LEFT JOIN doctor_profiles dp ON du.profile_id = dp.id
LEFT JOIN inr_logs il ON pp.id = il.patient_id AND il.test_date = (
  SELECT MAX(test_date) FROM inr_logs WHERE patient_id = pp.id
)
LEFT JOIN dosage_schedules ds ON pp.id = ds.patient_id;

-- ============================================================
-- END OF SCHEMA
-- ============================================================