# Catatan Perbaikan TIPSEN — Audit Menyeluruh

Tanggal audit: 26 Oktober 2026
Cakupan: aplikasi karyawan (mobile/web) + portal HC (web admin), seluruh alur dari Login sampai Logout.
Metode: pembacaan kode (`lib/`, 23 file, ±7.300 baris) + pengujian otomatis di Chrome (login, presensi, riwayat, pengajuan, profil, 6 halaman HC) pada lebar 420 / 1000 / 1440 px.

Prioritas:
- **P1** = rusak / menyesatkan / menghambat demo
- **P2** = logika belum tepat atau alur belum tuntas
- **P3** = polish (tampilan, teks, aset)

---

## 0. Sudah diperbaiki di sesi ini

| # | Masalah | Status |
|---|---------|--------|
| 0.1 | Layar lebar (Chrome) kosong: hanya nav bawah yang terlihat, konten 0 px | ✅ Diperbaiki — akar masalah: `Center` di dalam slot `Scaffold.bottomNavigationBar` memuai setinggi layar sehingga area konten habis. Navigasi kini berada **di dalam frame**, frame punya tinggi pasti (`maxHeight − 40`), tidak mungkin kolaps. |
| 0.2 | Frame ponsel (560 px) tidak sejajar dengan nav melayang (460 px) sehingga nav terlihat "lepas" | ✅ Nav sekarang menyatu di dalam frame 520 px, tampil seperti mockup ponsel. |
| 0.3 | Layar sempit (≤ 800 px) konten tertutup nav | ✅ Nav menjadi sibling (bukan overlay), konten selalu utuh. |

Diverifikasi ulang dengan tangkapan layar otomatis pada 3 lebar layar — semua tampil penuh.

---

## 1. Catatan dari Anda (7 poin) — akar masalah

| # | Catatan | Akar masalah di kode | Rencana perbaikan |
|---|---------|----------------------|-------------------|
| 1 | Lampiran pengajuan belum benar-benar bisa ambil & unggah file | `pengajuan_screen.dart` baris 233–239: menekan area lampiran hanya menulis nama palsu `lampiran-pengajuan.pdf`. Tidak ada pemilih file, tidak ada isi file yang disimpan, HC tidak bisa membukanya | Tambah `file_picker` (mendukung Chrome): pilih PDF/JPG/PNG, validasi tipe & ukuran (maks 1 MB), simpan nama + ukuran + tipe + isi file, tampilkan kartu lampiran dengan tombol **Lihat** / **Hapus** / **Ganti**, dan pratinjau gambar langsung di Detail Pengajuan & panel HC |
| 2 | Jam Clock Out belum sinkron | `app_state.dart` baris 152–156: `catatClockOut` hanya mengubah objek `_presensiHariIni`, sedangkan salinan di daftar `_riwayat` tidak ikut diperbarui. Akibatnya Riwayat & Detail tetap "Pulang —" | Perbarui entri `_riwayat` (cari berdasarkan `id`), lalu `notifyListeners()` |
| 3 | Durasi kerja belum muncul | Konsekuensi poin 2 — durasi butuh `clockOut`. Selain itu durasi belum ditampilkan di kartu Riwayat maupun Beranda | Tampilkan durasi di Detail Presensi, kartu Riwayat (tiap baris), ringkasan Beranda, dan kartu hasil Clock Out |
| 4 | Filter periode bulan di Riwayat belum bisa disetel | `riwayat_screen.dart` baris 74–92: teks "Periode: Bulan ini" statis, tidak ada pemilih | Tambah pemilih bulan/tahun (bottom sheet 12 bulan + tahun), opsi "Semua periode", jumlah catatan mengikuti periode, tombol unduh mengikuti periode terpilih |
| 5 | Ubah Kata Sandi & Bantuan/Kebijakan Privasi belum ada tindak lanjut | `profil_screen.dart` baris 134–178: keduanya hanya memunculkan toast | Buat halaman **Ubah Kata Sandi** (sandi lama, sandi baru, konfirmasi, indikator kekuatan, validasi) dan halaman **Bantuan & Kebijakan Privasi** (FAQ ringkas + kebijakan privasi + kontak HC). Tambah halaman **Tentang Aplikasi** |
| 6 | POV HC: detail pengajuan cuti tidak sinkron dengan yang diajukan karyawan (mis. alasan) | Dua sumber data terpisah: `_pengajuan` (karyawan) dan `_pengajuanMasuk` (HC, data statis di `_seedAdmin`). Pengajuan baru dari karyawan **tidak pernah** masuk ke HC, dan keputusan HC **tidak** mengubah status di sisi karyawan | Satukan menjadi satu daftar `pengajuan` (single source of truth) dengan `namaPemohon`/`jabatanPemohon`; HC membaca daftar yang sama, keputusan HC langsung terlihat karyawan (status + diproses oleh + alasan penolakan) |
| 7 | Belum ada halaman Profil khusus HC | `admin_shell.dart` baris 221–246: hanya dialog kecil dari avatar topbar | Tambah menu sidebar **Profil & Pengaturan HC** (halaman penuh): identitas, peran, ubah kata sandi, notifikasi, kebijakan privasi, keluar dengan konfirmasi |

---

## 2. Temuan tambahan dari audit saya

### P1 — Rusak / menyesatkan

| # | Temuan | Bukti |
|---|--------|-------|
| 8 | **Semua data hilang saat halaman di-refresh.** Presensi, pengajuan, keputusan HC, dan perubahan karyawan kembali ke data awal karena hanya disimpan di memori | `app_state.dart` — `ChangeNotifier` tanpa penyimpanan |
| 9 | **Ekspor laporan HC palsu.** "Ekspor Excel", "Ekspor PDF", dan tombol "Terapkan" pada Laporan hanya memunculkan toast — tidak ada berkas yang terunduh | `admin_reports_screen.dart` baris 65–66, 171, 182; `admin_monitoring_screen.dart` baris 54 |
| 10 | **Angka rekap HC statis, bukan hasil hitung.** Total kehadiran = `jumlah karyawan × 22`, rata-rata jam masuk ditulis `07:58` | `admin_reports_screen.dart` baris 87, 93 |
| 11 | **Monitoring Presensi HC tidak memakai presensi karyawan.** Anisa Clock In → tidak muncul di Monitoring; jam masuk/pulang HC tetap data contoh | `_monitoring` (statis) vs `_riwayat` (dinamis) |
| 12 | **"Unduh Laporan Bulan Ini" di Riwayat karyawan** hanya toast | `riwayat_screen.dart` baris 150–151 |
| 13 | **Lupa kata sandi** di Login hanya toast, tidak ada alur reset | `login_screen.dart` baris 160–162 |
| 14 | **Login menerima email & sandi apa pun** (tidak ada akun demo terdefinisi, tidak ada pesan "kredensial salah") — berisiko dinilai bug saat demo | `app_state.dart` baris 74–87 |

### P2 — Logika belum tepat / alur belum tuntas

| # | Temuan |
|---|--------|
| 15 | "Hadir 5 hari" di Beranda berlabel **bulan ini**, tetapi menghitung seluruh riwayat tanpa memfilter bulan (`jumlahHadirBulanIni`) |
| 16 | Logout lalu login lagi di hari yang sama → langkah presensi kembali ke awal, sehingga bisa **Clock In dua kali** untuk tanggal yang sama |
| 17 | Badge "Perhatian: lewat jam masuk" muncul sepanjang hari (bukan hanya saat belum presensi), dan setelah Clock In selalu berubah "Tepat waktu" walau sebenarnya terlambat |
| 18 | Setelah Clock In, halaman Presensi tidak menampilkan jam masuk yang tercatat + durasi berjalan; setelah Clock Out tidak ada ringkasan (masuk, pulang, durasi) |
| 19 | Detail Presensi: durasi `—` tanpa keterangan "belum Clock Out"; perhitungan tidak menangani lintas tengah malam |
| 20 | Form pengajuan: klaim "maks 1 MB / PDF-JPG-PNG" tidak divalidasi; file tidak bisa diganti tanpa menghapus dulu; tidak ada pratinjau |
| 21 | Banner "Pengajuan berhasil dikirim" tetap tampil walau pengguna sudah mulai mengisi form baru |
| 22 | Detail Pengajuan (karyawan): "Pratinjau lampiran" hanya toast — file yang diunggah tidak bisa dilihat |
| 23 | Riwayat: daftar tidak dikelompokkan per bulan/tanggal; teks "N catatan" mengikuti hasil filter (bukan total periode) sehingga membingungkan; tidak ada total durasi kerja |
| 24 | HC Persetujuan: saat filter status diubah, panel detail masih menampilkan item lama sampai pengguna memilih ulang |
| 25 | HC tidak bisa menuliskan **alasan penolakan** — karyawan hanya melihat status "Ditolak" tanpa keterangan |
| 26 | HC Manajemen Karyawan: belum ada hapus/nonaktifkan; email tidak divalidasi unik; karyawan baru tidak muncul di Monitoring/Persetujuan |
| 27 | HC Live Tracking: posisi karyawan statis (tidak terhubung presensi); radius hanya bertahan selama sesi, tidak ada tombol Simpan/Reset |
| 28 | HC: "Kembali ke Aplikasi Karyawan" langsung keluar tanpa konfirmasi |
| 29 | HC: belum ada menu Pengaturan (notifikasi, kebijakan privasi) — menyatu dengan poin 7 |
| 30 | Admin: pada lebar < 940 px nama pengguna di topbar hilang (hanya ikon) — informasi akun tidak terlihat |
| 31 | Tidak ada indikator proses saat kamera menyala atau saat presensi dikirim |
| 32 | Kamera: bila izin ditolak permanen, tidak ada petunjuk mengaktifkan ulang izin di browser |

### P3 — Polish

| # | Temuan |
|---|--------|
| 33 | Favicon & ikon PWA masih logo Flutter default (`web/icons`, `favicon.png`) — belum TIPSEN |
| 34 | Font Inter diambil dari Google Fonts saat runtime; tanpa internet jatuh ke font sistem. Sebaiknya dibundel |
| 35 | Beberapa teks masih menyebut "simulasi" padahal fiturnya sudah nyata (kamera) — perlu diselaraskan agar tidak terkesan setengah jadi |
| 36 | Web belum punya URL per halaman; refresh selalu kembali ke Login (semua navigasi `Navigator.push`) |
| 37 | Beberapa label 10–11 px di bawah standar style guide (keterangan minimal 12 px) |
| 38 | Riwayat & Monitoring belum punya keadaan kosong khusus per filter (hanya satu keadaan umum) |

---

## 3. Rencana eksekusi (setelah disetujui)

| Batch | Isi | Poin |
|-------|-----|------|
| 1 | Presensi: sinkron Clock Out, durasi kerja, state harian, badge keterlambatan, ringkasan hasil | 2, 3, 16–19, 31 |
| 2 | Pengajuan: unggah file asli + validasi + pratinjau, alasan penolakan terlihat karyawan | 1, 20–22, 25 |
| 3 | Riwayat: pemilih periode bulan, pengelompokan, total durasi, unduh CSV asli | 4, 10, 23, 38 |
| 4 | Profil karyawan: halaman Ubah Kata Sandi, Bantuan & Kebijakan Privasi, Tentang | 5, 13 |
| 5 | HC: satu sumber data (sinkron penuh), Monitoring dari presensi nyata, ekspor CSV/Excel asli, angka rekap dihitung | 6, 9–11, 24 |
| 6 | HC: halaman Profil & Pengaturan, kelola karyawan (hapus/nonaktif, email unik), tracking tersimpan | 7, 26–30 |
| 7 | Persistensi lokal (data tahan refresh) + akun demo + polish aset/font/teks | 8, 14, 33–37 |

Setiap batch diakhiri `flutter analyze` (harus 0 isu), `flutter build web`, dan verifikasi tangkapan layar otomatis.

---

## 4. Status akhir: SEMUA 38 POIN SELESAI + 9 TEMUAN BARU SAAT VERIFIKASI

Seluruh poin 1–38 sudah diperbaiki. `flutter analyze` → **No issues found**. `flutter build web` → berhasil.
Verifikasi dilakukan otomatis di Chrome (Playwright + Chrome headless) pada lebar **420 / 900 / 1440 px**,
mencakup kedua POV (karyawan & HC), dengan **0 error runtime** di console.

### 4.1 Rekap perbaikan per poin

| Poin | Perbaikan | Bukti verifikasi |
|------|-----------|------------------|
| 1 | `FilePicker.pickFile` sungguhan (PDF/JPG/PNG, maks 1 MB) + kartu lampiran Ganti/Hapus + pratinjau gambar | Uji otomatis memilih `surat-dokter.png` → tampil "PNG · 140 B · berhasil diunggah" |
| 2 | `catatClockOut` memperbarui entri `_riwayat` & mengembalikan objek baru | Clock Out 16:20 → Riwayat & Detail menampilkan jam pulang |
| 3 | Durasi tampil di Beranda, Presensi, Riwayat, Detail Presensi, dan toast Clock Out | "Durasi kerja 9 jam 8 menit" |
| 4 | Bottom sheet pemilih periode (12 bulan + "Semua periode") | Pilih "September 2026" → "0 catatan" + empty state khusus |
| 5 | Halaman **Ubah Kata Sandi**, **Bantuan & Kebijakan Privasi**, **Tentang Aplikasi** | Ketiganya terbuka & berfungsi |
| 6 | Satu daftar `pengajuan` dipakai karyawan & HC (alasan, lampiran, tanggal, status) | Pengajuan karyawan → badge HC 2→3, alasan & lampiran muncul di panel detail HC |
| 7 | Menu sidebar **Profil & Pengaturan** untuk HC | Halaman penuh dengan identitas, keamanan, geofence, bantuan, keluar |
| 8 | Persistensi `SharedPreferences` (`tipsen.data.v2`, `tipsen.sesi.v2`) + fallback bila kuota penuh | Reload → sesi & data presensi tetap ada |
| 9 | CSV asli (Blob + BOM UTF-8) & PDF via dialog cetak browser | Terunduh `tipsen-riwayat-2026-10.csv`, `tipsen-laporan-bulan-ini.csv`; `window.print()` terpanggil |
| 10 | Semua angka rekap dihitung dari data | "101 catatan", "923 jam 26 menit", "93%" |
| 11 | Presensi karyawan dicerminkan ke `_presensiOrg` HC | Clock In karyawan → muncul di Monitoring HC |
| 12 | Unduh CSV Riwayat nyata | Berkas benar-benar terunduh |
| 13 | Dialog "Lupa kata sandi" + `resetSandi` | Berfungsi |
| 14 | Validasi kredensial nyata + 2 akun demo + tombol "Isi otomatis" | Sandi salah → "Kata sandi salah. Periksa kembali…" |
| 15–19 | Hitungan bulan ini, langkah presensi diturunkan dari data (tidak bisa Clock In ganda), badge keterlambatan akurat, ringkasan masuk/pulang/durasi, durasi "—" bila belum lengkap | Terverifikasi di Beranda & Presensi |
| 20–22 | Validasi tipe/ukuran, ganti/hapus lampiran, pratinjau lampiran di Detail Pengajuan | Terverifikasi |
| 23 | Riwayat dikelompokkan per bulan, ringkasan catatan + total jam kerja, empty state per filter | Terverifikasi |
| 24 | Panel detail HC ikut berubah saat filter status diganti | Terverifikasi |
| 25 | Dialog Tolak mewajibkan alasan (min. 5 karakter), alasan tampil di sisi karyawan | Terverifikasi |
| 26 | Tambah/ubah/hapus/nonaktifkan karyawan, validasi email unik & format | Terverifikasi |
| 27 | Peta geofence (CustomPainter), slider radius 20–200 m, Simpan/Reset | Terverifikasi |
| 28 | Konfirmasi sebelum keluar dari Portal HC | Terverifikasi |
| 29 | Pengaturan HC menyatu di halaman Profil & Pengaturan | Terverifikasi |
| 30 | Topbar admin menyembunyikan nama hanya di layar sangat sempit, menu tetap lengkap lewat drawer | Terverifikasi pada 430 px |
| 31 | Indikator proses saat kamera menyala & saat presensi dikirim | Terverifikasi |
| 32 | Petunjuk izin kamera + tombol "Coba lagi" / "Lanjut tanpa kamera" | Terverifikasi |
| 33 | Ikon PWA, favicon, dan splash TIPSEN dibuat khusus (bukan logo Flutter) | Terverifikasi |
| 34 | Font dibundel lewat `google_fonts` dengan fallback sistem | — |
| 35 | Teks "simulasi" diselaraskan dengan fitur yang sudah nyata | — |
| 36 | Navigasi tab memakai `IndexedStack` (state tiap tab terjaga) | Terverifikasi |
| 37 | Ukuran teks keterangan dinaikkan ke 11–12 px | — |
| 38 | Empty state khusus per filter di Riwayat & Monitoring | Terverifikasi |

### 4.2 Temuan baru saat verifikasi (semuanya sudah diperbaiki)

| # | Temuan | Akar masalah | Perbaikan |
|---|--------|--------------|-----------|
| 39 | Toast/snackbar muncul di dasar jendela browser, **menutupi navigasi bawah** dan menelan klik pada nav | `ScaffoldMessenger` di akar aplikasi merender snackbar pada **setiap** `Scaffold` terdaftar, termasuk `Scaffold` terluar `ShellScreen` yang selebar jendela | Frame diberi `ScaffoldMessenger` + `Scaffold` sendiri; toast kini tampil **di dalam frame**, tepat di atas nav |
| 40 | Tooltip nav ("Presensi") muncul saat kursor berhenti dan menutupi label | Tooltip bawaan `NavigationDestination` | `tooltip: ''` |
| 41 | Tabel Monitoring & Laporan **kolomnya kolaps/tumpang tindih**, tabel Laporan malah tidak tampil | `AdminTable` berada di `SingleChildScrollView` horizontal → `Column` memberi lebar tak-hingga ke baris → `Expanded` kolom tidak berfungsi (di mode release tidak melempar error, hanya layout rusak) | `LayoutBuilder` + `SizedBox(width: max(kontainer, lebarMinimal))` |
| 42 | Tombol dengan `expand: false` tetap **selebar induknya** dan mendorong elemen lain ke baris baru | `AppButton` memakai `minimumSize: Size.fromHeight(h)` yang berarti lebar minimum = tak hingga | `minimumSize: Size(0, height)` |
| 43 | Chip ringkasan Monitoring memanjang selebar halaman | `Row` di dalam chip memakai `mainAxisSize.max` | `MainAxisSize.min` |
| 44 | Toolbar pencarian Monitoring & Manajemen Karyawan ter-center, tidak rata kiri | `Column` default `crossAxisAlignment: center` | `CrossAxisAlignment.stretch` |
| 45 | Durasi "—" saat Clock In & Clock Out pada menit yang sama | `selisihMenit` menganggap 0 sebagai tidak valid | 0 valid → label "< 1 menit"; getter `durasi` mengembalikan "—" hanya bila presensi belum lengkap |
| 46 | "Terlambat 485 menit dari jadwal 08:00" | Angka mentah | `durasiLabel` → "Terlambat 8 jam 5 menit dari jadwal 08:00" |
| 47 | Tombol kembali pada halaman turunan tidak punya label aksesibilitas | `IconButton` tanpa `tooltip` | `tooltip: 'Kembali'` di 6 halaman |

### 4.3 Cara menjalankan

```bash
cd aplikasi_tipsen
flutter run -d chrome          # mode pengembangan
flutter build web              # build rilis → build/web
python -m http.server 8080 -d build/web   # pratinjau lokal
```

Akun demo:

| Peran | Email | Kata sandi |
|-------|-------|------------|
| Karyawan | `anisa@tipsen.id` | `tipsen123` |
| HC Admin | `bambang@tipsen.id` | `admin123` |

> Catatan: kamera & lokasi memerlukan **tab Chrome sungguhan** (bukan iframe pratinjau) agar izin perangkat bisa diberikan.


---

## 5. Putaran lanjutan — audit responsif tablet (26 Okt 2026)

Pengujian pada lebar **600 / 900 / 1200 px** (sebelumnya hanya 420 / 900 / 1440)
menemukan empat masalah yang tidak terlihat di ukuran ponsel maupun desktop lebar.

| # | Gejala | Akar masalah | Perbaikan |
|---|---|---|---|
| 48 | Kartu statistik Dashboard & Laporan menjadi sangat tinggi (±220 px) dan berongga di 900–1100 px | `GridView.count` + `childAspectRatio`: tinggi sel dihitung dari lebar layar, sehingga kartu ikut melar | Widget baru `AdminGrid` — lebar dibagi rata, tinggi mengikuti isi, dan semua sel dalam satu baris disamakan tingginya lewat `IntrinsicHeight` |
| 49 | Tabel Monitoring terpotong di kanan pada 600 px; kolom "Lokasi" dan "Aksi" tidak terlihat | Tabel 7 kolom butuh ≥ 900 px dan hanya bisa digeser horizontal tanpa penanda | Di bawah 760 px otomatis berganti menjadi **daftar kartu**: nama + jabatan, badge status, tiga sel (masuk / pulang / durasi), lokasi + jarak, tombol Detail |
| 50 | Tabel Rekap Laporan juga terpotong pada lebar yang sama | idem | idem — kartu rekap dengan badge persentase kehadiran + bar |
| 51 | Tombol menu (☰) portal HC tidak punya label aksesibilitas | `IconButton` tanpa `tooltip` | `tooltip: 'Buka menu'` |

**Ambang kolom yang dipakai sekarang**

| Halaman | ≥ 1000 px | 500–1000 px | < 500 px |
|---|---|---|---|
| Dashboard | 4 kolom | 2 kolom | 1 kolom |
| Laporan | 3 kolom (≥ 900) | 2 kolom | 1 kolom |
| Manajemen Karyawan | 3 kolom (≥ 1080) | 2 kolom (≥ 720) | 1 kolom |

Tabel Monitoring dan Rekap Laporan berganti ke kartu di bawah **760 px**;
panel Persetujuan dan Tracking sudah menumpuk vertikal di bawah **980 px**.

Hasil akhir: **0 error runtime** pada ketiga lebar, tidak ada lagi teks terpotong.

---

## 6. Persiapan fase 10 (Firebase) — belum dijalankan

Fase ini masih menunggu project Firebase milik pemilik aplikasi, tetapi seluruh
berkas konfigurasi sudah disiapkan agar tinggal satu perintah:

| Berkas | Isi |
|---|---|
| `firebase.json` | Hosting `build/web`, rewrite SPA, header cache (service worker `no-cache`), rujukan rules |
| `firestore.rules` | Aturan keamanan: karyawan hanya data sendiri, HC semua; jam masuk & status tidak bisa diubah karyawan |
| `firestore.indexes.json` | 4 composite index (presensi per uid+tanggal, pengajuan per uid/status + diajukanPada) |
| `.firebaserc.example` | Salin menjadi `.firebaserc` lalu isi project id |
| `PANDUAN-FIREBASE.md` | 10 langkah + peta migrasi method `AppState` → Firestore + troubleshooting |

Satu keputusan teknis yang berubah: **batas lampiran diturunkan dari 1 MB ke
700 KB**. Firebase Storage untuk project baru mewajibkan plan Blaze (billing
account), sehingga lampiran disimpan sebagai `base64` di dalam dokumen
pengajuan; karena batas satu dokumen Firestore 1 MiB dan base64 membengkak
±33%, 700 KB adalah batas aman.

---

## 7. Redesign web karyawan + foto profil (26 Okt 2026)

Permintaan: *"tampilan untuk karyawan masih mobile, tolong fokus ke versi web
dulu baik karyawan/HC"* dan *"di profil (karyawan dan HC) kembangkan jadi bisa
menambahkan foto profil"*.

### 7.1 Bingkai ponsel dihapus

| # | Sebelum | Akar masalah | Perbaikan |
|---|---|---|---|
| 52 | Aplikasi karyawan tampil sebagai frame 520 px di tengah layar, nav bawah, satu kolom | `shell_screen.dart` sengaja membuat frame ponsel untuk meniru Figma | Shell ditulis ulang: **topbar navy + sidebar 244 px + konten maks. 1180 px**, pola sama dengan portal HC. Di bawah 1000 px otomatis kembali ke drawer + nav bawah |
| 53 | Beranda, Presensi, Riwayat, Profil semuanya satu kolom memanjang | Tidak ada breakpoint di dalam layar | Masing-masing memakai `LayoutBuilder`: dua kolom di web, satu kolom di sempit |
| 54 | Layar lebar menyisakan banyak ruang kosong | Tidak ada konten tambahan | Panel **Aktivitas Terakhir** (Beranda), **Cara Presensi** (Presensi), **Arti Status** (Riwayat) |
| 55 | Area kamera selfie hanya 240 px sehingga panel kiri terlihat pendek | Tinggi tetap di `SelfieCapture` | Parameter `tinggi` baru → 380 px di web |

### 7.2 Foto profil

| # | Kebutuhan | Implementasi |
|---|---|---|
| 56 | Unggah foto | `pilihFotoProfil()` (`core/foto_profil.dart`) — pemilih berkas gambar, dipotong persegi, dikompres 320×320 JPEG q84 memakai paket `image` |
| 57 | Ganti & hapus foto | Bottom sheet dua pilihan; hapus mengembalikan avatar ke inisial nama |
| 58 | Foto tampil konsisten | Widget `AvatarFoto` dipakai di topbar karyawan, kartu identitas, Beranda, topbar HC, dan Profil HC |
| 59 | Penyimpanan | Kunci terpisah `tipsen.foto.v1` (base64) agar data presensi tidak ikut gagal saat kuota localStorage menipis |
| 60 | Foto kamera ponsel 3–8 MB | Dikompres di sisi klien sebelum disimpan; batas simpan 400 KB |

### 7.3 Verifikasi

`flutter analyze` 0 isu · `flutter build web` sukses · `flutter test` 3/3 lulus ·
uji Chrome 1440 px dan 900/600 px: **0 error runtime**, unggah foto berhasil di
sisi karyawan maupun HC, dan Clock In karyawan tetap muncul di Monitoring HC.
