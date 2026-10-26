# PROGRES PENGERJAAN APLIKASI TIPSEN

> Dokumen ini diperbarui setiap satu fase selesai.
> Jika pengerjaan terhenti di tengah, lihat tabel **Status** di bawah untuk
> mengetahui persis sampai mana, lalu cukup bilang: *"lanjutkan dari fase X"*.
>
> Acuan desain: `design-figma/ANALISIS-DESAIN.md` (ekspor Figma Make).
> Warna aksi utama: **navy #263858** (disetujui pemilik proyek, 26 Okt 2026).

## Cara menjalankan (Chrome/web)

```bash
cd D:/KULIAH/smt7/tipsen/aplikasi_tipsen
D:/KULIAH/smt7/tipsen/dev/flutter/bin/flutter.bat run -d chrome
```

Alternatif tanpa Flutter: build web sudah tersedia di folder `build/web`,
bisa dibuka dengan server statis apa pun.

## Status: ✅ FASE 1–9 + 11 SELESAI — aplikasi karyawan & web admin siap demo

| # | Fase | Ruang lingkup | Status |
|---|------|---------------|--------|
| 1 | Fondasi | Theme navy #263858, komponen inti, model data, state simulasi | ✅ Selesai |
| 2 | Login | Brand mark, validasi inline, toggle sandi, toast | ✅ Selesai |
| 3 | Shell navigasi | Bottom nav 4 tab + frame terpusat di Chrome | ✅ Selesai |
| 4 | Beranda | Hero jam real-time, stat Hadir/Izin, menu cepat | ✅ Selesai |
| 5 | Presensi | Selfie + GPS simulasi, state machine Clock In/Out | ✅ Selesai |
| 6 | Riwayat | Filter Semua/Hadir/Izin, daftar, Detail Presensi | ✅ Selesai |
| 7 | Pengajuan Izin | Form + validasi + lampiran simulasi, Detail Pengajuan | ✅ Selesai |
| 8 | Profil | Info akun, pengaturan, logout | ✅ Selesai |
| 9 | Verifikasi | `flutter analyze` bersih + `flutter build web` sukses | ✅ Selesai |
| 11 | Web Admin | 6 halaman HC Portal + sidebar + topbar + modal | ✅ Selesai |
| 10 | Firebase | Auth email/password + Firestore — **butuh kredensial project Firebase Anda** | ⏸ Menunggu user |
| 12 | Deploy | Firebase Hosting + repo GitHub remote — **butuh akun/CLI login** | ⏸ Menunggu user |

## Web Admin (HC Portal) — fase 11

Akses: halaman Login → tombol **"Masuk sebagai HC Admin (Demo)"**.

| Halaman | Isi |
|---|---|
| Dashboard Admin | 4 kartu statistik, grafik bar kehadiran, akses cepat, aktivitas terbaru, informasi penting |
| Monitoring Presensi | Tabel log presensi + pencarian + filter status + modal detail (bukti selfie) |
| Live Tracking & Geofence | Peta simulasi gelap, lingkaran geofence yang membesar mengikuti slider radius 20–200 m, pin kantor & karyawan, daftar status posisi |
| Persetujuan Cuti & Izin | Filter status, daftar pengajuan dengan aksi inline Setujui/Tolak, panel detail + lampiran |
| Manajemen Karyawan | Pencarian, filter status, grid kartu, modal detail, modal tambah/edit dengan validasi |
| Laporan & Ekspor Data | Filter periode/status, 3 kartu ringkasan, tabel rekap dengan progress %, modal rincian, tombol ekspor Excel/PDF |

## Yang sudah bisa dicoba sekarang

1. **Login** — email apa pun berformat valid (contoh `anisa@tipsen.id`) + sandi bebas.
2. **Beranda** — jam berjalan real-time; tombol hero mengikuti status presensi.
3. **Presensi** — minta izin lokasi → ambil selfie (klik area gelap) → Kirim Presensi Masuk;
   coba juga "Simulasi: pindah ke luar radius" untuk melihat pencatatan WFH.
4. **Riwayat** — filter Semua / Hadir / Izin; klik item untuk detail.
5. **Pengajuan** (menu cepat di Beranda) — isi form, validasi alasan min. 10 karakter.
6. **Profil** — logout mengembalikan ke halaman Login.

## Berkas kode utama

```
lib/
├── main.dart                      # gerbang sesi (Login ↔ Shell)
├── core/theme.dart                # token warna/teks/radius + tema Material
├── core/widgets.dart              # AppButton, AppBadge, StatCard, toast, dll.
├── models/models.dart             # Karyawan, Presensi, PengajuanIzin, Geofence
├── state/app_state.dart           # ChangeNotifier: sesi, presensi, data simulasi
└── screens/
    ├── login_screen.dart          ├── beranda_screen.dart
    ├── shell_screen.dart          ├── presensi_screen.dart
    ├── riwayat_screen.dart        ├── detail_presensi_screen.dart
    ├── pengajuan_screen.dart      ├── detail_pengajuan_screen.dart
    ├── profil_screen.dart
    └── admin/
        ├── admin_shell.dart       # topbar + sidebar 6 menu + drawer responsif
        ├── admin_widgets.dart     # AdminPanel, AdminTable, dialog, toolbar
        ├── admin_dashboard_screen.dart
        ├── admin_monitoring_screen.dart
        ├── admin_tracking_screen.dart
        ├── admin_approval_screen.dart
        ├── admin_employees_screen.dart
        └── admin_reports_screen.dart
```

## Penyempurnaan di luar prototipe (nilai plus)

- Font Inter (google_fonts) + skala tipografi style guide
- Semua status memakai badge berteks (bukan warna saja) — aturan aksesibilitas modul 4
- Data simulasi realistis (6 catatan presensi + 2 pengajuan) & empty state
- Detail presensi menghitung durasi kerja; verifikasi selfie ditampilkan
- Konfirmasi dialog sebelum logout
- Responsif: frame ponsel terpusat di Chrome, full-width di layar sempit
- 2 widget test dasar (halaman login & validasi)

## Catatan keputusan desain

1. Warna aksi utama = navy `#263858` (bukan #2563EB prototipe).
2. Bottom nav 4 item mengikuti Figma (Beranda, Presensi, Riwayat, Profil).
3. Pengajuan Izin = halaman turunan dari Beranda (punya tombol kembali), bukan item menu.
4. Selfie & GPS masih simulasi; kamera/GPS asli menyusul bersama fase Firebase.
5. Data disimpan di memori (hilang saat refresh) sampai fase Firebase.

## Langkah yang butuh tindakan Anda (fase 10 & 12)

Fase 10 (Firebase) dan 12 (deploy) tidak bisa saya kerjakan tanpa akses akun Anda.
Urutan yang disarankan:

1. **Buat project Firebase** (paket Spark/gratis) di console.firebase.google.com →
   tambahkan app **Web**, lalu aktifkan:
   - Authentication → Sign-in method → **Email/Password**
   - Firestore Database → buat database (mode uji coba)
2. **Hubungkan ke project Flutter**:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   (pilih project Firebase yang baru dibuat, platform web/android)
3. **Buat repo GitHub** kosong bernama `aplikasi-tipsen`, lalu:
   ```bash
   git remote add origin https://github.com/<username>/aplikasi-tipsen.git
   git push -u origin main
   ```
4. Beri tahu saya setelah langkah 1–2 selesai → saya lanjutkan kode Auth + Firestore
   (mengganti data simulasi) dan deploy ke Firebase Hosting.

