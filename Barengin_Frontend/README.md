# BARENGIN — Flutter Frontend

**Find Your People, Make It Happen.**

Frontend Flutter untuk aplikasi Barengin. Project ini mengikuti 10 wireframe yang disertakan di `assets/design_reference/` dan menggunakan kontrak API Laravel pada `docs/FLUTTER_CONTRACT.md`.

## Arah visual

- Light mode dengan palet sage green, forest, warm cream, peach, lavender, dan lemon.
- Layout card yang rounded, hierarchy informasi jelas, tombol utama mudah ditemukan.
- Bahasa antarmuka Indonesia yang ringan, tetapi label status dan informasi penting tetap eksplisit.
- Navigasi utama: Home, Explore, Create, My Activity, Profile.

## Fitur frontend yang tersedia

### Akun dan personalisasi
- Login dan Register.
- Konfirmasi usia 18+ dan persetujuan Syarat & Privasi.
- Token Sanctum disimpan dengan `flutter_secure_storage`.
- Restore sesi ketika aplikasi dibuka kembali.
- Profil, username, display name, bio, kota/area, foto profil.
- Pilih 3–6 minat untuk personalisasi rekomendasi.

### Aktivitas
- Home dan kategori.
- Explore dengan pencarian, filter kategori/kota/tanggal/budget/level peserta, dan pencarian sekitar saya (GPS, atas tindakan pengguna).
- Detail aktivitas, favorite, request join, report, dan block Host.
- Buat aktivitas dua tahap, lokasi manual atau koordinat GPS opsional, review, lalu publish.
- My Activity: sebagai Host, sebagai Member, dan Join Requests.
- Host Management: lihat join request, approve/reject, lihat peserta, keluarkan peserta, start/complete/cancel.
- Keluar dari aktivitas sebagai Member.
- Daftar aktivitas tersimpan/favorites.

### Keamanan dan privasi
- Pusat keamanan dan daftar pengguna yang diblokir.
- Form laporan dengan alasan sesuai enum backend.
- Lokasi GPS hanya diminta ketika pengguna menekan tombol **Sekitar saya**; koordinat dikirim sebagai parameter pencarian, bukan disimpan sebagai profil.
- Respons 401 mengakhiri sesi lokal; error validasi Laravel ditampilkan melalui pesan API.

## Struktur folder

```text
Barengin_Flutter/
├── lib/
│   ├── core/          # API client, base URL, token store, location
│   ├── models/        # Model kategori, user, activity, join request
│   ├── screens/       # Auth, Home, Explore, Detail, Create, Host, Profile, Safety
│   ├── state/         # SessionController
│   ├── theme/         # Design system dan tema
│   ├── utils/         # Format tanggal, rupiah, ISO timestamp
│   └── widgets/       # Komponen UI reusable
├── assets/design_reference/  # 10 wireframe SVG dari desain awal
├── docs/              # Kontrak integrasi API
├── setup_platforms.ps1
└── pubspec.yaml
```

## Persiapan pertama di Windows

Pastikan Flutter SDK dan Android Studio/Android SDK sudah terpasang. Buka folder `Barengin_Flutter` di VS Code.

Di terminal PowerShell, jalankan satu kali:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\setup_platforms.ps1
```

Script ini membuat folder platform Android dan Web melalui Flutter CLI, menambahkan permission internet/lokasi Android, mengaktifkan HTTP cleartext untuk pengembangan lokal, dan mengatur minimum Android SDK ke 23 untuk secure storage.

Kemudian jalankan:

```powershell
flutter pub get
flutter doctor -v
```

## Menjalankan aplikasi dan Laravel

Pastikan MySQL XAMPP aktif dan backend Laravel Barengin berjalan di port 8000.

Di terminal backend:

```powershell
php artisan serve
```

Di terminal folder Flutter:

```powershell
flutter run
```

`ApiConfig` otomatis memakai:

- Android Emulator: `http://10.0.2.2:8000/api`
- Windows/Web: `http://127.0.0.1:8000/api`

### Jika memakai HP Android fisik

Laptop dan HP harus berada di jaringan Wi-Fi yang sama. Jalankan backend agar menerima koneksi LAN:

```powershell
php artisan serve --host=0.0.0.0 --port=8000
```

Lihat IP lokal laptop dengan `ipconfig`, lalu jalankan Flutter menggunakan IP laptop (contoh di bawah hanya format, ganti dengan IPv4 laptopmu):

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

Pastikan Windows Firewall mengizinkan koneksi lokal ke port 8000. Jangan gunakan IP contoh secara mentah.

## Catatan integrasi

- Endpoint dan field mengikuti kontrak backend Barengin yang disertakan.
- `activities.status` (draft/published/ongoing/completed/cancelled) dan `join_requests.status` (pending/accepted/rejected) diperlakukan sebagai dua status berbeda.
- Kapasitas aktivitas 2–15 orang dan sudah termasuk Host.
- Waktu mulai dan selesai dikirim sebagai ISO-8601 beserta UTC offset perangkat.
- Avatar dikirim sebagai multipart `avatar` dengan method override PATCH agar sesuai request Laravel.
- Saat membuat aktivitas, frontend membuat draft lalu memanggil endpoint publish.

## Catatan validasi

Source frontend sudah disiapkan dan diperiksa secara statis. Lingkungan pembuat file ini tidak menyediakan Flutter/Dart CLI, sehingga `flutter pub get`, `flutter analyze`, dan build Android/Web belum dapat dijalankan di sini. Jalankan perintah tersebut setelah project diekstrak di laptop yang memiliki Flutter. Jika ada error analyzer atau respons endpoint yang berbeda, gunakan pesan error itu untuk penyesuaian integrasi berikutnya.

## Keamanan pengembangan lokal

Manifest Android mengizinkan HTTP cleartext agar dapat terhubung ke server Laravel lokal. Untuk rilis produksi, gunakan HTTPS dan nonaktifkan `usesCleartextTraffic`.
