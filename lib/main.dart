import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/audio_recording.dart';
import 'services/local_storage_service.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/audio_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/panic_alert_provider.dart';
import 'utils/time_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('⚠️ .env file not found, using default values');
  }
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(AudioRecordingAdapter());
  
  // Open the audio recordings box before app starts
  await Hive.openBox<AudioRecording>('audio_recordings');
  
  // Initialize local storage service (for telemetry, alerts, activity)
  try {
    await LocalStorageService().initialize();
    print('✅ Local storage initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize local storage: $e');
  }
  
  runApp(const ProviderScope(child: SmartPendantApp()));
}

class SmartPendantApp extends ConsumerStatefulWidget {
  const SmartPendantApp({super.key});

  @override
  ConsumerState<SmartPendantApp> createState() => _SmartPendantAppState();
}

class _SmartPendantAppState extends ConsumerState<SmartPendantApp> {
  @override
  void initState() {
    super.initState();
    // Initialize panic alert provider after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(panicAlertProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch panic alert state
    final panicAlertState = ref.watch(panicAlertProvider);

    return MaterialApp(
      title: 'Smart Pendant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: Stack(
        children: [
          // Main app navigation
          Navigator(
            onGenerateRoute: (settings) {
              Widget page;
              switch (settings.name) {
                case '/map':
                  page = const MapScreen();
                  break;
                case '/camera':
                  page = const CameraScreen();
                  break;
                case '/audio':
                  page = const AudioScreen();
                  break;
                case '/activity':
                  page = const ActivityScreen();
                  break;
                case '/sos':
                  page = const SosScreen();
                  break;
                case '/settings':
                  page = const SettingsScreen();
                  break;
                default:
                  page = const HomeScreen();
              }
              return MaterialPageRoute(builder: (_) => page);
            },
          ),
          
          // Panic alert overlay (shows on top of everything)
          if (panicAlertState.isAlerting && panicAlertState.currentAlert != null)
            _PanicAlertOverlay(
              alertData: panicAlertState.currentAlert!,
              onDismiss: () {
                ref.read(panicAlertProvider.notifier).dismissAlert();
              },
            ),
        ],
      ),
    );
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
  int _remainingSeconds = 5;
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
                  const Icon(
                    Icons.warning_rounded,
                    size: 100,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
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
                  const Text(
                    'Emergency button pressed!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Timestamp in Asia/Manila timezone (same format as home screen)
                  if (widget.alertData['timestamp'] != null)
                    Text(
                      TimeUtils.formatTimestamp(widget.alertData['timestamp'], format: 'MMM dd, yyyy h:mm:ss a'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 4),

                  // Location if available
                  if (widget.alertData['location'] != null)
                    Text(
                      'Location: ${widget.alertData['location']['latitude']?.toStringAsFixed(6)}, '
                      '${widget.alertData['location']['longitude']?.toStringAsFixed(6)}',
                      style: const TextStyle(
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
                      style: const TextStyle(
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
                    icon: const Icon(Icons.close, size: 24),
                    label: const Text(
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
