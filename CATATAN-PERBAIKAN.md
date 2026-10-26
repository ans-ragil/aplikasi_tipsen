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
