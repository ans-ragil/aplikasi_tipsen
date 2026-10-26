# TIPSEN — Aplikasi Presensi Online

Proyek individu mata kuliah **Mobile and Web Application Development** (Ganjil 2026/2027).
Mahasiswa: Anisa Ragil Saputri — NIM 23.01.55.0009 — Kelas A1/A2DLC.

TIPSEN adalah aplikasi presensi online karyawan berbasis **Flutter** (mobile + web) dengan
**Firebase** (Authentication email/password, Cloud Firestore, Hosting).

## Fitur inti (MVP)

- **Clock In / Clock Out** dengan validasi lokasi (GPS geofence) dan selfie
- **Riwayat presensi** karyawan
- **Pengajuan cuti/izin** secara online (Should)
- **Laporan & ekspor data** untuk admin/HC (Could)

## Teknologi

| Komponen | Fungsi |
|---|---|
| Flutter + Dart | Aplikasi mobile dan web |
| Firebase Authentication | Login email/password |
| Cloud Firestore | Penyimpanan data (CRUD) |
| Firebase Hosting | Versi web |
| GitHub | Repositori & riwayat perubahan |

> Catatan batasan proyek: tanpa billing account, Cloud Functions, OTP telepon,
> maupun payment gateway. Seluruh data menggunakan simulasi.

## Menjalankan project

```bash
flutter pub get
flutter run -d chrome   # versi web
flutter run             # pilih emulator/device
```

## Rancangan

User flow, sitemap, wireframe, dan style guide tersedia pada modul minggu 1–4
serta prototipe Figma "TIPSEN-App-Mockups".
