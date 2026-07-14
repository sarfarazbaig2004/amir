import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

void downloadReportFile(
  Uint8List bytes, {
  required String fileName,
  required String mimeType,
}) {
  final parts = <web.BlobPart>[bytes.toJS].toJS;
  final blob = web.Blob(parts, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..click();
  web.URL.revokeObjectURL(url);
}
