import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/app_models.dart';

// Camera provider
final cameraProvider = StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  return CameraNotifier();
});

class CameraNotifier extends StateNotifier<CameraState> {
  Timer? _autoRefreshTimer;
  Timer? _frameCycleTimer;
  List<Map<String, dynamic>> _frameBuffer = [];
  int _currentFrameIndex = 0;
  
  // Update this with your server IP
  static const String SERVER_URL = 'http://192.168.1.11:3000';

  CameraNotifier() : super(CameraState());

  /// Fetch the latest camera frame from server
  Future<void> requestSnapshot() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final response = await http.get(
        Uri.parse('$SERVER_URL/api/camera/latest'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        state = CameraState(
          imageUrl: data['imageUrl'],
          timestamp: data['timestamp'],
          isLoading: false,
          frameNumber: data['frameNumber'],
        );
      } else {
        print('Failed to fetch camera frame: ${response.statusCode}');
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print('Error fetching camera frame: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Fetch all frames for cycling (video-like effect)
  Future<void> _fetchAllFrames() async {
    try {
      final response = await http.get(
        Uri.parse('$SERVER_URL/api/camera/frames'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _frameBuffer = List<Map<String, dynamic>>.from(data['frames']);
        
        if (_frameBuffer.isNotEmpty) {
          _currentFrameIndex = _frameBuffer.length - 1; // Start with latest
          _displayCurrentFrame();
        }
      }
    } catch (e) {
      print('Error fetching frames: $e');
    }
  }

  /// Display current frame from buffer
  void _displayCurrentFrame() {
    if (_frameBuffer.isEmpty) return;
    
    final frame = _frameBuffer[_currentFrameIndex];
    state = CameraState(
      imageUrl: frame['imageUrl'],
      timestamp: frame['timestamp'],
      isLoading: false,
      frameNumber: frame['frameNumber'],
    );
  }

  /// Start auto-refresh mode (fetch new frames every 500ms)
  void startAutoRefresh() {
    stopAutoRefresh(); // Clear any existing timers
    
    // Fetch all frames immediately
    _fetchAllFrames();
    
    // Set up frame cycling (2 FPS = 500ms per frame)
    _frameCycleTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_frameBuffer.isNotEmpty) {
        _currentFrameIndex = (_currentFrameIndex + 1) % _frameBuffer.length;
        _displayCurrentFrame();
      }
    });
    
    // Fetch fresh frames from server every 2 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchAllFrames();
    });
  }

  /// Stop auto-refresh mode
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _frameCycleTimer?.cancel();
    _autoRefreshTimer = null;
    _frameCycleTimer = null;
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
