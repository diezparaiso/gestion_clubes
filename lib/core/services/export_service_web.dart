import 'dart:convert';
import 'package:universal_html/html.dart' as html;

Future<void> downloadCsv({required String filename, required String content}) async {
  final blob = html.Blob([utf8.encode('\uFEFF$content')], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  anchor.remove();
}
