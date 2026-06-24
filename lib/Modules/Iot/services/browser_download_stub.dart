import 'dart:typed_data';

Future<void> downloadFileFromBytes(
  Uint8List bytes,
  String filename, {
  String contentType = 'application/octet-stream',
}) {
  throw UnsupportedError('File downloads are only available on the web.');
}
