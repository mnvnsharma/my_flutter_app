
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://dummyjson.com';

  static String? token;

  static const Duration timeout = Duration(seconds: 15);

  static Future<bool> login(
    String username,
    String password,
  ) async {
    try {
      final response = await http
          .post(
      Uri.parse('$baseUrl/auth/login'),
            headers: {
              'Content-Type': 'application/json',
            },
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 30,
      }),
          )
          .timeout(timeout);

      debugPrint('Login HTTP status: ${response.statusCode}');

    if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body) as Map<String, dynamic>;

      token = data['accessToken'] as String?;

      return token != null && token!.isNotEmpty;
    }

      debugPrint('Login API error: ${response.body}');
    return false;
    } on SocketException catch (e) {
      debugPrint('Network error: $e');
      rethrow;
    } on TimeoutException catch (e) {
      debugPrint('API timeout: $e');
      rethrow;
    } on http.ClientException catch (e) {
      debugPrint('HTTP client error: $e');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected login error: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getStudents() async {
    final response = await http
        .get(Uri.parse('$baseUrl/users?limit=20'))
        .timeout(timeout);

    debugPrint('Students HTTP status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      return data['users'] as List<dynamic>;
    }

    throw Exception(
      'Failed to load students: HTTP ${response.statusCode}',
    );
  }

  static Future<Map<String, dynamic>> addStudent(
    String name,
    String grade,
  ) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/users/add'),
          headers: {
            'Content-Type': 'application/json',
          },
      body: jsonEncode({
        'firstName': name,
        'lastName': '',
        'company': {'title': grade},
      }),
        )
        .timeout(timeout);

         debugPrint('Add HTTP status: ${response.statusCode}');
    debugPrint('Add response: ${response.body}');

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return jsonDecode(response.body)
          as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to add student: HTTP ${response.statusCode}',
    );
  }

  static Future<bool> deleteStudent(int id) async {

    final apiStudents = await getStudents();
    final existsInApi = apiStudents.any(
    (student) => student['id'] == id,
  );

    if (!existsInApi) {
      debugPrint(
        'Student $id not found in API. '
        'It should be removed locally.',
      );

      return true;
    }

    final response = await http
        .delete(Uri.parse('$baseUrl/users/$id'))
        .timeout(timeout);

    debugPrint('Delete HTTP status: ${response.statusCode}');
      debugPrint('Deleting student ID: $id');
    debugPrint('Delete HTTP status: ${response.statusCode}');
    debugPrint('Delete response: ${response.body}');
    debugPrint('Delete response3: $response');

    return response.statusCode == 200;
  }
}
