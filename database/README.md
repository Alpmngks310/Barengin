# Barengin Database

Dokumentasi database untuk aplikasi **Barengin**, sebuah platform sosial yang memungkinkan pengguna menemukan aktivitas, membuat kegiatan, dan bergabung dengan aktivitas bersama pengguna lainnya.

Folder ini berisi file SQL yang digunakan sebagai sumber database untuk kebutuhan pengembangan dan pengujian aplikasi Barengin.

## 1. Database Overview

| Informasi | Detail |
|---|---|
| Project | Barengin |
| Database File | `barengin_db.sql` |
| Database Management System | MySQL / MariaDB |
| Format | SQL |
| Status | Ongoing Development |

## 2. Folder Structure

```text
database/
│
├── README.md
└── barengin_db.sql
```

**Keterangan:**

- `README.md` — Dokumentasi database dan panduan instalasi.
- `barengin_db.sql` — File SQL yang berisi struktur dan/atau data database Barengin sesuai hasil ekspor.

## 3. Database Import Guide

Database dapat diimpor menggunakan phpMyAdmin melalui XAMPP atau Laragon.

### A. Menggunakan phpMyAdmin

1. Jalankan Apache dan MySQL melalui XAMPP atau Laragon.
2. Buka phpMyAdmin melalui browser:

   `http://localhost/phpmyadmin`

3. Buat database baru dengan nama:

   `barengin_db`

4. Pilih database `barengin_db`.
5. Buka menu **Import**.
6. Pilih file `barengin_db.sql`.
7. Klik tombol **Import** atau **Go**.
8. Tunggu sampai proses import selesai.

### B. Menggunakan MySQL Command Line

Buat database terlebih dahulu:

```sql
CREATE DATABASE barengin_db;
```

Kemudian impor file SQL melalui terminal:

```bash
mysql -u root -p barengin_db < database/barengin_db.sql
```

Sesuaikan username dan password MySQL dengan konfigurasi lokal.

## 4. Laravel Database Configuration

Setelah database berhasil diimpor, sesuaikan konfigurasi koneksi database pada file `.env` di folder `Barengin_Backend/`.

Contoh konfigurasi MySQL:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=barengin_db
DB_USERNAME=root
DB_PASSWORD=
```

Sesuaikan konfigurasi tersebut dengan environment database yang digunakan.

Setelah itu, bersihkan cache konfigurasi Laravel:

```bash
php artisan config:clear
```

Pastikan backend dapat terhubung ke database sebelum menjalankan aplikasi.

## 5. Important Notes

- Pastikan MySQL atau MariaDB sudah berjalan sebelum melakukan import.
- Gunakan database yang sesuai dengan konfigurasi backend.
- Jangan mengunggah file `.env`, password, token, atau kredensial database ke repository.
- File SQL digunakan untuk membantu proses setup database pada lingkungan pengembangan.
- Struktur database dapat berubah mengikuti perkembangan aplikasi Barengin.

## 6. Project Repository

Source code aplikasi dan dokumentasi pengembangan tersedia di:

**GitHub:** https://github.com/Alpmngks310/Barengin

---

**Barengin — Find Your People, Share Your Moments.**

*Database Documentation | Ongoing Development*
