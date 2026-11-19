# Barengin

**Aplikasi untuk menemukan teman dan bergabung dalam berbagai aktivitas bersama.**

Barengin merupakan aplikasi sosial yang dirancang untuk membantu pengguna menemukan orang dengan minat dan aktivitas yang sama. Melalui Barengin, pengguna dapat menjelajahi aktivitas di sekitarnya, membuat kegiatan sendiri, serta bergabung dengan aktivitas yang dibuat oleh pengguna lain.

Project ini dikembangkan dengan fokus pada pengalaman sosial yang lebih mudah, interaktif, dan fleksibel, khususnya bagi mahasiswa dan generasi muda.

> **Project Status: Ongoing Development**  
> Barengin masih dalam tahap pengembangan. Fitur, tampilan, dan arsitektur aplikasi dapat mengalami perubahan seiring proses pengembangan.

---

## 1. Project Overview

| Informasi | Detail |
|---|---|
| Nama Aplikasi | Barengin |
| Kategori | Social Activity & Community App |
| Target Pengguna | Mahasiswa dan masyarakat umum |
| Platform | Android (Flutter) |
| Frontend | Flutter & Dart |
| Backend | Laravel (PHP) |
| Database | MySQL / SQLite sesuai konfigurasi |
| Metodologi Pengembangan | Agile |
| Status | Ongoing Development |

## 2. Background & Purpose

Tidak semua orang mudah menemukan teman untuk melakukan aktivitas bersama. Terkadang seseorang ingin berolahraga, mencari teman belajar, menghadiri acara, atau sekadar nongkrong, tetapi tidak memiliki teman dengan minat dan waktu yang sama.

Barengin hadir sebagai platform yang mempertemukan pengguna melalui aktivitas bersama.

**Tujuan utama Barengin:**
- Mempermudah pengguna menemukan aktivitas yang sesuai dengan minat.
- Membantu pengguna menemukan teman baru.
- Menyediakan ruang untuk membuat dan membagikan aktivitas.
- Memfasilitasi interaksi antara penyelenggara aktivitas (Host) dan peserta.
- Mendorong terbentuknya komunitas dan interaksi sosial yang positif.

## 3. Main Features

Beberapa fitur utama yang dikembangkan dalam Barengin meliputi:

| Fitur | Deskripsi |
|---|---|
| Authentication | Registrasi dan login pengguna. |
| Personalization | Pengaturan profil dan minat pengguna. |
| Activity Discovery | Menjelajahi berbagai aktivitas yang tersedia. |
| Activity Categories | Menemukan aktivitas berdasarkan kategori. |
| Activity Creation | Membuat dan mempublikasikan aktivitas baru. |
| Join Activity | Mengirim permintaan untuk bergabung ke aktivitas. |
| Host Management | Mengelola aktivitas dan permintaan peserta. |
| Favorites | Menyimpan aktivitas yang disukai. |
| Profile Management | Melihat dan mengelola informasi profil. |
| Safety Features | Fitur pendukung keamanan dan kenyamanan pengguna. |

*Catatan: Implementasi dan penyempurnaan fitur masih berlangsung.*

## 4. Technology Stack

### Frontend
- **Flutter** — Framework pengembangan aplikasi.
- **Dart** — Bahasa pemrograman frontend.
- Material Design — Komponen antarmuka aplikasi.

### Backend
- **Laravel** — Framework backend dan REST API.
- **PHP** — Bahasa pemrograman backend.
- Composer — Dependency management.

### Database & Development Tools
- MySQL / SQLite — Database sesuai konfigurasi environment.
- XAMPP / Laragon — Lingkungan pengembangan lokal.
- Postman — Pengujian API.
- Git & GitHub — Version control dan kolaborasi.

## 5. Project Structure

Repository ini menggabungkan frontend dan backend dalam satu project.

```text
Barengin/
│
├── Barengin_Backend/
│   ├── app/
│   │   ├── Http/
│   │   │   ├── Controllers/
│   │   │   ├── Requests/
│   │   │   └── Resources/
│   │   ├── Models/
│   │   ├── Policies/
│   │   └── Services/
│   │
│   ├── bootstrap/
│   ├── config/
│   ├── database/
│   │   └── migrations/
│   ├── docs/
│   ├── routes/
│   ├── tests/
│   ├── composer.json
│   └── README.md
│
├── Barengin_Frontend/
│   ├── android/
│   ├── assets/
│   │   └── design_reference/
│   ├── docs/
│   ├── lib/
│   │   ├── core/
│   │   ├── models/
│   │   ├── screens/
│   │   ├── state/
│   │   ├── theme/
│   │   ├── utils/
│   │   └── widgets/
│   ├── web/
│   ├── pubspec.yaml
│   └── README.md
│
├── postman/
├── .postman/
├── .gitignore
└── README.md
```

## 6. Installation & Setup

### Prerequisites

Pastikan perangkat pengembangan sudah memiliki:

- Git
- Flutter SDK
- Dart SDK
- PHP 8.4+
- Composer
- MySQL atau SQLite
- Android Studio atau Visual Studio Code

### A. Clone Repository

```bash
git clone https://github.com/Alpmngks310/Barengin.git
```

Masuk ke direktori project:

```bash
cd Barengin
```

### B. Setup Backend (Laravel)

Masuk ke folder backend:

```bash
cd Barengin_Backend
```

Install dependency:

```bash
composer install
```

Buat file environment:

```bash
cp .env.example .env
```

Pada Windows PowerShell, gunakan:

```powershell
Copy-Item .env.example .env
```

Generate application key:

```bash
php artisan key:generate
```

Selanjutnya, sesuaikan konfigurasi database pada file `.env` dengan database lokal yang digunakan.

Jalankan migration:

```bash
php artisan migrate
```

Jalankan backend:

```bash
php artisan serve
```

Secara default, Laravel dapat diakses melalui:

```text
http://127.0.0.1:8000
```

### C. Setup Frontend (Flutter)

Buka terminal baru dan masuk ke folder frontend:

```bash
cd Barengin_Frontend
```

Install dependency:

```bash
flutter pub get
```

Pastikan konfigurasi API pada frontend mengarah ke alamat backend yang sesuai dengan perangkat atau emulator yang digunakan.

Jalankan aplikasi:

```bash
flutter run
```

## 7. API & Documentation

Dokumentasi teknis tersedia di dalam repository:

**Backend Documentation**
- `Barengin_Backend/docs/ENDPOINTS.md`
- `Barengin_Backend/docs/DATABASE_MAPPING.md`
- `Barengin_Backend/docs/FLUTTER_CONTRACT.md`

**Frontend Documentation**
- `Barengin_Frontend/docs/FEATURE_MAP.md`
- `Barengin_Frontend/docs/FLUTTER_CONTRACT.md`

**API Testing**
- Koleksi Postman tersedia di folder `Barengin_Backend/docs/` dan `postman/`.

## 8. Development Workflow

Pengembangan Barengin dilakukan secara bertahap menggunakan pendekatan Agile.

Alur pengembangan:

1. Perencanaan fitur dan kebutuhan aplikasi.
2. Perancangan UI/UX.
3. Pengembangan frontend.
4. Pengembangan backend dan API.
5. Integrasi frontend dengan backend.
6. Pengujian dan perbaikan.
7. Evaluasi dan pengembangan lanjutan.

## 9. Future Development

Beberapa aspek yang dapat terus dikembangkan dalam Barengin:

- Penyempurnaan UI/UX.
- Peningkatan sistem pencarian dan filter aktivitas.
- Pengembangan fitur lokasi dan aktivitas berdasarkan area.
- Peningkatan sistem keamanan dan moderasi pengguna.
- Optimalisasi performa aplikasi.
- Pengujian menyeluruh pada berbagai perangkat.
- Pengembangan fitur sosial dan komunitas.

## 10. Repository

Source code dan perkembangan project dapat diakses melalui:

**GitHub:** https://github.com/Alpmngks310/Barengin

---

## License

Project ini masih dalam tahap pengembangan. Informasi lisensi akan ditentukan kemudian.

---

**Barengin — Find Your People, Share Your Moments.**

*Developed with Flutter & Laravel.*
