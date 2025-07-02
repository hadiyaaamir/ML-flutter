import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../cubit/cubit.dart';

/// Reusable camera preview widget for ML media operations
class MLCameraPreview extends StatefulWidget {
  const MLCameraPreview({
    super.key,
    this.title = 'Live Camera Feed',
    this.showSwitchButton = true,
    this.maxHeight = 400.0,
  });

  /// Title for the camera preview section
  final String title;

  /// Whether to show the camera switch button
  final bool showSwitchButton;

  /// Maximum height for the camera preview
  final double maxHeight;

  @override
  State<MLCameraPreview> createState() => _MLCameraPreviewState();
}

class _MLCameraPreviewState extends State<MLCameraPreview> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MLMediaCubit, MLMediaState>(
      builder: (context, state) {
        final cubit = context.read<MLMediaCubit>();

        if (!state.isLiveCameraActive) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (widget.showSwitchButton)
                      IconButton(
                        onPressed: () => cubit.switchCamera(),
                        icon: const Icon(Icons.switch_camera),
                        tooltip: 'Switch Camera',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxHeight: widget.maxHeight),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const _CameraPreviewWidget(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CameraPreviewWidget extends StatefulWidget {
  const _CameraPreviewWidget();

  @override
  State<_CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<_CameraPreviewWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MLMediaCubit, MLMediaState>(
      builder: (context, state) {
        final cubit = context.read<MLMediaCubit>();
        final cameraController = cubit.cameraController;

        if (cameraController == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Initializing camera...'),
              ],
            ),
          );
        }

        if (!cameraController.value.isInitialized) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Setting up camera...'),
              ],
            ),
          );
        }

        // Wrap CameraPreview in error handling and use a key to force rebuild on camera switch
        return Builder(
          key: ValueKey(
            '${cameraController.description.name}_${state.timestamp?.millisecondsSinceEpoch}',
          ),
          builder: (context) {
            try {
              // Double-check that controller is still valid before building preview
              if (cameraController.value.isInitialized) {
                // Get the camera's aspect ratio to prevent squishing
                final aspectRatio = cameraController.value.aspectRatio;

                return AspectRatio(
                  aspectRatio: aspectRatio,
                  child: OverflowBox(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: cameraController.value.previewSize?.height ?? 1,
                        height: cameraController.value.previewSize?.width ?? 1,
                        child: CameraPreview(cameraController),
                      ),
                    ),
                  ),
                );
              } else {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text('Camera not ready'),
                    ],
                  ),
                );
              }
            } catch (e) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Camera error: ${e.toString()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed:
                          () => context.read<MLMediaCubit>().switchMode(
                            MLMediaMode.live,
                          ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }
}
