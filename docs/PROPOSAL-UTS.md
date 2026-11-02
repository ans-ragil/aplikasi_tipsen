# Proposal UTS — TIPSEN: Aplikasi Presensi Online Karyawan

## 1. Identitas

| Item | Keterangan |
|------|------------|
| Nama | Anisa Ragil Saputri |
| NIM | 23.01.55.0009 |
| Kelas | A1 / A2DLC |
| Mata kuliah | Mobile and Web Application Development — UTS Pertemuan 8 |
| Judul aplikasi | TIPSEN — Aplikasi Presensi Online Karyawan (mobile + web) |
| Repository GitHub | https://github.com/ans-ragil/aplikasi_tipsen |
| Wireframe Figma | https://www.figma.com/make/lO24y140BTgqTk4yQcynmk/TIPSEN-App-Mockups |

## 2. Problem Statement

Banyak perusahaan masih mencatat kehadiran karyawan secara manual, yaitu melalui lembar
absensi kertas atau kartu hadir yang di-stamp. **Siapa yang mengalami:** karyawan sebagai
pelaku presensi harian dan tim Human Capital (HC) sebagai penanggung jawab rekapitulasi.

**Masalah yang timbul:** (1) rekap kehadiran lambat dan rawan salah karena harus
dikumpulkan dan dihitung ulang manual; (2) absensi mudah dimanipulasi, misalnya titip
absen ke rekan kerja; (3) dokumen fisik mudah hilang dan rusak; (4) HC sulit memantau
karyawan yang bekerja di luar kantor (dinas, WFH, cabang lain).

**Mengapa penting:** kehadiran adalah dasar penggajian, evaluasi kinerja, dan kepatuhan
disiplin perusahaan. Data presensi yang tidak akurat berdampak langsung pada kerugian
operasional dan ketidakadilan bagi karyawan yang hadir secara jujur.

## 3. Persona

### Persona 1 — Karyawan: Rina, Staf Administrasi (26 tahun)

- Bekerja di kantor pusat, kadang dinas luar dan WFH dua kali sebulan.
- Ingin cara absen yang cepat dari ponsel tanpa antre di mesin finger.
- Frustrasi saat rekap absensinya salah dan harus proses klaim manual ke HC.
- Terbiasa menggunakan aplikasi sehari-hari; mengharapkan antarmuka sederhana.

### Persona 2 — Human Capital: Bapak Bambang, Staf HC (41 tahun)

- Mengelola kehadiran puluhan karyawan dan memproses izin/cuti setiap minggu.
- Membutuhkan rekap cepat, akurat, dan dapat diekspor untuk penggajian.
- Sering kesulitan memverifikasi apakah karyawan luar kantor benar-benar bertugas.
- Membutuhkan alat persetujuan pengajuan yang tercatat beserta alasan keputusannya.

## 4. User Story (minimal 5)

| No | User Story | Prioritas |
|----|-----------|-----------|
| 1 | Sebagai **karyawan**, saya ingin melakukan Clock In/Clock Out dengan foto selfie dan validasi lokasi GPS, sehingga kehadiran saya sah dan tidak dapat dititipkan ke rekan kerja. | Must |
| 2 | Sebagai **karyawan**, saya ingin melihat riwayat presensi pribadi, sehingga saya dapat memastikan catatan kehadiran saya benar setiap saat. | Should |
| 3 | Sebagai **karyawan**, saya ingin mengajukan izin/cuti secara online lengkap dengan alasan dan lampiran pendukung, sehingga saya tidak perlu mengisi formulir kertas. | Should |
| 4 | Sebagai **karyawan**, saya ingin menerima keputusan persetujuan beserta alasannya di aplikasi, sehingga status pengajuan saya transparan. | Should |
| 5 | Sebagai **HC**, saya ingin memantau kehadiran karyawan secara langsung dan memproses pengajuan izin, sehingga rekap dan keputusan cepat serta terdokumentasi. | Must |
| 6 | Sebagai **HC**, saya ingin mengekspor laporan kehadiran per periode, sehingga data siap dipakai untuk penggajian dan evaluasi. | Could |

Kriteria penerimaan diturunkan dari persona: contohnya user story 3 menghasilkan aturan
validasi form (jenis wajib dipilih, tanggal selesai ≥ tanggal mulai, alasan minimal 10
karakter, lampiran PDF/JPG/PNG maksimal 700 KB).

## 5. Kebutuhan Fungsional dan Prioritas (MoSCoW)

| Kode | Kebutuhan Fungsional | Prioritas |
|------|---------------------|-----------|
| F1 | Login email/password untuk dua peran (karyawan dan HC) | Must |
| F2 | Clock In/Clock Out dengan validasi waktu, GPS geofence radius kantor, dan foto selfie | Must |
| F3 | Beranda ringkasan status presensi hari ini | Must |
| F4 | Riwayat presensi karyawan dengan filter periode | Should |
| F5 | Pengajuan izin/cuti online (jenis, rentang tanggal, alasan, lampiran) | Should |
| F6 | Portal HC: persetujuan/penolakan pengajuan dengan alasan, sinkron dua arah | Should |
| F7 | Monitoring kehadiran real-time dan tracking geofence untuk HC | Could |
| F8 | Laporan dan ekspor data (CSV) untuk HC | Could |
| F9 | Manajemen data karyawan oleh HC | Could |
| — | Payroll, payment gateway, OTP telepon | Won't (di luar lingkup) |

Prioritas Must dipilih karena tanpa F1–F3 masalah utama (presensi tidak sah dan tidak
tercatat) tidak terpecahkan; F4–F6 melengkapi siklus pengajuan; F7–F9 adalah peningkat
efisiensi yang menyusul setelah inti stabil.

## 6. User Flow

**Alur utama karyawan (login sampai presensi selesai):**

1. Buka aplikasi → halaman **Login** → masukkan email dan kata sandi → validasi.
2. Masuk ke **Beranda** → melihat kartu status presensi hari ini dan akses cepat.
3. Ketuk menu **Presensi** → sistem mengambil posisi GPS dan menghitung jarak ke kantor.
4. Jika dalam radius geofence → ambil **selfie** → tombol Clock In aktif → tekan.
5. Presensi tercatat → muncul konfirmasi berhasil → data langsung tampil di Beranda dan Riwayat.
6. Akhir hari kerja: ulangi langkah 3–5 untuk **Clock Out**.

**Alur pengajuan izin/cuti:**

1. Dari Beranda ketuk **Ajukan Izin** → form Pengajuan terbuka.
2. Pilih jenis (izin/cuti/sakit/dinas), tanggal mulai–selesai, tulis alasan, unggah lampiran opsional.
3. Tekan Kirim → semua kolom divalidasi; bacaan salah ditolak dengan pesan per kolom.
4. Data valid tersimpan → muncul pesan status berhasil → tampil di Riwayat dan di antrian HC.
5. HC menyetujui/menolak dengan alasan → keputusan tampil kembali di sisi karyawan.

**Alur HC:** Login → Dashboard → Monitoring/Persetujuan → proses pengajuan → Laporan/ekspor.

## 7. Sitemap

**Aplikasi karyawan (mobile, navigasi 4 tab):** Beranda | Presensi | Riwayat | Profil —
dengan halaman turunan: Login, Pengajuan Izin & Cuti, Detail Presensi, Detail Pengajuan,
Ubah Kata Sandi, Bantuan (total 8 layar).

**Portal HC (web, sidebar):** Dashboard, Monitoring, Tracking Geofence, Persetujuan,
Manajemen Karyawan, Laporan + Ekspor, Profil & Pengaturan (7 halaman).

## 8. Wireframe dan Tautan Figma

Seluruh antarmuka dirancang di Figma Make: **TIPSEN-App-Mockups**
(<https://www.figma.com/make/lO24y140BTgqTk4yQcynmk/TIPSEN-App-Mockups>), mencakup
wireframe 8 layar mobile dan 7 halaman web admin. Wireframe mengikuti style guide:

| Elemen | Nilai |
|--------|-------|
| Warna primer | #263858 |
| Latar / border | #F4F7FB / #D1D9E6 |
| Status | hijau #16A34A, oranye #F59E0B, merah #DC2626 (selalu disertai teks) |
| Tipografi | judul 24, subjudul 18, isi 14–16, keterangan 12 |
| Komponen | tombol radius 8 px tinggi ≥48 px, margin 16 px, jarak kelipatan 8 |
| Responsif | breakpoint 600 px; web karyawan 1000 px, admin 940 px |

Kesesuaian wireframe dengan aplikasi diverifikasi pada pertemuan 6 (uji teman) dan
dibuktikan lewat screenshot pada README repository.

## 9. Tech Stack

| Komponen | Fungsi |
|----------|--------|
| Flutter + Dart (Material 3) | Aplikasi mobile dan web dari satu basis kode |
| Provider | Manajemen state (AppState) |
| Kamera (camera/camera_web) | Selfie presensi |
| Geolokasi | Validasi GPS geofence radius kantor |
| File picker | Unggah lampiran pengajuan (PDF/JPG/PNG ≤ 700 KB) |
| Shared Preferences | Penyimpanan lokal fase prototype (struktur data JSON siap migrasi) |
| Firebase Authentication (email/password) | Login dua peran — fase Pertemuan 9–15 |
| Cloud Firestore | Penyimpanan data terpusat — fase Pertemuan 9–15 |
| Firebase Hosting (paket Spark) | Publikasi versi web — fase Pertemuan 9–15 |
| GitHub | Repositori dan riwayat commit bertahap |
| Figma | Perancangan wireframe dan style guide |

## 10. Rancangan Database Firestore

Empat koleksi mengikuti kebutuhan bisnis presensi (nama field memakai bahasa Indonesia
agar konsisten dengan kode aplikasi):

### 10.1 `users/{uid}` — profil dan peran

| Field | Tipe | Keterangan |
|-------|------|------------|
| nama, email | string | identitas karyawan |
| jabatan, departemen | string | data kepegawaian |
| jadwal | string | jadwal kerja |
| peran | string | `karyawan` atau `admin` |
| aktif | boolean | status kepegawaian |

### 10.2 `presensi/{autoId}` — catatan kehadiran per hari

| Field | Tipe | Keterangan |
|-------|------|------------|
| uid | string | pemilik catatan |
| tanggal | timestamp | hari presensi |
| status | string | `hadir` / `terlambat` / `wfh` / `izinDisetujui` |
| clockIn, clockOut | string/null | jam `HH:mm` |
| lokasiNama, jarakMeter, dalamRadius | string/number/boolean | bukti geofence |
| selfie | string | referensi foto |
| keterangan | string | catatan tambahan |

### 10.3 `pengajuan_izin/{autoId}` — pengajuan dan keputusan

| Field | Tipe | Keterangan |
|-------|------|------------|
| uid, namaPemohon, jabatanPemohon | string | pemohon |
| jenis | string | izin/cuti/sakit/dinas |
| tanggalMulai, tanggalSelesai | timestamp | rentang pengajuan |
| alasan | string | minimal 10 karakter (validasi form) |
| status | string | `menunggu` / `disetujui` / `ditolak` |
| diajukanPada | timestamp | waktu kirim |
| diprosesOleh, diprosesPada, alasanPenolakan | string/timestamp | jejak keputusan HC |
| lampiran | map | `{nama, ukuran, tipe, base64}` — batas 700 KB karena dokumen Firestore maksimal 1 MiB |

### 10.4 `config/geofence` — konfigurasi lokasi kantor

| Field | Tipe | Keterangan |
|-------|------|------------|
| namaKantor | string | nama lokasi |
| latitude, longitude | number | titik pusat kantor |
| radiusMeter | number | radius dianggap hadir di kantor |

**Keamanan:** firestore.rules membatasi karyawan hanya pada datanya sendiri, sementara
peran admin berhak membaca dan memproses seluruh koleksi. Empat composite index sudah
disiapkan untuk daftar presensi dan pengajuan. Lampiran besar tidak memakai Firebase
Storage karena mewajibkan paket Blaze (billing), sehingga disimpan sebagai base64 di
dalam dokumen dengan batas unggah 700 KB.
