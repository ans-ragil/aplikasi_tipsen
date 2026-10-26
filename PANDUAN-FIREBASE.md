# Panduan Fase 10 — Menyambungkan TIPSEN ke Firebase

Dokumen ini adalah panduan langkah demi langkah untuk memindahkan penyimpanan
TIPSEN dari `SharedPreferences` (lokal browser) ke **Firebase Authentication +
Cloud Firestore**. Semua berkas konfigurasi sudah disiapkan di repo ini, jadi
kamu hanya perlu membuat project lalu menjalankan beberapa perintah.

> **Kenapa sekarang pakai data lokal?**
> Supaya aplikasi bisa didemokan di Chrome tanpa akun Firebase. Struktur datanya
> sudah 100% siap dipindah — model, JSON, dan aturan keamanan sudah disamakan.

---

## 0. Yang sudah disiapkan (jangan diubah dulu)

| Berkas | Isi |
|---|---|
| `firebase.json` | Konfigurasi Hosting (`build/web`), rewrite SPA, header cache, dan rujukan rules |
| `firestore.rules` | Aturan keamanan siap deploy: karyawan hanya data sendiri, HC boleh semua |
| `firestore.indexes.json` | 4 composite index yang dibutuhkan daftar presensi & pengajuan |
| `.firebaserc.example` | Contoh penunjuk project id (salin jadi `.firebaserc`) |

---

## 1. Buat project Firebase (paket Spark / gratis)

1. Buka <https://console.firebase.google.com> → **Add project**.
2. Nama project: `tipsen-app` (atau apa pun; id-nya nanti dipakai di `.firebaserc`).
3. Google Analytics: **boleh dimatikan** (tidak dipakai, lebih cepat).
4. Pastikan plan tetap **Spark (no cost)** — jangan upgrade ke Blaze.

> Batasan proyek: tanpa billing account, tanpa Cloud Functions, tanpa OTP
> telepon, tanpa payment gateway. Semua fitur di bawah ini masih aman di Spark.

---

## 2. Aktifkan Authentication

1. Menu **Build → Authentication → Get started**.
2. Tab **Sign-in method** → aktifkan **Email/Password** (yang pertama saja,
   *Email link* tidak perlu).
3. Tab **Users** → **Add user**, buat dua akun demo:

| Email | Password | Peran |
|---|---|---|
| `anisa@tipsen.id` | `tipsen123` | karyawan |
| `bambang@tipsen.id` | `admin123` | admin HC |

> Catat **UID** kedua user ini (kolom User UID) — dipakai di langkah 6.

---

## 3. Aktifkan Cloud Firestore

1. Menu **Build → Firestore Database → Create database**.
2. Lokasi: **asia-southeast2 (Jakarta)** — paling dekat, latensi rendah.
3. Mode: **Production mode** (rules akan kita deploy sendiri, lebih ketat
   daripada test mode).
4. Setelah dibuat, jalankan deploy rules di langkah 5.

### Struktur koleksi yang dipakai

```
users/{uid}
  nama, jabatan, departemen, email, jadwal,
  peran: 'karyawan' | 'admin', aktif: true

presensi/{autoId}
  uid, tanggal (timestamp), status: 'hadir'|'terlambat'|'wfh'|'izinDisetujui',
  clockIn: 'HH:mm' | null, clockOut: 'HH:mm' | null,
  lokasiNama, jarakMeter, dalamRadius, selfie, keterangan

pengajuan_izin/{autoId}
  uid, namaPemohon, jabatanPemohon, jenis,
  tanggalMulai (timestamp), tanggalSelesai (timestamp),
  alasan, status: 'menunggu'|'disetujui'|'ditolak',
  diajukanPada (timestamp),
  diprosesOleh, diprosesPada, alasanPenolakan,
  lampiran: { nama, ukuran, tipe, base64 }

config/geofence
  namaKantor, latitude, longitude, radiusMeter
```

> **Catatan lampiran.** Firebase Storage untuk project baru sekarang
> mewajibkan plan Blaze (butuh billing account) — jadi lampiran **tidak**
> disimpan di Storage. Lampiran disimpan sebagai `base64` di dalam dokumen
> pengajuan. Karena batas satu dokumen Firestore adalah **1 MiB** dan base64
> membengkak ±33%, batas unggah di aplikasi sudah diturunkan menjadi
> **700 KB** (lihat `_maksUkuranLampiran` di `pengajuan_screen.dart`).

---

## 4. Daftarkan aplikasi web & jalankan `flutterfire configure`

```bash
# sekali saja, global
dart pub global activate flutterfire_cli

# dari folder aplikasi_tipsen
flutterfire configure --project=tipsen-app
```

Pilih platform **web** saat ditanya. Perintah ini menghasilkan
`lib/firebase_options.dart` dan mendaftarkan app web di console.

Lalu tambahkan dependensi:

```bash
flutter pub add firebase_core firebase_auth cloud_firestore
```

Aktifkan di `lib/main.dart`, sebelum `runApp`:

```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
runApp(const TipsenApp());
```

---

## 5. Deploy aturan keamanan & index

```bash
npm install -g firebase-tools      # sekali saja
firebase login
cp .firebaserc.example .firebaserc # lalu isi project id hasil langkah 1
firebase deploy --only firestore:rules,firestore:indexes
```

Index butuh beberapa menit untuk selesai dibangun — statusnya bisa dilihat di
tab **Indexes**.

### Ringkasan isi `firestore.rules`

| Aktor | Boleh |
|---|---|
| Belum login | tidak boleh apa pun |
| Karyawan | baca profil sendiri; baca presensi & pengajuan sendiri; buat presensi hari ini; isi jam pulang sekali; ajukan izin dengan status `menunggu` |
| Admin HC | baca semua data organisasi; putuskan pengajuan; kelola akun karyawan; ubah geofence |

Yang **sengaja dikunci**: karyawan tidak bisa mengubah jam masuk, tanggal, atau
status presensinya sendiri (mencegah durasi kerja dipalsukan), dan tidak bisa
mengubah status pengajuannya menjadi `disetujui`.

---

## 6. Isi data awal

### a. Dokumen `users` untuk dua akun demo

Di console → Firestore → **Start collection** `users` → Document ID = UID Anisa:

```json
{
  "nama": "Anisa Ragil Saputri",
  "jabatan": "Staff Administrasi",
  "departemen": "Operasional",
  "email": "anisa@tipsen.id",
  "jadwal": "Shift Pagi · 08:00–17:00",
  "peran": "karyawan",
  "aktif": true
}
```

Ulangi dengan UID Bambang:

```json
{
  "nama": "Bambang Wijaya",
  "jabatan": "HC Administrator",
  "departemen": "Human Capital",
  "email": "bambang@tipsen.id",
  "jadwal": "Shift Pagi · 08:00–17:00",
  "peran": "admin",
  "aktif": true
}
```

> `peran: "admin"` inilah yang membuka seluruh portal HC. Tanpa ini, akun hanya
> bisa memakai aplikasi karyawan.

### b. Dokumen `config/geofence`

```json
{ "namaKantor": "Kantor Pusat TIPSEN", "latitude": -6.2088, "longitude": 106.8456, "radiusMeter": 100 }
```

---

## 7. Memindahkan kode dari `SharedPreferences` ke Firestore

Semua akses data sudah terkumpul di **`lib/state/app_state.dart`**. Buat berkas
baru `lib/services/firestore_service.dart` lalu ganti isi method berikut satu
per satu — tampilan tidak perlu diubah karena semuanya memanggil `AppState`.

| Method di `AppState` | Padanan Firestore |
|---|---|
| `masuk(email, sandi)` | `FirebaseAuth.instance.signInWithEmailAndPassword` lalu baca `users/{uid}` |
| `init()` | `authStateChanges()` + `snapshots()` pada `presensi` & `pengajuan_izin` |
| `catatClockIn(...)` | `add({'uid': uid, 'tanggal': Timestamp.now(), ...})` |
| `catatClockOut(jam)` | `update({'clockOut': jam})` pada dokumen hari ini |
| `kirimPengajuan(...)` | `add({..., 'status': 'menunggu', 'diajukanPada': Timestamp.now()})` |
| `putuskanPengajuan(id, ...)` | `update({'status': ..., 'diprosesOleh': ..., 'diprosesPada': ...})` |
| `_simpan()` / `_muat()` | **hapus** — Firestore realtime menggantikannya |
| `monitoringHariIni`, `rekap()` | query `presensi where tanggal >= awalBulan` lalu agregasi di Dart (sama seperti sekarang) |

Contoh potongan yang bisa langsung dipakai:

```dart
// Ambil presensi milik user yang sedang login, terbaru dulu
final snap = await FirebaseFirestore.instance
    .collection('presensi')
    .where('uid', isEqualTo: uid)
    .orderBy('tanggal', descending: true)
    .get();

_riwayat = snap.docs.map((d) => Presensi.fromJson(d.data())).toList();
```

> Karena aplikasi ini memakai satu daftar untuk dua peran, cukup ubah `_pengajuan`
> dan `_riwayat` menjadi hasil `snapshots()` — UI karyawan dan portal HC akan
> ikut ter-update otomatis tanpa perubahan kode tampilan.

---

## 8. Deploy ke Firebase Hosting

```bash
flutter build web --release
firebase deploy --only hosting
```

Alamat hasil deploy berbentuk `https://tipsen-app.web.app`. Alamat ini yang
dikumpulkan untuk tugas akhir.

---

## 9. Jika ada masalah

| Gejala | Penyebab & solusi |
|---|---|
| `permission-denied` saat baca presensi | Dokumen `users/{uid}` belum ada atau `peran` salah tulis (harus `admin`, bukan `hc`) |
| `The query requires an index` | Jalankan `firebase deploy --only firestore:indexes`, tunggu index selesai dibangun |
| Login gagal terus | User belum dibuat di tab Authentication, atau Email/Password belum diaktifkan |
| Data hilang setelah refresh | `init()` masih membaca `SharedPreferences`; pastikan sudah pindah ke `snapshots()` |
| Lampiran gagal disimpan | Berkas > 700 KB. Perkecil foto atau pindai ulang dengan kualitas lebih rendah |
| `flutterfire configure` error | Jalankan `firebase login` dulu, dan pastikan project id sama dengan `.firebaserc` |

---

## 10. Biaya

Seluruh skenario demo kelas berada jauh di bawah kuota gratis Spark:

| Layanan | Kuota gratis harian | Perkiraan pemakaian demo |
|---|---|---|
| Authentication | tak terbatas (email/password) | 2 akun |
| Firestore reads | 50.000 / hari | < 1.000 |
| Firestore writes | 20.000 / hari | < 100 |
| Firestore storage | 1 GiB | < 5 MB |
| Hosting | 10 GB transfer / bulan | < 50 MB |
