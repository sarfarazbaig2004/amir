import 'dart:typed_data';

void downloadReportFile(
  Uint8List bytes, {
  required String fileName,
  required String mimeType,
}) {
  throw UnsupportedError('Report downloads are currently supported on web.');
}
