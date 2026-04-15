import 'dart:convert';
import 'package:http/http.dart' as http;

class MachineService {
  static const String overviewUrl =
      'http://localhost:5000/api/machine/3/overview';

  static const String fleetUrl =
      'http://localhost:5000/api/machines/overview';

  static Future<Map<String, dynamic>> fetchOverview() async {
    final response = await http.get(Uri.parse(overviewUrl));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load overview: ${response.statusCode}');
    }
  }

  static Future<List<dynamic>> fetchFleet() async {
    final response = await http.get(Uri.parse(fleetUrl));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load fleet: ${response.statusCode}');
    }
  }
}