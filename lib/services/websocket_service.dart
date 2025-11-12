import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _telemetryController;
  StreamController<Map<String, dynamic>>? _imageController;
  StreamController<Map<String, dynamic>>? _alertController;
  
  bool _isConnected = false;

  Stream<Map<String, dynamic>> get telemetryStream => 
      _telemetryController?.stream ?? const Stream.empty();
  Stream<Map<String, dynamic>> get imageStream => 
      _imageController?.stream ?? const Stream.empty();
  Stream<Map<String, dynamic>> get alertStream => 
      _alertController?.stream ?? const Stream.empty();

  Future<void> connect(String deviceId) async {
    if (_isConnected) return;

    try {
      // Use WS_URL from .env file, default to localhost
      final wsUrl = dotenv.env['WS_URL'] ?? 'ws://192.168.0.113:3000';
      print('🔌 Connecting to WebSocket: $wsUrl');
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _telemetryController = StreamController<Map<String, dynamic>>.broadcast();
      _imageController = StreamController<Map<String, dynamic>>.broadcast();
      _alertController = StreamController<Map<String, dynamic>>.broadcast();

      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _isConnected = false;
        },
        onDone: () {
          print('📡 WebSocket connection closed');
          _isConnected = false;
        },
      );

      _isConnected = true;
      print('✅ WebSocket connected for device: $deviceId');
    } catch (e) {
      print('❌ Failed to connect WebSocket: $e');
      _isConnected = false;
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      final topic = message['topic'] as String?;

      if (topic == null) return;

      if (topic.contains('telemetry')) {
        _telemetryController?.add(message['payload'] as Map<String, dynamic>);
      } else if (topic.contains('image')) {
        _imageController?.add(message['payload'] as Map<String, dynamic>);
      } else if (topic.contains('alert')) {
        _alertController?.add(message['payload'] as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  void sendCommand(String command, Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode({
        'command': command,
        'data': data,
      }));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _telemetryController?.close();
    _imageController?.close();
    _alertController?.close();
    _isConnected = false;
  }

  bool get isConnected => _isConnected;
}
