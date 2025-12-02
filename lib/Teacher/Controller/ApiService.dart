import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://smartattendnotification.onrender.com',
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10), // Important for Mobile
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<void> sendNotification(String title, String body) async {
    try {
      final res = await _dio.post(
        '/send-notification',
        data: {'title': title, 'body': body},
      );
      if (res.statusCode != 200) {
        throw Exception('Failed to send notification: ${res.statusCode}');
      }
      if (kDebugMode) {
        print("Notification Sent: ${res.data}");
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print("DioError: ${e.message}");
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error sending notification: $e');
    }
  }
}