/// Penerjemah kode kesalahan [FirebaseAuthException] menjadi pesan yang
/// dipahami pengguna (modul minggu 9, bagian 6).
///
/// Pesan untuk "email tidak terdaftar" dan "password salah" sengaja
/// disamakan karena Firebase mengaktifkan perlindungan enumerasi email —
/// orang lain tidak dapat menebak email mana yang terdaftar.
String pesanKesalahanAuth(String kode) {
  switch (kode) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'Email atau password salah.';
    case 'invalid-email':
      return 'Format email belum benar.';
    case 'email-already-in-use':
      return 'Email sudah terdaftar. Silakan masuk.';
    case 'weak-password':
      return 'Password terlalu lemah, minimal 6 karakter.';
    case 'too-many-requests':
      return 'Terlalu banyak percobaan. Coba lagi nanti.';
    case 'network-request-failed':
      return 'Tidak dapat terhubung. Periksa koneksi internet.';
    case 'operation-not-allowed':
      return 'Login email/password belum diaktifkan di Firebase Console.';
    case 'user-disabled':
      return 'Akun ini dinonaktifkan. Hubungi HC Admin.';
    case 'requires-recent-login':
      return 'Sesi terlalu lama. Keluar lalu masuk kembali sebelum mengubah kata sandi.';
    default:
      return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
