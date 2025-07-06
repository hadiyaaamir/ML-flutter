import 'dart:io';
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
    as mlkit;
import 'package:ml_flutter/pose_detection/cubit/pose_detection_cubit.dart';
import 'package:ml_flutter/pose_detection/models/pose_detection_result.dart';
import 'package:ml_flutter/ml_media/ml_media.dart';

/// Main view for pose detection functionality
class PoseDetectionView extends StatelessWidget {
  const PoseDetectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pose Detection'), centerTitle: true),
      body: BlocBuilder<PoseDetectionCubit, PoseDetectionState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PoseDetectionModeToggle(),
                _PoseDetectionStatusCard(),
                _CameraOrActionSection(),
                _DetectedPosesResults(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Custom mode toggle for pose detection
class _PoseDetectionModeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MLModeToggle(title: 'Pose Detection Mode');
  }
}

/// Custom status card for pose detection
class _PoseDetectionStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PoseDetectionCubit, PoseDetectionState>(
      builder: (context, state) {
        String statusText;
        Color statusColor;
        IconData statusIcon;
        bool showLoading = false;

        if (state.mode == PoseDetectionMode.live) {
          // Live camera mode status
          if (state.isLiveCameraActive) {
            if (state.detectedPoses != null &&
                state.detectedPoses!.isNotEmpty) {
              final count = state.detectedPoses!.length;
              statusText =
                  'Live Detection: $count pose${count == 1 ? '' : 's'} detected';
              statusColor = Colors.green;
              statusIcon = Icons.accessibility_new;
            } else {
              statusText = 'Live camera active - Looking for poses...';
              statusColor = Colors.blue;
              statusIcon = Icons.videocam;
            }
          } else {
            statusText = 'Ready to start live pose detection';
            statusColor = Colors.blue;
            statusIcon = Icons.videocam;
          }
        } else {
          // Static image mode status
          if (state.poseDetectionDataState.isLoading) {
            statusText = 'Detecting poses...';
            statusColor = Colors.orange;
            statusIcon = Icons.hourglass_empty;
            showLoading = true;
          } else if (state.poseDetectionDataState.isFailure) {
            statusText =
                state.poseDetectionDataState.errorMessage ?? 'Error occurred';
            statusColor = Colors.red;
            statusIcon = Icons.error;
          } else if (state.detectedPoses != null &&
              state.detectedPoses!.isNotEmpty) {
            final count = state.detectedPoses!.length;
            statusText = '$count pose${count == 1 ? '' : 's'} detected';
            statusColor = Colors.green;
            statusIcon = Icons.accessibility_new;
          } else if (state.image != null) {
            statusText = 'No poses detected';
            statusColor = Colors.grey;
            statusIcon = Icons.accessibility_new_outlined;
          } else {
            statusText = 'Ready to detect poses';
            statusColor = Colors.blue;
            statusIcon = Icons.camera_alt;
          }
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (showLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Section that shows either camera preview (live mode) or action buttons (static mode)
class _CameraOrActionSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PoseDetectionCubit, PoseDetectionState>(
      builder: (context, state) {
        if (state.mode == PoseDetectionMode.live) {
          return _PoseDetectionCameraPreview();
        } else {
          return Column(
            children: [
              _PoseDetectionActionButtons(),
              const SizedBox(height: 16),
              _PoseDetectionImageDisplay(),
            ],
          );
        }
      },
    );
  }
}

/// Custom camera preview for pose detection
class _PoseDetectionCameraPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PoseDetectionCubit, PoseDetectionState>(
      builder: (context, state) {
        if (!state.isLiveCameraActive) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with title and switch camera button
                Row(
                  children: [
                    const Text(
                      'Live Pose Detection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed:
                          () => context.read<MLMediaCubit>().switchCamera(),
                      icon: const Icon(Icons.switch_camera),
                      tooltip: 'Switch Camera',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Camera preview with pose detection overlay
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _CameraPreviewWithOverlay(),
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

/// Camera preview widget with pose overlay
class _CameraPreviewWithOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MLMediaCubit, MLMediaState>(
      builder: (context, mlMediaState) {
        return BlocBuilder<PoseDetectionCubit, PoseDetectionState>(
          builder: (context, poseState) {
            final cameraController =
                context.read<MLMediaCubit>().cameraController;

            if (cameraController == null ||
                !cameraController.value.isInitialized) {
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

            return AspectRatio(
              aspectRatio: cameraController.value.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(cameraController),
                  if (poseState.detectedPoses != null &&
                      poseState.detectedPoses!.isNotEmpty)
                    CustomPaint(
                      painter: _LiveCameraPosePainter(
                        poses: poseState.detectedPoses!,
                        cameraController: cameraController,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Custom action buttons for pose detection
class _PoseDetectionActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MLActionButtons(
      captureButtonText: 'Capture Image',
      galleryButtonText: 'Select Image',
      retryButtonText: 'Try Another Image',
    );
  }
}

/// Custom image display for pose detection
class _PoseDetectionImageDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PoseDetectionCubit, PoseDetectionState>(
      builder: (context, state) {
        if (state.image == null) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Captured Image',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return FutureBuilder<Size>(
                          future: _getImageSize(state.image!),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final imageSize = snapshot.data!;
                            final aspectRatio =
                                imageSize.width / imageSize.height;

                            return AspectRatio(
                              aspectRatio: aspectRatio,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // The image
                                  Image.file(state.image!, fit: BoxFit.contain),
                                  // Pose overlay
                                  if (state.detectedPoses != null &&
                                      state.detectedPoses!.isNotEmpty)
                                    CustomPaint(
                                      painter: _StaticImagePosePainter(
                                        poses: state.detectedPoses!,
                                        imageSize: imageSize,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Size> _getImageSize(File imageFile) async {
    final image = Image.file(imageFile);
    final imageStream = image.image.resolve(const ImageConfiguration());
    final completer = Completer<Size>();

    imageStream.addListener(
      ImageStreamListener((imageInfo, _) {
        final size = Size(
          imageInfo.image.width.toDouble(),
          imageInfo.image.height.toDouble(),
        );
        completer.complete(size);
      }),
    );

    return completer.future;
  }
}

/// Display detected poses results
class _DetectedPosesResults extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PoseDetectionCubit, PoseDetectionState>(
      builder: (context, state) {
        if (state.detectedPoses == null || state.detectedPoses!.isEmpty) {
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
                    const Icon(
                      Icons.accessibility_new,
                      color: Colors.deepPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Detected Poses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.detectedPoses!.length} pose${state.detectedPoses!.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...state.detectedPoses!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final poseResult = entry.value;
                  return _PoseResultCard(poseResult: poseResult, index: index);
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Individual pose result card
class _PoseResultCard extends StatelessWidget {
  const _PoseResultCard({required this.poseResult, required this.index});

  final PoseDetectionResult poseResult;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.accessibility_new,
                  color: Colors.deepPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pose ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Confidence: ${poseResult.confidencePercentage}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PoseInfoItem(
                  icon: Icons.location_on,
                  label: 'Total Landmarks',
                  value: '${poseResult.landmarks.length}',
                ),
              ),
              Expanded(
                child: _PoseInfoItem(
                  icon: Icons.visibility,
                  label: 'Visible Landmarks',
                  value: '${poseResult.visibleLandmarks.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PoseInfoItem(
                  icon: Icons.face,
                  label: 'Face Points',
                  value: '${poseResult.faceLandmarks.length}',
                ),
              ),
              Expanded(
                child: _PoseInfoItem(
                  icon: Icons.accessibility,
                  label: 'Full Body',
                  value: poseResult.hasFullBody ? 'Yes' : 'No',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual pose information item
class _PoseInfoItem extends StatelessWidget {
  const _PoseInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '$label: $value',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for live camera pose overlay
class _LiveCameraPosePainter extends CustomPainter {
  final List<PoseDetectionResult> poses;
  final CameraController cameraController;

  _LiveCameraPosePainter({required this.poses, required this.cameraController});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.deepPurple
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    final pointPaint =
        Paint()
          ..color = Colors.deepPurple
          ..strokeWidth = 4.0
          ..style = PaintingStyle.fill;

    for (final poseResult in poses) {
      // Draw pose landmarks
      for (final landmark in poseResult.visibleLandmarks) {
        final point = _transformPoint(
          Offset(landmark.x, landmark.y),
          size,
          cameraController.value.previewSize!,
        );
        canvas.drawCircle(point, 3, pointPaint);
      }

      // Draw pose connections
      _drawPoseConnections(canvas, poseResult, size, paint);
    }
  }

  void _drawPoseConnections(
    Canvas canvas,
    PoseDetectionResult poseResult,
    Size size,
    Paint paint,
  ) {
    // Define pose connections (simplified skeleton)
    final connections = [
      // Head
      [mlkit.PoseLandmarkType.nose, mlkit.PoseLandmarkType.leftEye],
      [mlkit.PoseLandmarkType.nose, mlkit.PoseLandmarkType.rightEye],
      [mlkit.PoseLandmarkType.leftEye, mlkit.PoseLandmarkType.leftEar],
      [mlkit.PoseLandmarkType.rightEye, mlkit.PoseLandmarkType.rightEar],

      // Torso
      [
        mlkit.PoseLandmarkType.leftShoulder,
        mlkit.PoseLandmarkType.rightShoulder,
      ],
      [mlkit.PoseLandmarkType.leftShoulder, mlkit.PoseLandmarkType.leftHip],
      [mlkit.PoseLandmarkType.rightShoulder, mlkit.PoseLandmarkType.rightHip],
      [mlkit.PoseLandmarkType.leftHip, mlkit.PoseLandmarkType.rightHip],

      // Arms
      [mlkit.PoseLandmarkType.leftShoulder, mlkit.PoseLandmarkType.leftElbow],
      [mlkit.PoseLandmarkType.leftElbow, mlkit.PoseLandmarkType.leftWrist],
      [mlkit.PoseLandmarkType.rightShoulder, mlkit.PoseLandmarkType.rightElbow],
      [mlkit.PoseLandmarkType.rightElbow, mlkit.PoseLandmarkType.rightWrist],

      // Legs
      [mlkit.PoseLandmarkType.leftHip, mlkit.PoseLandmarkType.leftKnee],
      [mlkit.PoseLandmarkType.leftKnee, mlkit.PoseLandmarkType.leftAnkle],
      [mlkit.PoseLandmarkType.rightHip, mlkit.PoseLandmarkType.rightKnee],
      [mlkit.PoseLandmarkType.rightKnee, mlkit.PoseLandmarkType.rightAnkle],
    ];

    for (final connection in connections) {
      final landmark1 = poseResult.landmarks[connection[0]];
      final landmark2 = poseResult.landmarks[connection[1]];

      if (landmark1 != null &&
          landmark2 != null &&
          landmark1.likelihood > 0.5 &&
          landmark2.likelihood > 0.5) {
        final point1 = _transformPoint(
          Offset(landmark1.x, landmark1.y),
          size,
          cameraController.value.previewSize!,
        );
        final point2 = _transformPoint(
          Offset(landmark2.x, landmark2.y),
          size,
          cameraController.value.previewSize!,
        );
        canvas.drawLine(point1, point2, paint);
      }
    }
  }

  Offset _transformPoint(Offset point, Size widgetSize, Size previewSize) {
    final double scaleX = widgetSize.width / previewSize.height;
    final double scaleY = widgetSize.height / previewSize.width;

    return Offset(widgetSize.width - (point.dy * scaleX), point.dx * scaleY);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for static image pose overlay
class _StaticImagePosePainter extends CustomPainter {
  final List<PoseDetectionResult> poses;
  final Size imageSize;

  _StaticImagePosePainter({required this.poses, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.deepPurple
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;

    final pointPaint =
        Paint()
          ..color = Colors.deepPurple
          ..strokeWidth = 6.0
          ..style = PaintingStyle.fill;

    // Calculate how the image is positioned within the widget
    final imageAspectRatio = imageSize.width / imageSize.height;
    final widgetAspectRatio = size.width / size.height;

    double scaleX, scaleY, offsetX = 0, offsetY = 0;

    if (imageAspectRatio > widgetAspectRatio) {
      // Image is wider than widget, so it's scaled to fit width
      scaleX = size.width / imageSize.width;
      scaleY = scaleX; // Maintain aspect ratio
      offsetY = (size.height - (imageSize.height * scaleY)) / 2;
    } else {
      // Image is taller than widget, so it's scaled to fit height
      scaleY = size.height / imageSize.height;
      scaleX = scaleY; // Maintain aspect ratio
      offsetX = (size.width - (imageSize.width * scaleX)) / 2;
    }

    for (final poseResult in poses) {
      // Draw pose landmarks
      for (final landmark in poseResult.visibleLandmarks) {
        final point = Offset(
          landmark.x * scaleX + offsetX,
          landmark.y * scaleY + offsetY,
        );
        canvas.drawCircle(point, 4, pointPaint);
      }

      // Draw pose connections
      _drawPoseConnections(
        canvas,
        poseResult,
        paint,
        scaleX,
        scaleY,
        offsetX,
        offsetY,
      );
    }
  }

  void _drawPoseConnections(
    Canvas canvas,
    PoseDetectionResult poseResult,
    Paint paint,
    double scaleX,
    double scaleY,
    double offsetX,
    double offsetY,
  ) {
    // Define pose connections (simplified skeleton)
    final connections = [
      // Head
      [mlkit.PoseLandmarkType.nose, mlkit.PoseLandmarkType.leftEye],
      [mlkit.PoseLandmarkType.nose, mlkit.PoseLandmarkType.rightEye],
      [mlkit.PoseLandmarkType.leftEye, mlkit.PoseLandmarkType.leftEar],
      [mlkit.PoseLandmarkType.rightEye, mlkit.PoseLandmarkType.rightEar],

      // Torso
      [
        mlkit.PoseLandmarkType.leftShoulder,
        mlkit.PoseLandmarkType.rightShoulder,
      ],
      [mlkit.PoseLandmarkType.leftShoulder, mlkit.PoseLandmarkType.leftHip],
      [mlkit.PoseLandmarkType.rightShoulder, mlkit.PoseLandmarkType.rightHip],
      [mlkit.PoseLandmarkType.leftHip, mlkit.PoseLandmarkType.rightHip],

      // Arms
      [mlkit.PoseLandmarkType.leftShoulder, mlkit.PoseLandmarkType.leftElbow],
      [mlkit.PoseLandmarkType.leftElbow, mlkit.PoseLandmarkType.leftWrist],
      [mlkit.PoseLandmarkType.rightShoulder, mlkit.PoseLandmarkType.rightElbow],
      [mlkit.PoseLandmarkType.rightElbow, mlkit.PoseLandmarkType.rightWrist],

      // Legs
      [mlkit.PoseLandmarkType.leftHip, mlkit.PoseLandmarkType.leftKnee],
      [mlkit.PoseLandmarkType.leftKnee, mlkit.PoseLandmarkType.leftAnkle],
      [mlkit.PoseLandmarkType.rightHip, mlkit.PoseLandmarkType.rightKnee],
      [mlkit.PoseLandmarkType.rightKnee, mlkit.PoseLandmarkType.rightAnkle],
    ];

    for (final connection in connections) {
      final landmark1 = poseResult.landmarks[connection[0]];
      final landmark2 = poseResult.landmarks[connection[1]];

      if (landmark1 != null &&
          landmark2 != null &&
          landmark1.likelihood > 0.5 &&
          landmark2.likelihood > 0.5) {
        final point1 = Offset(
          landmark1.x * scaleX + offsetX,
          landmark1.y * scaleY + offsetY,
        );
        final point2 = Offset(
          landmark2.x * scaleX + offsetX,
          landmark2.y * scaleY + offsetY,
        );
        canvas.drawLine(point1, point2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
