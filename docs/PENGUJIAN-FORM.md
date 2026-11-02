# Tabel Uji Form — Pengajuan Izin & Cuti (Modul Minggu 7)

Form utama TIPSEN: **Pengajuan Izin & Cuti** (5 kolom, 4 jenis input: dropdown, 2× date picker,
TextFormField, file picker). Aturan validasi diturunkan dari kriteria penerimaan Minggu 2.

## Aturan validasi per kolom

| Kolom | Input | Aturan | Pesan kesalahan |
|---|---|---|---|
| Jenis pengajuan | DropdownButtonFormField | Wajib dipilih | "Pilih jenis pengajuan" |
| Tanggal mulai | showDatePicker (firstDate −30 hari) | Wajib dipilih | "Tanggal mulai wajib dipilih" |
| Tanggal selesai | showDatePicker (lastDate +365 hari) | Wajib; ≥ tanggal mulai | "Tanggal selesai wajib dipilih" / "Tanggal selesai tidak boleh lebih awal" |
| Alasan | TextFormField | Wajib; minimal 10 karakter | "Alasan wajib diisi (minimal 10 karakter)" |
| Lampiran | FilePicker (opsional) | PDF/JPG/PNG; maksimal 700 KB | "Format belum didukung" / "Melebihi batas 700 KB" |

## Tabel uji (5 kasus)

| No | Kasus uji | Data masukan | Hasil yang diharapkan | Hasil nyata |
|---|---|---|---|---|
| 1 | Semua kolom kosong | Kirim tanpa mengisi apa pun | Pesan kesalahan muncul di setiap kolom wajib | Sesuai — bukti: `docs/pengajuan-validasi.png` |
| 2 | Alasan terlalu pendek | alasan: "cuti" (4 karakter) | Pesan minimal 10 karakter muncul di kolom Alasan | Sesuai |
| 3 | Tanggal terbalik | mulai 10 Nov, selesai 5 Nov | Ditolak: "Tanggal selesai tidak boleh lebih awal" | Sesuai |
| 4 | Lampiran tidak sesuai aturan | berkas .gif berukuran 900 KB | Ditolak: format belum didukung / melebihi batas 700 KB | Sesuai |
| 5 | Semua data valid | jenis, tanggal urut, alasan ≥10 karakter | Toast hijau berhasil; data tampil di Riwayat dan Persetujuan HC | Sesuai — bukti: `docs/pengajuan-berhasil.png` |

Selain validasi form, Clock In/Out menerapkan validasi sisi sistem: cek radius geofence
kantor lewat GPS dan wajibnya selfie sebelum presensi tercatat.
