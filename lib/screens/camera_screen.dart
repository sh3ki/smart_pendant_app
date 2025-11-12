import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/camera_provider.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  bool _autoRefresh = false;

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        actions: [
          IconButton(
            icon: Icon(_autoRefresh ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _autoRefresh = !_autoRefresh;
              });
              if (_autoRefresh) {
                ref.read(cameraProvider.notifier).startAutoRefresh();
              } else {
                ref.read(cameraProvider.notifier).stopAutoRefresh();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: cameraState.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: cameraState.imageUrl!,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 48, color: Colors.red),
                          const SizedBox(height: 8),
                          Text('Failed to load image', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      fit: BoxFit.contain,
                    )
                  : Container(
                      width: 320,
                      height: 240,
                      color: Colors.grey[300],
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No image available'),
                        ],
                      ),
                    ),
            ),
          ),
          if (cameraState.timestamp != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    'Last updated: ${cameraState.timestamp}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (cameraState.frameNumber != null)
                    Text(
                      'Frame #${cameraState.frameNumber}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: cameraState.isLoading
                        ? null
                        : () => ref.read(cameraProvider.notifier).requestSnapshot(),
                    icon: cameraState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera),
                    label: const Text('Request Snapshot'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

