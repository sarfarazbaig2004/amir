// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadFileFromBytes(
  Uint8List bytes,
  String filename, {
  String contentType = 'application/octet-stream',
}) async {
  final blob = html.Blob([bytes], contentType);
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);

  try {
    final anchor = html.AnchorElement(href: objectUrl)
      ..download = filename
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  } finally {
    html.Url.revokeObjectUrl(objectUrl);
  }
}
