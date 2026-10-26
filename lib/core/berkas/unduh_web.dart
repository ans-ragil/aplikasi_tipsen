import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Mengunduh berkas di browser (Chrome) memakai Blob + anchor.
Future<void> unduhBerkas(String nama, List<int> bytes, String mime) async {
  final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  final blob = web.Blob(
    [data.toJS].toJS,
    web.BlobPropertyBag(type: mime),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = nama
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

/// Membuka dialog cetak browser — pengguna dapat memilih "Save as PDF".
void cetakHalaman() {
  web.window.print();
}
