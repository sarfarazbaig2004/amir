import 'dart:async';

import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import 'auth_service.dart';
import 'browser_download.dart';
import 'machine_service.dart';

class ReportExportService {
  static const Duration _requestTimeout = Duration(seconds: 30);

  static Future<void> downloadWelderArcReport({
    required String date,
    required String format,
  }) async {
    final normalizedFormat = format.trim().toLowerCase();
    if (normalizedFormat != 'csv' && normalizedFormat != 'pdf') {
      throw const MachineServiceException('Unsupported report format.');
    }

    final uri = Uri.parse(
      '${AppConfig.baseUrl}/api/reports/welder-arc-events.$normalizedFormat',
    ).replace(queryParameters: {'date': date});

    try {
      final response = await http
          .get(uri, headers: AuthService.authorizedHeaders)
          .timeout(_requestTimeout);

      if (response.statusCode == 401 || response.statusCode == 403) {
        AuthService.handleAuthFailure();
        throw const MachineServiceException(
          'Your session expired. Please sign in again.',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw MachineServiceException(
          'Report download failed with status ${response.statusCode}.',
        );
      }

      final contentType =
          response.headers['content-type'] ??
          (normalizedFormat == 'pdf' ? 'application/pdf' : 'text/csv');

      await downloadFileFromBytes(
        response.bodyBytes,
        'welder-arc-report-$date.$normalizedFormat',
        contentType: contentType,
      );
    } on TimeoutException {
      throw const MachineServiceException('Report download timed out.');
    } on http.ClientException catch (error) {
      throw MachineServiceException(
        'Unable to download the report: ${error.message}',
      );
    }
  }
}
