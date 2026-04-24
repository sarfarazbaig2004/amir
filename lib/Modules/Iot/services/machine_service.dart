import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';

class MachineService {
  static const Duration _requestTimeout = Duration(seconds: 10);
  static const Map<String, String> _defaultHeaders = {
    'Accept': 'application/json',
  };

  static Future<Map<String, dynamic>> getMachineOverview(
    String machineId,
  ) async {
    final normalizedMachineId = machineId.trim();
    if (normalizedMachineId.isEmpty) {
      throw const MachineServiceException('Machine ID is required.');
    }

    try {
      final response = await http
          .get(
            _machineOverviewUri(normalizedMachineId),
            headers: _defaultHeaders,
          )
          .timeout(_requestTimeout);

      return _decodeMapResponse(
        response,
        notFoundMessage:
            'Machine $normalizedMachineId was not found on the backend.',
      );
    } on TimeoutException {
      throw const MachineServiceException(
        'Machine overview request timed out. Check the API connection and try again.',
      );
    } on http.ClientException catch (error) {
      throw MachineServiceException(
        'Unable to reach the machine overview API: ${error.message}',
      );
    } on FormatException {
      throw const MachineServiceException(
        'Machine overview response was not valid JSON.',
      );
    }
  }

  static Future<List<dynamic>> getFleetOverview() async {
    try {
      final response = await http
          .get(_fleetOverviewUri, headers: _defaultHeaders)
          .timeout(_requestTimeout);

      return _decodeListResponse(
        response,
        notFoundMessage: 'Fleet overview endpoint was not found on the backend.',
      );
    } on TimeoutException {
      throw const MachineServiceException(
        'Fleet overview request timed out. Check the API connection and try again.',
      );
    } on http.ClientException catch (error) {
      throw MachineServiceException(
        'Unable to reach the fleet overview API: ${error.message}',
      );
    } on FormatException {
      throw const MachineServiceException(
        'Fleet overview response was not valid JSON.',
      );
    }
  }

  static Uri _machineOverviewUri(String machineId) {
    final encodedMachineId = Uri.encodeComponent(machineId);
    return Uri.parse('${AppConfig.baseUrl}/api/machine/$encodedMachineId/overview');
  }

  static Uri get _fleetOverviewUri =>
      Uri.parse('${AppConfig.baseUrl}/api/machines/overview');

  static Map<String, dynamic> _decodeMapResponse(
    http.Response response, {
    required String notFoundMessage,
  }) {
    _throwForStatus(response, notFoundMessage: notFoundMessage);

    final decodedBody = jsonDecode(response.body);
    if (decodedBody is! Map) {
      throw const FormatException('Expected a JSON object.');
    }

    return Map<String, dynamic>.from(decodedBody);
  }

  static List<dynamic> _decodeListResponse(
    http.Response response, {
    required String notFoundMessage,
  }) {
    _throwForStatus(response, notFoundMessage: notFoundMessage);

    final decodedBody = jsonDecode(response.body);
    if (decodedBody is! List) {
      throw const FormatException('Expected a JSON array.');
    }

    return decodedBody;
  }

  static void _throwForStatus(
    http.Response response, {
    required String notFoundMessage,
  }) {
    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 404) {
      throw MachineServiceException(notFoundMessage);
    }

    final apiMessage = _extractApiMessage(response.body);
    final fallbackMessage =
        'API request failed with status ${response.statusCode}.';

    throw MachineServiceException(apiMessage ?? fallbackMessage);
  }

  static String? _extractApiMessage(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return null;
    }

    try {
      final decodedBody = jsonDecode(responseBody);
      if (decodedBody is Map) {
        final message = decodedBody['message'] ?? decodedBody['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } on FormatException {
      return null;
    }

    return null;
  }
}

class MachineServiceException implements Exception {
  const MachineServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
