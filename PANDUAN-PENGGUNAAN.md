# Panduan Penggunaan TIPSEN

TIPSEN adalah aplikasi presensi karyawan berbasis web (Chrome) dengan dua
antarmuka dalam satu aplikasi:

- **Aplikasi Karyawan** — Clock In/Out dengan selfie dan validasi lokasi,
  riwayat presensi, pengajuan izin/cuti, profil.
- **Portal HC** — dashboard, monitoring presensi, tracking geofence,
  persetujuan izin, manajemen karyawan, laporan + ekspor.

---

## 1. Menjalankan aplikasi

### Cara cepat (mode pengembangan)

```bash
cd aplikasi_tipsen
flutter run -d chrome
```

### Cara versi rilis (yang dipakai untuk demo/sidang)

```bash
flutter build web --release
cd build/web
python -m http.server 8080
```

Lalu buka **<http://127.0.0.1:8080>** di tab Chrome biasa.

> **Penting:** buka di **tab Chrome langsung**, bukan di panel pratinjau
> editor. Kamera dan GPS diblokir di dalam iframe, sehingga tombol
> "Ambil Foto" akan menampilkan panel peringatan.

### Tata letak: web dan ponsel

Aplikasi menyesuaikan diri dengan lebar jendela:

| Lebar jendela | Tampilan |
|---|---|
| **≥ 1000 px** (web/desktop) | Topbar navy + **sidebar menu** di kiri + konten dua kolom |
| **< 1000 px** (ponsel/tablet) | Topbar + tombol ☰ (drawer) + **navigasi bawah** |

Portal HC memakai ambang 940 px untuk sidebar. Coba perkecil jendela Chrome
untuk melihat peralihannya — tidak ada konten yang terpotong di semua ukuran.

---

## 2. Akun demo

| Peran | Email | Kata sandi |
|---|---|---|
| Karyawan | `anisa@tipsen.id` | `tipsen123` |
| Admin HC | `bambang@tipsen.id` | `admin123` |

Di halaman login tersedia kotak **Akun demo** dengan tombol **Isi otomatis** —
satu klik untuk mengisi email + kata sandi, jadi tidak perlu mengetik saat
presentasi.

---

## 3. Alur karyawan

### a. Login
1. Isi email & kata sandi (atau klik **Isi otomatis**).
2. Salah ketik → muncul panel merah dengan pesan spesifik.
3. **Lupa kata sandi?** → tautan membuka dialog pemulihan.

### b. Beranda
- Jam digital berjalan real-time dan tanggal hari ini.
- Status presensi hari ini: jam masuk, jam pulang, dan durasi kerja
  (durasi ikut bertambah setiap menit selama belum Clock Out).
- Ringkasan bulan: jumlah **Hadir** dan **Terlambat**.
- Empat menu cepat: **Presensi**, **Riwayat**, **Ajukan Izin**, **Profil**.

### c. Presensi (Clock In)
1. Tab **Presensi** → tekan **Ambil Foto** dan izinkan akses kamera.
   Jika kamera tidak tersedia, gunakan **Lanjut tanpa kamera**.
2. Tekan **Minta Izin Lokasi** → browser meminta izin; setujui.
   Kartu lokasi menampilkan nama kantor, jarak, dan status
   **Dalam Radius** / **Di Luar Radius**.
3. Tekan **Kirim Presensi Masuk**. Muncul konfirmasi berisi jam masuk dan
   status (Tepat waktu / Terlambat / WFH).

### d. Presensi (Clock Out)
Kembali ke tab **Presensi**, lalu tekan **Kirim Presensi Pulang**. Setelah itu
kartu ringkasan menampilkan **jam pulang** dan **durasi kerja total**.

### e. Riwayat
- Tombol periode di kanan atas → pilih **bulan tertentu** atau
  **Semua periode**.
- Filter cepat: **Semua / Hadir / Izin / Terlambat**.
- Daftar dikelompokkan per bulan, dengan ringkasan **jumlah hari** dan
  **total jam kerja**.
- Tombol **Ekspor CSV** mengunduh berkas yang bisa langsung dibuka di Excel.
- Klik satu baris → **Detail Presensi** (jam masuk/pulang, durasi, lokasi,
  jarak, foto selfie).

### f. Pengajuan izin/cuti
1. Dari Beranda → **Ajukan Izin**.
2. Pilih jenis (Cuti Tahunan / Izin Sakit / Izin Keperluan Pribadi),
   tanggal mulai & selesai, lalu tulis alasan (minimal 10 karakter).
3. **Lampiran** (opsional): PDF/JPG/PNG maksimal 700 KB.
   Setelah terunggah muncul kartu berkas dengan tombol **Ganti** dan **Hapus**.
4. **Kirim Pengajuan** → status awal **Menunggu**.
5. Buka detailnya di Riwayat → tab **Pengajuan** untuk melihat status dan,
   bila ditolak, **Catatan dari HC**.

### g. Profil
- **Foto profil**: klik avatar (ada ikon kamera kecil) atau tombol **Tambah/Ganti
  Foto** → pilih gambar dari perangkat. Foto otomatis dipotong persegi dan
  dikecilkan, lalu muncul di topbar dan Beranda. Untuk menghapus, klik avatar
  lagi → **Hapus foto profil**.
- Ubah kata sandi, notifikasi, Bantuan & Kebijakan Privasi, Tentang Aplikasi,
  dan **Keluar Akun**.

---

## 4. Alur Portal HC

Masuk dengan `bambang@tipsen.id`. Sidebar berisi tujuh menu:

| Menu | Isi |
|---|---|
| **Dashboard** | Jumlah masuk, terlambat, izin, belum presensi hari ini; grafik kehadiran mingguan; daftar presensi terbaru |
| **Monitoring Presensi** | Tabel seluruh karyawan hari ini + pencarian, filter status, ekspor CSV, klik baris untuk detail |
| **Live Tracking & Geofence** | Peta kantor, radius geofence yang bisa diatur (slider 20–200 m), daftar posisi karyawan |
| **Persetujuan** | Daftar pengajuan menunggu; **Setujui** langsung, atau **Tolak** dengan alasan wajib ≥ 5 karakter |
| **Manajemen Karyawan** | Tambah/edit karyawan (validasi email unik), aktif/nonaktifkan, hapus |
| **Laporan & Ekspor Data** | Filter periode & departemen, statistik kehadiran, rekap per karyawan, ekspor CSV, **Cetak / PDF** |
| **Profil & Pengaturan** | Identitas HC (termasuk **foto profil**), ubah sandi, pengaturan geofence, bantuan, keluar |

### Sinkronisasi dua arah
Pengajuan yang dikirim karyawan **langsung** muncul di menu Persetujuan
lengkap dengan alasan, tanggal, dan lampirannya. Begitu HC menekan
**Tolak** dan menulis alasan, karyawan melihat catatan itu di detail
pengajuannya. Presensi karyawan juga langsung tercatat di Monitoring HC.

---

## 5. Yang nyata vs yang disimulasikan

| Fitur | Status |
|---|---|
| Login & validasi kredensial | Nyata (akun demo di atas) |
| Kamera selfie | Nyata — memakai kamera perangkat lewat `camera` + `camera_web` |
| GPS & geofence | Nyata — `geolocator`-style API browser, radius dihitung terhadap koordinat kantor |
| Unggah lampiran | Nyata — pemilih berkas asli, isi berkas ikut tersimpan |
| Foto profil | Nyata — dipotong persegi & dikompres jadi 320×320 JPEG di browser |
| Ekspor CSV | Nyata — Blob + BOM UTF-8, terbuka rapi di Excel |
| PDF | Nyata — dialog cetak Chrome (**Save as PDF**) |
| Penyimpanan data | `SharedPreferences` browser — **tahan refresh**, tetapi hanya di perangkat itu |
| Data lintas perangkat | Belum — menunggu fase Firebase (`PANDUAN-FIREBASE.md`) |

---

## 6. Skenario demo 3 menit (urutan yang paling meyakinkan)

1. **Login karyawan** dengan tombol *Isi otomatis* → tunjukkan jam berjalan.
2. **Clock In**: ambil selfie → izinkan lokasi → kirim. Tunjukkan toast
   berisi jam masuk.
3. **Clock Out** → tunjukkan **durasi kerja** muncul.
4. **Riwayat** → ganti periode → tunjukkan ringkasan jam → **Ekspor CSV**,
   buka berkasnya di Excel.
5. **Ajukan Izin** dengan lampiran → kirim.
6. **Keluar**, lalu **login HC** → buka **Persetujuan** → tunjukkan pengajuan
   tadi sudah masuk dengan alasan + lampiran → **Tolak** dengan alasan.
7. Kembali **login karyawan** → buka detail pengajuan → tunjukkan
   **Catatan dari HC**. Ini yang membuktikan datanya satu, bukan dua aplikasi
   terpisah.
8. Tutup dengan **Laporan & Ekspor** → ekspor CSV lalu **Cetak / PDF**.

---

## 7. Reset data demo

Data tersimpan di `localStorage` browser. Untuk mengembalikan ke kondisi awal:

1. Buka Chrome DevTools (F12) → tab **Application** → **Local Storage** →
   `http://127.0.0.1:8080` → hapus dua kunci `tipsen.data.v2` dan
   `tipsen.sesi.v2`.
2. Refresh halaman. Data contoh akan dibuat ulang otomatis.

Atau lebih cepat: jalankan di jendela **Incognito** baru.

---

## 8. Pertanyaan yang sering muncul saat presentasi

**"Datanya hilang kalau browser ditutup?"**
Tidak. Data disimpan di `SharedPreferences` (localStorage), jadi bertahan
setelah refresh maupun menutup browser. Yang belum ada adalah sinkronisasi
antar perangkat — itu masuk fase Firebase.

**"Kenapa tidak pakai Firebase sejak awal?"**
Karena fase Firebase memerlukan project & akun Firebase milik pemilik aplikasi.
Supaya aplikasi tetap bisa diuji sejak awal, penyimpanan dibuat di lapisan
`AppState` yang terpisah, sehingga penggantian ke Firestore tidak mengubah
satu pun halaman tampilan.

**"Bagaimana mencegah karyawan memalsukan presensi?"**
Ada tiga lapis: validasi radius geofence terhadap koordinat kantor, selfie
sebagai bukti kehadiran, dan (setelah Firebase) aturan keamanan yang melarang
karyawan mengubah jam masuk atau status presensinya sendiri.

**"Kalau dua orang Clock In bersamaan?"**
Setiap karyawan hanya punya satu dokumen presensi per tanggal; tombol Clock In
otomatis berubah menjadi Clock Out setelah tercatat, dan status dibaca dari
data (bukan dari variabel sementara), sehingga tidak bisa tercatat dua kali.
