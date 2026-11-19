# Pemetaan Wireframe → Flutter

| Wireframe | Implementasi frontend |
|---|---|
| `00_Cover_Index.svg` | Identitas visual `BrandMark`, tema, warna, dan struktur navigasi aplikasi. |
| `01_Getting_Started.svg` | `AuthScreen`: welcome, login, register, konfirmasi usia 18+, persetujuan. |
| `02_Account_Setup.svg` | `ProfileEditScreen`: foto, nama tampilan, bio, kota/area, dan pilihan minat 3–6. |
| `03_Personalization_Home.svg` | `HomeTab`: sapaan, search entry, kategori, rekomendasi aktivitas, CTA buat aktivitas. |
| `04_Discovery.svg` | `ExploreTab`: kata kunci, kategori, area/kota, tanggal, budget, level peserta, radius GPS. |
| `05_Join_Activity.svg` | `ActivityDetailScreen`: jadwal, lokasi, kapasitas, Host, deskripsi, favorite, join request; `MyActivityTab` menampilkan status request. |
| `06_Create_Activity.svg` | `CreateActivityScreen`: form dua tahap, jadwal, venue, kapasitas, budget, opsi koordinat GPS. |
| `07_Publish_My_Activity.svg` | Review bottom sheet sebelum publish, `MyActivityTab` dengan tab Host/Member/Request. |
| `08_Host_Management.svg` | `HostManagementScreen`: persetujuan request, peserta, publish draft, start, complete, cancel, remove participant. |
| `09_Profile_Safety.svg` | `ProfileTab`, `SafetyCenterScreen`, dan `ReportScreen`. |

## Catatan status

Status aktivitas dan status permintaan bergabung ditampilkan terpisah. Kapasitas grup 2–15 orang termasuk Host. Aksi yang tersedia mengikuti endpoint dan izin yang disediakan Laravel Barengin.
