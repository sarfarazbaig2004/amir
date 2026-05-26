import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import 'auth_service.dart';

class MachineService {
  static const Duration _requestTimeout = Duration(seconds: 30);

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
            headers: AuthService.authorizedHeaders,
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

  static Future<Map<String, dynamic>> getMachineDailyProduction(
    String machineId,
    String date,
  ) async {
    final normalizedMachineId = machineId.trim();
    if (normalizedMachineId.isEmpty) {
      throw const MachineServiceException('Machine ID is required.');
    }

    try {
      final response = await http
          .get(
            _machineDailyProductionUri(normalizedMachineId, date),
            headers: AuthService.authorizedHeaders,
          )
          .timeout(_requestTimeout);

      return _decodeMapResponse(
        response,
        notFoundMessage:
            'Daily production endpoint was not found for machine $normalizedMachineId.',
      );
    } on TimeoutException {
      throw const MachineServiceException(
        'Daily production request timed out. Check the API connection and try again.',
      );
    } on http.ClientException catch (error) {
      throw MachineServiceException(
        'Unable to reach the daily production API: ${error.message}',
      );
    } on FormatException {
      throw const MachineServiceException(
        'Daily production response was not valid JSON.',
      );
    }
  }

  static Future<List<dynamic>> getMachineProductionTimeline(
    String machineId,
    String date,
  ) async {
    final normalizedMachineId = machineId.trim();
    if (normalizedMachineId.isEmpty) {
      throw const MachineServiceException('Machine ID is required.');
    }

    try {
      final response = await http
          .get(
            _machineProductionTimelineUri(normalizedMachineId, date),
            headers: AuthService.authorizedHeaders,
          )
          .timeout(_requestTimeout);

      return _decodeFlexibleListResponse(
        response,
        listKeys: const ['timeline', 'items', 'data', 'events'],
        notFoundMessage:
            'Production timeline endpoint was not found for machine $normalizedMachineId.',
      );
    } on TimeoutException {
      throw const MachineServiceException(
        'Production timeline request timed out. Check the API connection and try again.',
      );
    } on http.ClientException catch (error) {
      throw MachineServiceException(
        'Unable to reach the production timeline API: ${error.message}',
      );
    } on FormatException {
      throw const MachineServiceException(
        'Production timeline response was not valid JSON.',
      );
    }
  }

  static Future<Map<String, dynamic>> setCurrent(
    String machineId,
    int current,
  ) async {
    final normalizedMachineId = machineId.trim();
    if (normalizedMachineId.isEmpty) {
      throw const MachineServiceException('Machine ID is required.');
    }

    try {
      final response = await http
          .post(
            Uri.parse(
              '${AppConfig.baseUrl}/api/machine/$normalizedMachineId/set-current',
            ),
            headers: AuthService.authorizedJsonHeaders,
            body: jsonEncode({'current': current}),
          )
          .timeout(_requestTimeout);

      return _decodeMapResponse(
        response,
        notFoundMessage:
            'Set current endpoint was not found for machine $normalizedMachineId.',
      );
    } on TimeoutException {
      throw const MachineServiceException(
        'Set current request timed out. Check the API connection and try again.',
      );
    } on http.ClientException catch (error) {
      throw MachineServiceException(
        'Unable to reach the set current API: ${error.message}',
      );
    } on FormatException {
      throw const MachineServiceException(
        'Set current response was not valid JSON.',
      );
    }
  }

  static Future<List<dynamic>> getFleetOverview() async {
    try {
      final response = await http
          .get(_fleetOverviewUri, headers: AuthService.authorizedHeaders)
          .timeout(_requestTimeout);

      return _decodeListResponse(
        response,
        notFoundMessage:
            'Fleet overview endpoint was not found on the backend.',
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

  static Future<List<dynamic>> getLiveWelderSessions() async {
    try {
      final response = await http
          .get(_fleetOverviewUri, headers: AuthService.authorizedHeaders)
          .timeout(_requestTimeout);

      final machines = _decodeListResponse(
        response,
        notFoundMessage:
            'Fleet overview endpoint was not found on the backend.',
      );

      return machines
          .where((machine) {
            if (machine is! Map) return false;
            return machine['activeWelderSession'] != null;
          })
          .map((machine) {
            final machineMap = Map<String, dynamic>.from(machine as Map);
            final session = Map<String, dynamic>.from(
              machineMap['activeWelderSession'] as Map,
            );

            return {
              'machine': {
                'id': machineMap['id'] ?? machineMap['machineId'],
                'machineCode':
                    machineMap['machineCode'] ?? machineMap['code'] ?? '-',
                'serialNumber': machineMap['serialNumber'] ?? '-',
                'location': machineMap['location'] ?? '-',
              },
              'welder': session['welder'] ??
                  {
                    'name': machineMap['welder'] ?? '-',
                  },
              'arcingTime': session['arcingTime'] ?? '0:00:00',
              'idleTime': session['idleTime'] ?? '0:00:00',
              'current': session['current'] ?? machineMap['outputCurrent'] ?? 0,
              'voltage': session['voltage'] ?? 0,
              'status': session['status'] ?? machineMap['status'] ?? '-',
            };
          })
          .toList();
    } on TimeoutException {
      throw const MachineServiceException(
        'Live welder session report request timed out. Check the API connection and try again.',
      );
    } on http.ClientException catch (error) {
      throw MachineServiceException(
        'Unable to reach the live welder session report API: ${error.message}',
      );
    } on FormatException {
      throw const MachineServiceException(
        'Live welder session report response was not valid JSON.',
      );
    }
  }

  static Future<List<dynamic>> getAdminCustomers() async {
    try {
      final response = await http
          .get(_adminCustomersUri, headers: AuthService.authorizedHeaders)
          .timeout(_requestTimeout);

      return _decodeListResponse(
        response,
        notFoundMessage:
            'Admin customers endpoint was not found on the backend.',
      );
    } on TimeoutException {
      throw const MachineServiceException(
        'Admin customers request timed out. Check the API connection and try again.',
      );
    } on http.ClientException catch (error) {
      throw MachineServiceException(
        'Unable to reach the admin customers API: ${error.message}',
      );
    } on FormatException {
      throw const MachineServiceException(
        'Admin customers response was not valid JSON.',
      );
    }
  }

  static Future<Map<String, dynamic>> createAdminCustomer({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            _adminCustomersUri,
            headers: AuthService.authorizedJsonHeaders,
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(_requestTimeout);

      return _decodeMapResponse(
        response,
        notFoundMessage: 'Customer creation endpoint was not found.',
      );
    } on TimeoutException {
      throw const MachineServiceException(
        'Customer creation request timed out. Check the API connection and try again.',
      );
    } on http.ClientException catch (error) {
      throw MachineServiceException(
        'Unable to reach the customer creation API: ${error.message}',
      );
    } on FormatException {
      throw const MachineServiceException(
        'Customer creation response was not valid JSON.',
      );
    }
  }

  static Future<Map<String, dynamic>> updateAdminCustomerAccess({
    required String customerId,
    required Set<String> modules,
    required Set<int> machineIds,
    Set<String> machineCodes = const {},
    Set<String> features = const {},
    Set<String> parameters = const {},
    Set<String> premiumFeatures = const {},
    Set<String> buttons = const {},
    Set<String> reports = const {},
  }) async {
    final payload = {
      'modules': modules.toList()..sort(),
      'machines': machineCodes.toList()..sort(),
      'machineIds': machineIds.toList()..sort(),
      'features': features.toList()..sort(),
      'parameters': parameters.toList()..sort(),
      'premiumFeatures': premiumFeatures.toList()..sort(),
      'buttons': buttons.toList()..sort(),
      'reports': reports.toList()..sort(),
    };
    debugPrint('[access] save payload for customer $customerId: $payload');

    try {
      final response = await http
          .put(
            _legacyAdminCustomerAccessUri(customerId),
            headers: AuthService.authorizedJsonHeaders,
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);

      debugPrint(
        '[access] API response ${response.statusCode} for customer '
        '$customerId: ${response.body}',
      );

      return _decodeMapResponse(
        response,
        notFoundMessage:
            'Access update endpoint was not found for customer $customerId.',
      );
    } on TimeoutException {
      throw const MachineServiceException(
        'Access update request timed out. Check the API connection and try again.',
      );
    } on http.ClientException catch (error) {
      throw MachineServiceException(
        'Unable to reach the access update API: ${error.message}',
      );
    } on FormatException {
      throw const MachineServiceException(
        'Access update response was not valid JSON.',
      );
    }
  }

  static Future<Map<String, dynamic>> getAdminCustomerAccessByEmail(
    String email,
  ) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw const MachineServiceException('Customer email is required.');
    }

    try {
      final response = await http
          .get(
            _adminCustomerAccessByEmailUri(normalizedEmail),
            headers: AuthService.authorizedHeaders,
          )
          .timeout(_requestTimeout);

      debugPrint(
        '[access] reload payload response ${response.statusCode} for '
        '$normalizedEmail: ${response.body}',
      );

      return _decodeMapResponse(
        response,
        notFoundMessage:
            'Customer access endpoint was not found for $normalizedEmail.',
      );
    } on TimeoutException {
      throw const MachineServiceException(
        'Customer access load request timed out. Check the API connection and try again.',
      );
    } on http.ClientException catch (error) {
      throw MachineServiceException(
        'Unable to reach the customer access API: ${error.message}',
      );
    } on FormatException {
      throw const MachineServiceException(
        'Customer access response was not valid JSON.',
      );
    }
  }

  static Future<Map<String, dynamic>> saveAdminCustomerAccessByEmail({
    required String email,
    required Set<String> modules,
    required Set<String> machineCodes,
    required Set<int> machineIds,
    Set<String> features = const {},
    Set<String> parameters = const {},
    Set<String> premiumFeatures = const {},
    Set<String> buttons = const {},
    Set<String> reports = const {},
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw const MachineServiceException('Customer email is required.');
    }

    final payload = {
      'email': normalizedEmail,
      'modules': modules.toList()..sort(),
      'machines': machineCodes.toList()..sort(),
      'machineIds': machineIds.toList()..sort(),
      'features': features.toList()..sort(),
      'parameters': parameters.toList()..sort(),
      'premiumFeatures': premiumFeatures.toList()..sort(),
      'buttons': buttons.toList()..sort(),
      'reports': reports.toList()..sort(),
    };

    debugPrint('[access] save payload for $normalizedEmail: $payload');

    try {
      final response = await http
          .post(
            _adminCustomerAccessUri,
            headers: AuthService.authorizedJsonHeaders,
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);

      debugPrint(
        '[access] API response ${response.statusCode} for '
        '$normalizedEmail: ${response.body}',
      );

      return _decodeMapResponse(
        response,
        notFoundMessage:
            'Customer access save endpoint was not found for $normalizedEmail.',
      );
    } on TimeoutException {
      throw const MachineServiceException(
        'Customer access save request timed out. Check the API connection and try again.',
      );
    } on http.ClientException catch (error) {
      throw MachineServiceException(
        'Unable to reach the customer access save API: ${error.message}',
      );
    } on FormatException {
      throw const MachineServiceException(
        'Customer access save response was not valid JSON.',
      );
    }
  }



  static Future<List<dynamic>> getActiveWelderAssignments({
    required String machineId,
  }) async {
    final response = await http
        .get(
          Uri.parse('${AppConfig.baseUrl}/api/welder-assignments/active')
              .replace(queryParameters: {'machineId': machineId}),
          headers: AuthService.authorizedHeaders,
        )
        .timeout(_requestTimeout);

    return _decodeListResponse(
      response,
      notFoundMessage: 'Active welder assignment endpoint was not found.',
    );
  }

  static Future<Map<String, dynamic>> startManualWelderAssignment({
    required String machineId,
    required String welderName,
    required String employeeCode,
  }) async {
    final response = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}/api/welder-assignments/manual'),
          headers: AuthService.authorizedJsonHeaders,
          body: jsonEncode({
            'machineId': machineId,
            'welderName': welderName,
            'employeeCode': employeeCode,
            'trackingMode': 'MANUAL',
          }),
        )
        .timeout(_requestTimeout);

    return _decodeMapResponse(
      response,
      notFoundMessage: 'Manual welder assignment endpoint was not found.',
    );
  }

  static Future<Map<String, dynamic>> endWelderAssignment({
    required String assignmentId,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            '${AppConfig.baseUrl}/api/welder-assignments/$assignmentId/end',
          ),
          headers: AuthService.authorizedJsonHeaders,
          body: '{}',
        )
        .timeout(_requestTimeout);

    return _decodeMapResponse(
      response,
      notFoundMessage: 'End welder assignment endpoint was not found.',
    );
  }

  static Future<Map<String, dynamic>> getEngineeringSetpoints(
    String machineId,
  ) async {
    final normalizedMachineId = machineId.trim();
    if (normalizedMachineId.isEmpty) {
      throw const MachineServiceException('Machine ID is required.');
    }

    try {
      final response = await http
          .get(
            _engineeringSetpointsUri(normalizedMachineId),
            headers: AuthService.authorizedHeaders,
          )
          .timeout(_requestTimeout);

      return _decodeMapResponse(
        response,
        notFoundMessage:
            'Engineering setpoints endpoint was not found for machine $normalizedMachineId.',
      );
    } on TimeoutException {
      throw const MachineServiceException(
        'Engineering setpoints request timed out.',
      );
    } on http.ClientException catch (error) {
      throw MachineServiceException(
        'Unable to reach engineering setpoints API: ${error.message}',
      );
    } on FormatException {
      throw const MachineServiceException(
        'Engineering setpoints response was not valid JSON.',
      );
    }
  }

  static Future<Map<String, dynamic>> saveEngineeringSetpoints({
    required String machineId,
    required Map<String, dynamic> payload,
  }) async {
    final normalizedMachineId = machineId.trim();
    if (normalizedMachineId.isEmpty) {
      throw const MachineServiceException('Machine ID is required.');
    }

    try {
      final response = await http
          .post(
            _engineeringSetpointsUri(normalizedMachineId),
            headers: AuthService.authorizedJsonHeaders,
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);

      return _decodeMapResponse(
        response,
        notFoundMessage:
            'Engineering setpoints save endpoint was not found for machine $normalizedMachineId.',
      );
    } on TimeoutException {
      throw const MachineServiceException(
        'Engineering setpoints save request timed out.',
      );
    } on http.ClientException catch (error) {
      throw MachineServiceException(
        'Unable to reach engineering setpoints save API: ${error.message}',
      );
    } on FormatException {
      throw const MachineServiceException(
        'Engineering setpoints save response was not valid JSON.',
      );
    }
  }

  static Future<Map<String, dynamic>> readAllEngineeringSetpoints(
    String machineId,
  ) async {
    final normalizedMachineId = machineId.trim();
    if (normalizedMachineId.isEmpty) {
      throw const MachineServiceException('Machine ID is required.');
    }

    try {
      final response = await http
          .post(
            _engineeringReadAllUri(normalizedMachineId),
            headers: AuthService.authorizedJsonHeaders,
            body: '{}',
          )
          .timeout(_requestTimeout);

      return _decodeMapResponse(
        response,
        notFoundMessage:
            'Engineering read-all endpoint was not found for machine $normalizedMachineId.',
      );
    } on TimeoutException {
      throw const MachineServiceException(
        'Engineering read-all request timed out.',
      );
    } on http.ClientException catch (error) {
      throw MachineServiceException(
        'Unable to reach engineering read-all API: ${error.message}',
      );
    } on FormatException {
      throw const MachineServiceException(
        'Engineering read-all response was not valid JSON.',
      );
    }
  }

  static Future<void> resetJobData(String machineId) async {
    await _postMachineAction(
      machineId: machineId,
      actionPath: 'reset-job',
      actionLabel: 'reset job data',
    );
  }

  static Future<void> resetMachineLifetimeData(String machineId) async {
    await _postMachineAction(
      machineId: machineId,
      actionPath: 'reset-machine',
      actionLabel: 'reset machine lifetime data',
    );
  }

  static Future<void> _postMachineAction({
    required String machineId,
    required String actionPath,
    required String actionLabel,
  }) async {
    final normalizedMachineId = machineId.trim();
    if (normalizedMachineId.isEmpty) {
      throw const MachineServiceException('Machine ID is required.');
    }

    try {
      final response = await http
          .post(
            _machineActionUri(normalizedMachineId, actionPath),
            headers: AuthService.authorizedJsonHeaders,
            body: '{}',
          )
          .timeout(_requestTimeout);

      _throwForStatus(
        response,
        notFoundMessage:
            'Backend endpoint to $actionLabel was not found for machine $normalizedMachineId.',
      );
    } on TimeoutException {
      throw MachineServiceException(
        'Machine $actionLabel request timed out. Check the API connection and try again.',
      );
    } on http.ClientException catch (error) {
      throw MachineServiceException(
        'Unable to reach the machine $actionLabel API: ${error.message}',
      );
    }
  }


  static Uri _engineeringSetpointsUri(String machineId) {
    final encodedMachineId = Uri.encodeComponent(machineId);
    return Uri.parse(
      '${AppConfig.baseUrl}/api/machine/$encodedMachineId/engineering/setpoints',
    );
  }

  static Uri _engineeringReadAllUri(String machineId) {
    final encodedMachineId = Uri.encodeComponent(machineId);
    return Uri.parse(
      '${AppConfig.baseUrl}/api/machine/$encodedMachineId/engineering/read-all',
    );
  }

  static Uri _machineOverviewUri(String machineId) {
    final encodedMachineId = Uri.encodeComponent(machineId);
    return Uri.parse(
      '${AppConfig.baseUrl}/api/machine/$encodedMachineId/overview',
    );
  }

  static Uri _machineDailyProductionUri(String machineId, String date) {
    final encodedMachineId = Uri.encodeComponent(machineId);
    return Uri.parse(
      '${AppConfig.baseUrl}/api/machine/$encodedMachineId/production/daily',
    ).replace(queryParameters: {'date': date});
  }

  static Uri _machineProductionTimelineUri(String machineId, String date) {
    final encodedMachineId = Uri.encodeComponent(machineId);
    return Uri.parse(
      '${AppConfig.baseUrl}/api/machine/$encodedMachineId/production/timeline',
    ).replace(queryParameters: {'date': date});
  }

  static Uri _machineActionUri(String machineId, String actionPath) {
    final encodedMachineId = Uri.encodeComponent(machineId);
    return Uri.parse(
      '${AppConfig.baseUrl}/api/machine/$encodedMachineId/$actionPath',
    );
  }

  static Uri get _fleetOverviewUri =>
      Uri.parse('${AppConfig.baseUrl}/api/machines/overview');

  static Uri get _adminCustomersUri =>
      Uri.parse('${AppConfig.baseUrl}/api/admin/customers');

  static Uri get _adminCustomerAccessUri =>
      Uri.parse('${AppConfig.baseUrl}/api/admin/customer-access');

  static Uri _adminCustomerAccessByEmailUri(String email) {
    return _adminCustomerAccessUri.replace(queryParameters: {'email': email});
  }

  static Uri _legacyAdminCustomerAccessUri(String customerId) {
    return Uri.parse(
      '${AppConfig.baseUrl}/api/admin/customers/${Uri.encodeComponent(customerId)}/access',
    );
  }

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

  static List<dynamic> _decodeFlexibleListResponse(
    http.Response response, {
    required List<String> listKeys,
    required String notFoundMessage,
  }) {
    _throwForStatus(response, notFoundMessage: notFoundMessage);

    final decodedBody = jsonDecode(response.body);
    if (decodedBody is List) {
      return decodedBody;
    }

    if (decodedBody is Map) {
      for (final key in listKeys) {
        final value = decodedBody[key];
        if (value is List) {
          return value;
        }
      }
    }

    throw const FormatException('Expected a JSON array.');
  }

  static void _throwForStatus(
    http.Response response, {
    required String notFoundMessage,
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    if (response.statusCode == 404) {
      throw MachineServiceException(notFoundMessage);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      AuthService.handleAuthFailure();
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