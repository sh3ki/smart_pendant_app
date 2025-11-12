import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late final Dio _dio;
  static const String _defaultBaseUrl = 'https://api.smartpendant.example.com';

  ApiClient() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? _defaultBaseUrl;
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors for logging and auth
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Device endpoints
  Future<List<dynamic>> getDevices() async {
    try {
      final response = await _dio.get('/devices');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getDeviceDetail(String deviceId) async {
    try {
      final response = await _dio.get('/devices/$deviceId');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTelemetry(String deviceId) async {
    try {
      final response = await _dio.get('/devices/$deviceId/telemetry');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Camera
  Future<Map<String, dynamic>> getLatestImage(String deviceId) async {
    try {
      final response = await _dio.get('/devices/$deviceId/latest-image');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> requestSnapshot(String deviceId) async {
    try {
      await _dio.post('/devices/$deviceId/command', data: {
        'command': 'capture_snapshot',
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Audio
  Future<void> startAudio(String deviceId) async {
    try {
      await _dio.post('/devices/$deviceId/command', data: {
        'command': 'start_audio',
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> stopAudio(String deviceId) async {
    try {
      await _dio.post('/devices/$deviceId/command', data: {
        'command': 'stop_audio',
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Send audio recording
  Future<void> sendAudio(String base64Audio, {String? deviceId}) async {
    try {
      await _dio.post('/audio/send', data: {
        'audio': base64Audio,
        'deviceId': deviceId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  // SOS
  Future<List<dynamic>> getSosAlerts(String deviceId) async {
    try {
      final response = await _dio.get('/devices/$deviceId/alerts');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markAlertHandled(String deviceId, String alertId) async {
    try {
      await _dio.post('/devices/$deviceId/alerts/$alertId/acknowledge');
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your network.';
        case DioExceptionType.badResponse:
          return 'Server error: ${error.response?.statusCode}';
        case DioExceptionType.cancel:
          return 'Request cancelled';
        default:
          return 'Network error occurred';
      }
    }
    return error.toString();
  }
}
