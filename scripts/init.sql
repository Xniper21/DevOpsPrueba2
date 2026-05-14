-- =====================================================
-- Initialize Innovatech Database
-- =====================================================

-- Use the database
USE innovatechdb;

-- Set character set
ALTER DATABASE innovatechdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- =====================================================
-- Initial Setup
-- =====================================================
GRANT ALL PRIVILEGES ON innovatechdb.* TO 'innovatech'@'%';
FLUSH PRIVILEGES;

-- Add any initial data here if needed
