-- Script untuk membuat database dan user untuk SendGrid
-- Jalankan script ini setelah PostgreSQL container berjalan

-- Membuat database untuk SendGrid
CREATE DATABASE sendgrid_db;

-- Membuat user khusus untuk SendGrid (opsional)
-- CREATE USER sendgrid_user WITH PASSWORD 'sendgrid_password';
-- GRANT ALL PRIVILEGES ON DATABASE sendgrid_emails TO sendgrid_user;

-- Atau gunakan user postgres yang sama untuk simplicity
GRANT ALL PRIVILEGES ON DATABASE sendgrid_db TO postgres;

-- Connect to sendgrid_emails database untuk membuat schema
\c sendgrid_db;

-- Import schema dari sendgrid-inbound/database/schema.sql jika ada
-- \i /path/to/sendgrid-inbound/database/schema.sql
-- untuk saat ini schema di create oleh server sendgrid-inbound