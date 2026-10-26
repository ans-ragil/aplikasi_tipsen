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

## Status: ✅ FASE 1–9 SELESAI — aplikasi mobile karyawan siap dipakai

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
| 10 | Firebase | Auth email/password + Firestore (users, presensi, pengajuan_izin, config/geofence) | ⬜ Berikutnya |
| 11 | Web Admin | 6 halaman HC Portal (Dashboard, Monitoring, Tracking, Geofence, Persetujuan, Karyawan, Laporan) | ⬜ Belum |
| 12 | Deploy | Firebase Hosting + repo GitHub remote | ⬜ Belum |

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
    └── profil_screen.dart
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
