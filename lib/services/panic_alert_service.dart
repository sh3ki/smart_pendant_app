import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../utils/time_utils.dart';

class PanicAlertService {
  static final PanicAlertService _instance = PanicAlertService._internal();
  factory PanicAlertService() => _instance;
  PanicAlertService._internal();

  Timer? _alertTimer;
  Timer? _beepTimer;
  Timer? _vibrationTimer;
  AudioPlayer? _audioPlayer;
  bool _isAlerting = false;

  final Duration alertDuration = const Duration(seconds: 5);  // Changed to 5 seconds
  final Duration beepInterval = const Duration(milliseconds: 800);
  final Duration vibrationInterval = const Duration(milliseconds: 500);

  // Callbacks for UI updates
  Function(Map<String, dynamic> alertData)? onAlertStarted;
  Function()? onAlertStopped;

  bool get isAlerting => _isAlerting;

  /// Start panic alert (5 seconds of notification, beep, vibration)
  Future<void> startPanicAlert(Map<String, dynamic> alertData) async {
    final startTime = DateTime.now();
    
    if (_isAlerting) {
      print('⚠️ Panic alert already in progress');
      return;
    }

    print('🚨 Starting panic alert for 5 seconds');
    _isAlerting = true;

    // Notify UI that alert started IMMEDIATELY (no await)
    onAlertStarted?.call(alertData);

    // Log response time
    final responseTime = DateTime.now().difference(startTime).inMilliseconds;
    print('⚡ Alert UI triggered in ${responseTime}ms');

    // Initialize audio player (don't await - let it load in background)
    _audioPlayer = AudioPlayer();
    _audioPlayer!.setReleaseMode(ReleaseMode.stop);
    _audioPlayer!.setVolume(1.0);

    // Start repeating beep sound
    _startRepeatingBeep();

    // Start repeating vibration
    _startRepeatingVibration();

    // Stop alert after 5 seconds
    _alertTimer = Timer(alertDuration, () {
      stopPanicAlert();
    });
  }

  /// Start repeating beep sound (every 800ms)
  void _startRepeatingBeep() {
    // Play initial beep
    _playBeep();

    // Continue playing beep every 800ms
    _beepTimer = Timer.periodic(beepInterval, (timer) {
      _playBeep();
    });
  }

  /// Play a single beep sound (1kHz tone for 300ms)
  Future<void> _playBeep() async {
    try {
      // Generate a simple beep tone URL
      // Since we don't have a beep.mp3 file, we'll use platform channel or system sound
      await HapticFeedback.heavyImpact(); // Add haptic for emphasis
      
      // For now, use SystemSoundType.alert (built-in system sound)
      await SystemSound.play(SystemSoundType.alert);
      
      print('🔊 BEEP!');
    } catch (e) {
      print('❌ Failed to play beep: $e');
    }
  }

  /// Start repeating vibration (every 500ms)
  void _startRepeatingVibration() {
    // Vibrate immediately
    _vibrate();

    // Continue vibrating every 500ms
    _vibrationTimer = Timer.periodic(vibrationInterval, (timer) {
      _vibrate();
    });
  }

  /// Trigger vibration
  Future<void> _vibrate() async {
    try {
      // Check if device has vibration capability
      bool? hasVibrator = await Vibration.hasVibrator();
      
      if (hasVibrator == true) {
        // Vibrate for 300ms with strong intensity
        await Vibration.vibrate(duration: 300);
        print('📳 VIBRATE!');
      } else {
        // Fallback to haptic feedback
        await HapticFeedback.heavyImpact();
        print('📳 HAPTIC (no vibrator)');
      }
    } catch (e) {
      print('❌ Failed to vibrate: $e');
      // Fallback to haptic feedback
      try {
        await HapticFeedback.heavyImpact();
      } catch (e2) {
        print('❌ Haptic feedback also failed: $e2');
      }
    }
  }

  /// Stop panic alert immediately
  void stopPanicAlert() {
    if (!_isAlerting) return;

    print('🛑 Stopping panic alert');

    // Cancel all timers
    _alertTimer?.cancel();
    _beepTimer?.cancel();
    _vibrationTimer?.cancel();

    // Stop and dispose audio player
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _audioPlayer = null;

    _isAlerting = false;

    // Notify UI that alert stopped
    onAlertStopped?.call();
  }

  /// Show in-app notification overlay
  OverlayEntry createAlertOverlay(BuildContext context, Map<String, dynamic> alertData) {
    return OverlayEntry(
      builder: (context) => _PanicAlertOverlay(
        alertData: alertData,
        onDismiss: () {
          stopPanicAlert();
        },
      ),
    );
  }

  void dispose() {
    stopPanicAlert();
  }
}

/// Visual overlay for panic alert notification
class _PanicAlertOverlay extends StatefulWidget {
  final Map<String, dynamic> alertData;
  final VoidCallback onDismiss;

  const _PanicAlertOverlay({
    required this.alertData,
    required this.onDismiss,
  });

  @override
  State<_PanicAlertOverlay> createState() => _PanicAlertOverlayState();
}

class _PanicAlertOverlayState extends State<_PanicAlertOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  int _remainingSeconds = 5;  // Changed to 5 seconds
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    // Pulsing animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          timer.cancel();
          widget.onDismiss();
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: SafeArea(
        child: Center(
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.6),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emergency icon
                  Icon(
                    Icons.warning_rounded,
                    size: 100,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    '🚨 PANIC ALERT 🚨',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Message
                  Text(
                    'Emergency button pressed!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Timestamp
                  if (widget.alertData['timestamp'] != null)
                    Text(
                      TimeUtils.formatTimestamp(
                        widget.alertData['timestamp'],
                        format: 'MMM dd, yyyy h:mm:ss a',
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 8),

                  // Location if available
                  if (widget.alertData['location'] != null)
                    Text(
                      'Location: ${widget.alertData['location']['latitude']?.toStringAsFixed(6)}, '
                      '${widget.alertData['location']['longitude']?.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: 24),

                  // Countdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '$_remainingSeconds seconds',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dismiss button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: Icon(Icons.close, size: 24),
                    label: Text(
                      'DISMISS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: widget.onDismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
