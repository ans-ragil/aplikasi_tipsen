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

## Status: ✅ FASE 1–9 + 11 SELESAI + AUDIT & PERBAIKAN MENYELURUH — siap demo

| # | Fase | Ruang lingkup | Status |
|---|------|---------------|--------|
| 1 | Fondasi | Theme navy #263858, komponen inti, model data, state | ✅ Selesai |
| 2 | Login | Brand mark, validasi kredensial nyata, toggle sandi, lupa sandi | ✅ Selesai |
| 3 | Shell navigasi | Bottom nav 4 tab + frame terpusat di Chrome | ✅ Selesai |
| 4 | Beranda | Hero jam real-time, statistik bulan berjalan, menu cepat | ✅ Selesai |
| 5 | Presensi | Kamera asli + GPS/geofence asli, Clock In/Out + durasi | ✅ Selesai |
| 6 | Riwayat | Filter periode bulan + status, pengelompokan, unduh CSV | ✅ Selesai |
| 7 | Pengajuan Izin | Form + unggah berkas asli (PDF/JPG/PNG) + detail | ✅ Selesai |
| 8 | Profil | Info akun, Ubah Kata Sandi, Bantuan, Tentang, logout | ✅ Selesai |
| 9 | Verifikasi | `flutter analyze` bersih + `flutter build web` sukses | ✅ Selesai |
| 11 | Web Admin | 7 halaman HC Portal (termasuk Profil & Pengaturan) | ✅ Selesai |
| 13 | Audit menyeluruh | 38 catatan + 9 temuan baru → semua diperbaiki & diuji E2E | ✅ Selesai |
| 14 | Audit responsif tablet | 600/900/1200 px → 4 masalah tata letak diperbaiki | ✅ Selesai |
| 15 | Persiapan Firebase | `firebase.json`, `firestore.rules`, index, `PANDUAN-FIREBASE.md` | ✅ Selesai |
| 16 | Redesign web karyawan | Bingkai ponsel → sidebar + topbar + konten 2 kolom | ✅ Selesai |
| 17 | Foto profil | Unggah/kirim ulang/hapus foto untuk karyawan & HC | ✅ Selesai |
| 10 | Firebase | Auth email/password + Firestore — **butuh kredensial project Firebase Anda** | ⏸ Menunggu user |
| 12 | Deploy | Firebase Hosting + repo GitHub remote — **butuh akun/CLI login** | ⏸ Menunggu user |

> Rincian lengkap 47 perbaikan (bukti + akar masalah) ada di **`CATATAN-PERBAIKAN.md`**.
> Panduan memakai aplikasi (untuk demo/sidang): **`PANDUAN-PENGGUNAAN.md`**.
> Panduan fase Firebase langkah demi langkah: **`PANDUAN-FIREBASE.md`**.

## Akun demo

| Peran | Email | Kata sandi |
|-------|-------|------------|
| Karyawan | `anisa@tipsen.id` | `tipsen123` |
| HC Admin | `bambang@tipsen.id` | `admin123` |

Halaman Login juga menyediakan tombol **"Isi otomatis"** untuk kedua akun.
Data (presensi, pengajuan, keputusan HC, daftar karyawan, radius geofence)
disimpan di `localStorage` (`SharedPreferences`) sehingga **tahan refresh**.


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

## Riwayat perbaikan (26 Okt 2026, setelah uji coba user)

| Masalah yang dilaporkan | Penyebab | Perbaikan |
|---|---|---|
| Tabel admin tumpang tindih (teks kolom menimpa kolom lain) | Sel tabel memakai lebar sama tanpa pemotongan teks | `AdminTable` ditulis ulang: lebar kolom berbobot (`flex`), tiap sel di-`ClipRect` + teks `ellipsis`, baris bisa diklik |
| Tampilan hilang saat jendela diperlebar | Frame ponsel di layar lebar tidak punya tinggi terbatas | Frame diberi `height: constraints.maxHeight - 16` + latar gradien, konten tidak lagi kolaps |
| Menu selfie belum terhubung kamera | Masih simulasi klik | Ditambah paket **camera** + widget `SelfieCapture`: pratinjau kamera langsung, tombol **Ambil Foto**, hasil foto tampil & tersimpan di detail presensi; ada fallback "mode simulasi" bila izin kamera ditolak |
| Tombol "Akses Cepat" di dashboard admin hanya toast | Belum terhubung ke navigasi | Dashboard menerima `onPindahMenu` → langsung pindah ke menu Persetujuan / Tracking / Laporan |
| Baris tabel tidak responsif saat diklik | Belum ada handler | Seluruh baris Monitoring & tabel laporan bisa diklik untuk membuka detail |

> Catatan kamera di Chrome: izin kamera hanya muncul bila halaman dibuka di
> **tab browser langsung** (`http://localhost:8080`), bukan di dalam panel
> pratinjau/iframe. Bila ditolak, aplikasi otomatis menawarkan mode simulasi.

## Yang sudah bisa dicoba sekarang

1. **Login** — gunakan akun demo di atas, atau klik "Isi otomatis". Sandi salah
   akan ditolak dengan pesan jelas; tersedia alur "Lupa kata sandi?".
2. **Beranda** — jam berjalan real-time, ringkasan bulan berjalan (hadir,
   terlambat, izin, total jam kerja), menu cepat ke semua fitur.
3. **Presensi** — minta izin lokasi → kamera asli → **Ambil Foto** → Kirim
   Presensi Masuk; setelah itu muncul jam masuk, durasi berjalan, dan tombol
   **Clock Out**. Di luar radius kantor otomatis dicatat sebagai WFH.
4. **Riwayat** — pilih periode bulan (bottom sheet), filter Semua/Hadir/Izin,
   klik item untuk Detail Presensi, dan **Unduh Riwayat (CSV)**.
5. **Pengajuan Izin** — pilih tanggal, tulis alasan, **unggah lampiran asli**
   (PDF/JPG/PNG maks 700 KB, bisa Ganti/Hapus), lalu Kirim.
6. **Profil** — Ubah Kata Sandi, Bantuan & Kebijakan Privasi, Tentang Aplikasi,
   dan Keluar Akun.
7. **Portal HC** — Dashboard, Monitoring, Live Tracking & Geofence,
   Persetujuan (Setujui / Tolak + alasan), Manajemen Karyawan,
   Laporan & Ekspor (CSV + Cetak/PDF), Profil & Pengaturan.

## Verifikasi otomatis (26 Okt 2026)

Pengujian dijalankan dengan Chrome headless + Playwright pada lebar
**420 / 900 / 1440 px**, mencakup kedua POV:

| Skenario | Hasil |
|---|---|
| Login sandi salah → pesan error | ✅ |
| Clock In + selfie + geofence → durasi & status | ✅ |
| Clock Out → jam pulang & durasi kerja | ✅ |
| Riwayat: pilih periode, empty state, unduh CSV | ✅ (`tipsen-riwayat-2026-10.csv`, BOM UTF-8) |
| Pengajuan: unggah `surat-dokter.png` sungguhan | ✅ |
| Karyawan kirim → HC melihat alasan & lampiran | ✅ |
| HC tolak + alasan → karyawan melihat "Catatan dari HC" | ✅ |
| Presensi karyawan muncul di Monitoring HC | ✅ |
| Laporan HC: ekspor CSV + Cetak/PDF (`window.print`) | ✅ |
| Reload halaman → sesi & data tetap | ✅ |
| Logout (karyawan & HC) dengan konfirmasi | ✅ |
| Error runtime di console browser | **0** |


## Audit responsif tablet (26 Okt 2026, lanjutan)

Pengujian ulang pada lebar **600 / 900 / 1200 px** untuk kedua POV menemukan
4 masalah tata letak yang tidak terlihat di ukuran ponsel maupun desktop lebar:

| # | Masalah | Akar masalah | Perbaikan |
|---|---|---|---|
| 1 | Kartu statistik Dashboard & Laporan jadi sangat tinggi dan berongga di 900–1100 px | `GridView.count` dengan `childAspectRatio` — tinggi kartu ikut lebar layar | Widget baru `AdminGrid`: lebar dibagi rata, tinggi mengikuti isi, sel satu baris disamakan tinggi (`IntrinsicHeight`) |
| 2 | Tabel Monitoring terpotong di kanan pada 600 px (kolom "Lokasi" & "Aksi" hilang) | Tabel 7 kolom butuh 900 px, hanya bisa digeser horizontal | Di bawah 760 px otomatis berganti ke **daftar kartu** (nama, badge status, masuk/pulang/durasi, lokasi, tombol Detail) |
| 3 | Tabel Rekap Laporan sama terpotong | idem | idem — kartu rekap dengan badge persentase + bar kehadiran |
| 4 | Tombol menu (☰) portal HC tanpa label aksesibilitas | `IconButton` tanpa `tooltip` | Ditambah `tooltip: 'Buka menu'` |

Setelah perbaikan: **0 error runtime** pada ketiga lebar, seluruh halaman HC
tetap terbaca tanpa geser horizontal.


## Redesign web karyawan + foto profil (26 Okt 2026, lanjutan 2)

### 1. Aplikasi karyawan tidak lagi berbentuk ponsel di tengah layar

| Sebelum | Sesudah |
|---|---|
| Frame 520 px di tengah, nav bawah, konten satu kolom | **Topbar navy + sidebar 244 px + area konten maksimal 1180 px**, sama seperti portal HC |
| Tidak ada identitas produk di atas | Topbar berisi logo, jam berjalan, dan avatar pengguna |
| Semua konten menumpuk ke bawah | Beranda, Presensi, Riwayat, dan Profil memakai **dua kolom** |

Perilaku responsif: **≥ 1000 px** memakai sidebar; **< 1000 px** otomatis
kembali ke topbar + drawer + navigasi bawah, sehingga di ponsel tetap nyaman.

Tata letak baru per halaman:

| Halaman | Kolom kiri | Kolom kanan |
|---|---|---|
| Beranda | Hero jam + menu cepat 4 kartu | Ringkasan bulan (hadir, izin, total jam) |
| Presensi | Kamera selfie (380 px) + panduan 3 langkah | Waktu, ringkasan hari ini, lokasi, tombol aksi |
| Riwayat | Pemilih periode + filter + daftar catatan | Ringkasan periode, ekspor CSV, arti status |
| Profil | Kartu identitas + foto + informasi akun | Pengaturan akun + keluar |

Tambahan: panel **Aktivitas Terakhir** di Beranda (4 catatan terbaru) supaya
layar lebar tidak menyisakan ruang kosong.

### 2. Foto profil (karyawan & HC)

- Unggah lewat pemilih berkas; foto **dipotong persegi dan dikompres** menjadi
  320 × 320 JPEG (±20–40 KB) memakai paket `image` — foto kamera 3–8 MB tidak
  akan membebani penyimpanan browser.
- Bisa **ganti** dan **hapus** foto (bottom sheet dua pilihan).
- Foto tampil di **topbar**, **kartu identitas**, dan **halaman Beranda**.
- Disimpan di kunci terpisah `tipsen.foto.v1` agar penyimpanan data presensi
  tidak ikut gagal bila kuota localStorage menipis.
- Foto HC juga muncul di topbar portal HC dan halaman Profil & Pengaturan.


## Berkas kode utama

```
lib/
├── main.dart                      # gerbang sesi (Login ↔ Shell / Portal HC)
├── core/
│   ├── theme.dart                 # token warna/teks/radius + tema Material
│   ├── widgets.dart               # AppButton, AppBadge, StatCard, toast, dll.
│   ├── csv.dart                   # keCsv + unduhCsv (BOM UTF-8)
│   ├── selfie_capture.dart        # kamera asli (camera + camera_web)
│   └── berkas/
│       ├── unduh.dart             # ekspor kondisional (stub / web)
│       ├── unduh_stub.dart
│       └── unduh_web.dart         # Blob download + window.print()
├── models/models.dart             # Karyawan, Presensi, PengajuanIzin, Lampiran, Geofence
├── state/app_state.dart           # ChangeNotifier + persistensi SharedPreferences
└── screens/
    ├── login_screen.dart          ├── beranda_screen.dart
    ├── shell_screen.dart          ├── presensi_screen.dart
    ├── riwayat_screen.dart        ├── detail_presensi_screen.dart
    ├── pengajuan_screen.dart      ├── detail_pengajuan_screen.dart
    ├── profil_screen.dart         ├── ubah_sandi_screen.dart
    ├── bantuan_screen.dart        # Bantuan & Kebijakan Privasi + Tentang
    └── admin/
        ├── admin_shell.dart       # topbar + sidebar 7 menu + drawer responsif
        ├── admin_widgets.dart     # AdminPanel, AdminTable, dialog, toolbar
        ├── admin_dashboard_screen.dart
        ├── admin_monitoring_screen.dart
        ├── admin_tracking_screen.dart
        ├── admin_approval_screen.dart
        ├── admin_employees_screen.dart
        ├── admin_reports_screen.dart
        └── admin_profil_screen.dart
```

## Penyempurnaan di luar prototipe (nilai plus)

- Font Inter (google_fonts) + skala tipografi style guide
- Semua status memakai badge berteks (bukan warna saja) — aturan aksesibilitas modul 4
- **Kamera asli** (bukan simulasi) dengan fallback bila izin ditolak
- **GPS + geofence asli**: jarak ke kantor dihitung, di luar radius otomatis WFH
- **Data tahan refresh** (SharedPreferences) + fallback bila kuota penyimpanan penuh
- **Ekspor CSV nyata** (BOM UTF-8, bisa dibuka Excel) & **PDF via dialog cetak browser**
- **Unggah lampiran nyata** dengan validasi tipe & ukuran, pratinjau gambar
- **Satu sumber data** untuk karyawan & HC: pengajuan, keputusan, presensi selalu sinkron
- Analitik HC dihitung dari data (persen kehadiran, rata-rata jam masuk, grafik mingguan)
- Detail presensi menghitung durasi kerja; verifikasi selfie ditampilkan
- Konfirmasi dialog sebelum logout
- Responsif: frame ponsel terpusat di Chrome, full-width di layar sempit (< 800 px)
- Ikon PWA, favicon, dan splash screen bermerek TIPSEN
- Label aksesibilitas pada tombol ikon (mis. "Kembali")
- Widget test dasar (halaman login & validasi)

## Catatan keputusan desain

1. Warna aksi utama = navy `#263858` (bukan #2563EB prototipe).
2. Bottom nav 4 item mengikuti Figma (Beranda, Presensi, Riwayat, Profil).
3. Pengajuan Izin = halaman turunan dari Beranda (punya tombol kembali), bukan item menu.
4. Kamera & GPS memakai API perangkat sungguhan; data presensi tetap disimpan lokal
   di browser sampai fase Firebase dijalankan.
5. Penyimpanan lokal dipilih agar aplikasi bisa didemokan tanpa konfigurasi akun;
   struktur data sudah disiapkan (JSON per model) sehingga tinggal dipindah ke Firestore.


## Langkah yang butuh tindakan Anda (fase 10 & 12)

Fase 10 (Firebase) dan 12 (deploy) tidak bisa dikerjakan tanpa akses akun Anda.
**Semua berkas konfigurasi sudah disiapkan**, jadi tinggal membuat project lalu
menjalankan perintah. Panduan lengkap langkah demi langkah:
**`PANDUAN-FIREBASE.md`**.

Berkas yang sudah siap di repo:

| Berkas | Fungsi |
|---|---|
| `firebase.json` | Hosting `build/web`, rewrite SPA, header cache, rujukan rules |
| `firestore.rules` | Aturan keamanan (karyawan vs HC) — siap `firebase deploy` |
| `firestore.indexes.json` | 4 composite index untuk query presensi & pengajuan |
| `.firebaserc.example` | Salin jadi `.firebaserc` lalu isi project id |
| `PANDUAN-FIREBASE.md` | 10 langkah + peta migrasi kode + troubleshooting |

Urutan singkat:

1. **Buat project Firebase** (paket Spark/gratis) → tambahkan app **Web**:
   - Authentication → Sign-in method → **Email/Password**
   - Firestore Database → **Production mode**, lokasi `asia-southeast2`
2. **Hubungkan ke project Flutter**:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<project-id>
   flutter pub add firebase_core firebase_auth cloud_firestore
   ```
3. **Deploy aturan & index**:
   ```bash
   firebase login
   cp .firebaserc.example .firebaserc   # isi project id
   firebase deploy --only firestore:rules,firestore:indexes
   ```
4. **Buat repo GitHub** kosong bernama `aplikasi-tipsen`, lalu:
   ```bash
   git remote add origin https://github.com/<username>/aplikasi-tipsen.git
   git push -u origin main
   ```
5. Beri tahu saya setelah langkah 1–2 selesai → saya lanjutkan kode Auth +
   Firestore (mengganti penyimpanan lokal) dan deploy ke Firebase Hosting.

> **Catatan lampiran:** Firebase Storage untuk project baru mewajibkan plan
> Blaze (butuh billing account), jadi lampiran **tidak** memakai Storage.
> Lampiran disimpan sebagai `base64` di dalam dokumen pengajuan. Karena batas
> dokumen Firestore 1 MiB, batas unggah sudah diturunkan ke **700 KB**.

