import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import 'package:ml_flutter/ml_media/ml_media.dart';
import 'package:ml_flutter/object_detection/object_detection.dart';

/// Main view for object classification functionality
class ObjectDetectionView extends StatelessWidget {
  const ObjectDetectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Classification'),
        centerTitle: true,
      ),
      body: BlocBuilder<ObjectDetectionCubit, ObjectDetectionState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ObjectDetectionModeToggle(),
                _ObjectDetectionStatusCard(),
                _CameraOrActionSection(),
                _DetectedObjects(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Custom mode toggle for object classification
class _ObjectDetectionModeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MLModeToggle(title: 'Object Classification Mode');
  }
}

/// Custom status card for object classification
class _ObjectDetectionStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectDetectionCubit, ObjectDetectionState>(
      builder: (context, state) {
        String statusText;
        Color statusColor;
        IconData statusIcon;
        bool showLoading = false;

        if (state.mode == ObjectDetectionMode.live) {
          // Live camera mode status
          if (state.isLiveCameraActive) {
            if (state.hasDetectedObjects) {
              final count = state.detectedObjectsCount;
              statusText =
                  'Live Classification: $count object${count == 1 ? '' : 's'} detected';
              statusColor = Colors.green;
              statusIcon = Icons.visibility;
            } else {
              statusText = 'Live camera active - Looking for objects...';
              statusColor = Colors.blue;
              statusIcon = Icons.videocam;
            }
          } else {
            statusText = 'Ready to start live object classification';
            statusColor = Colors.blue;
            statusIcon = Icons.videocam;
          }
        } else {
          // Static image mode status
          if (state.objectDetectionDataState.isLoading) {
            statusText = 'Classifying objects...';
            statusColor = Colors.orange;
            statusIcon = Icons.hourglass_empty;
            showLoading = true;
          } else if (state.objectDetectionDataState.isFailure) {
            statusText =
                state.objectDetectionDataState.errorMessage ?? 'Error occurred';
            statusColor = Colors.red;
            statusIcon = Icons.error;
          } else if (state.hasDetectedObjects) {
            final count = state.detectedObjectsCount;
            statusText = '$count object${count == 1 ? '' : 's'} classified';
            statusColor = Colors.green;
            statusIcon = Icons.label;
          } else if (state.image != null) {
            statusText = 'No objects detected';
            statusColor = Colors.grey;
            statusIcon = Icons.search_off;
          } else {
            statusText = 'Ready to classify objects';
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
    return BlocBuilder<ObjectDetectionCubit, ObjectDetectionState>(
      builder: (context, state) {
        if (state.mode == ObjectDetectionMode.live) {
          return _ObjectDetectionCameraPreview();
        } else {
          return Column(
            children: [
              _ObjectDetectionActionButtons(),
              const SizedBox(height: 16),
              _ObjectDetectionImageDisplay(),
            ],
          );
        }
      },
    );
  }
}

/// Custom camera preview for object classification
class _ObjectDetectionCameraPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectDetectionCubit, ObjectDetectionState>(
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
                      'Live Object Classification',
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
                // Camera preview with object classification overlay
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _ObjectDetectionCameraPreviewWidget(),
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

/// Specialized camera preview widget with object classification overlay
class _ObjectDetectionCameraPreviewWidget extends StatefulWidget {
  @override
  State<_ObjectDetectionCameraPreviewWidget> createState() =>
      _ObjectDetectionCameraPreviewWidgetState();
}

class _ObjectDetectionCameraPreviewWidgetState
    extends State<_ObjectDetectionCameraPreviewWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MLMediaCubit, MLMediaState>(
      builder: (context, mlState) {
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
            '${cameraController.description.name}_${mlState.timestamp?.millisecondsSinceEpoch}',
          ),
          builder: (context) {
            try {
              // Double-check that controller is still valid before building preview
              if (cameraController.value.isInitialized) {
                // Get the camera's aspect ratio to prevent squishing
                final aspectRatio = cameraController.value.aspectRatio;

                return BlocBuilder<ObjectDetectionCubit, ObjectDetectionState>(
                  builder: (context, objectState) {
                    return AspectRatio(
                      aspectRatio: aspectRatio,
                      child: Stack(
                        children: [
                          // Camera preview base
                          OverflowBox(
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width:
                                    cameraController
                                        .value
                                        .previewSize
                                        ?.height ??
                                    1,
                                height:
                                    cameraController.value.previewSize?.width ??
                                    1,
                                child: CameraPreview(cameraController),
                              ),
                            ),
                          ),

                          // Object classification overlay
                          if (objectState.detectedObjects != null &&
                              objectState.detectedObjects!.isNotEmpty) ...[
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final containerSize = Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                );
                                final previewSize =
                                    cameraController.value.previewSize;

                                if (previewSize != null) {
                                  // Use the original camera dimensions (not swapped)
                                  // ML Kit coordinates are in the original camera image space
                                  final cameraImageSize = Size(
                                    previewSize.width,
                                    previewSize.height,
                                  );

                                  return CustomPaint(
                                    painter: _LiveCameraObjectPainter(
                                      detectedObjects:
                                          objectState.detectedObjects!,
                                      cameraPreviewSize: cameraImageSize,
                                      containerSize: containerSize,
                                    ),
                                    child: Container(),
                                  );
                                }
                                return Container();
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
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

/// Custom painter for drawing object classification bounding boxes on live camera feed
class _LiveCameraObjectPainter extends CustomPainter {
  const _LiveCameraObjectPainter({
    required this.detectedObjects,
    required this.cameraPreviewSize,
    required this.containerSize,
  });

  final List<ObjectDetectionResult> detectedObjects;
  final Size cameraPreviewSize;
  final Size containerSize;

  @override
  void paint(Canvas canvas, Size size) {
    // ML Kit returns coordinates in camera image space (e.g., 320x240)
    // The preview is displayed rotated 90 degrees clockwise and uses BoxFit.cover

    // Camera preview dimensions after rotation (240x320 in display space)
    final rotatedCameraWidth = cameraPreviewSize.height; // 240
    final rotatedCameraHeight = cameraPreviewSize.width; // 320

    // Calculate how the camera preview fits within the widget using BoxFit.cover
    final cameraAspectRatio =
        rotatedCameraWidth / rotatedCameraHeight; // 240/320 = 0.75
    final widgetAspectRatio = size.width / size.height;

    double previewWidth, previewHeight, offsetX, offsetY;

    if (widgetAspectRatio > cameraAspectRatio) {
      // Widget is wider than camera - camera height fills widget height, width is cropped
      previewHeight = size.height;
      previewWidth = size.height * cameraAspectRatio;
      offsetX = (size.width - previewWidth) / 2;
      offsetY = 0;
    } else {
      // Widget is taller than camera - camera width fills widget width, height is cropped
      previewWidth = size.width;
      previewHeight = size.width / cameraAspectRatio;
      offsetX = 0;
      offsetY = (size.height - previewHeight) / 2;
    }

    // Scale factors from rotated camera space to actual preview display area
    final scaleX = previewWidth / rotatedCameraWidth;
    final scaleY = previewHeight / rotatedCameraHeight;

    _drawObjectOverlays(canvas, scaleX, scaleY, offsetX, offsetY);
  }

  void _drawObjectOverlays(
    Canvas canvas,
    double scaleX,
    double scaleY,
    double offsetX,
    double offsetY,
  ) {
    final paint =
        Paint()
          ..color = Colors.orange
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < detectedObjects.length; i++) {
      final detection = detectedObjects[i];
      final boundingBox = detection.boundingBox;

      // Apply 90-degree clockwise rotation transformation
      // Original camera coordinates: (x, y) in 320x240 space
      // Rotated display coordinates: (camera_height - y - height, x) in 240x320 space
      final rotatedLeft =
          (cameraPreviewSize.height - boundingBox.bottom) * scaleX + offsetX;
      final rotatedTop = boundingBox.left * scaleY + offsetY;
      final rotatedWidth = boundingBox.height * scaleX;
      final rotatedHeight = boundingBox.width * scaleY;

      final scaledRect = Rect.fromLTWH(
        rotatedLeft,
        rotatedTop,
        rotatedWidth,
        rotatedHeight,
      );

      // Draw bounding box
      canvas.drawRect(scaledRect, paint);

      // Draw label
      final topLabel = detection.topLabel;
      if (topLabel != null) {
        final trackingText =
            detection.trackingId != null ? ' #${detection.trackingId}' : '';
        final labelText =
            '${topLabel.text} (${topLabel.confidencePercentage})$trackingText';

        textPainter.text = TextSpan(
          text: labelText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black),
            ],
          ),
        );

        textPainter.layout();

        // Draw background for text
        final textRect = Rect.fromLTWH(
          scaledRect.left,
          scaledRect.top - textPainter.height - 4,
          textPainter.width + 8,
          textPainter.height + 4,
        );

        canvas.drawRect(
          textRect,
          Paint()..color = Colors.orange.withValues(alpha: 0.8),
        );

        // Draw text
        textPainter.paint(
          canvas,
          Offset(scaledRect.left + 4, scaledRect.top - textPainter.height - 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom action buttons for object classification
class _ObjectDetectionActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectDetectionCubit, ObjectDetectionState>(
      builder: (context, state) {
        return MLActionButtons(
          captureButtonText: 'Capture Image',
          galleryButtonText: 'Select Image',
          retryButtonText: 'Try Another Image',
          showRetryButton: true,
          hasResults: state.hasDetectedObjects,
        );
      },
    );
  }
}

/// Custom image display for object classification with bounding boxes
class _ObjectDetectionImageDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectDetectionCubit, ObjectDetectionState>(
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
                  'Classified Image',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _ImageWithBoundingBoxes(
                      imageFile: state.image!,
                      detectedObjects: state.detectedObjects ?? [],
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
}

/// Widget that displays an image with bounding boxes overlaid
class _ImageWithBoundingBoxes extends StatelessWidget {
  const _ImageWithBoundingBoxes({
    required this.imageFile,
    required this.detectedObjects,
  });

  final File imageFile;
  final List<ObjectDetectionResult> detectedObjects;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FutureBuilder<Size>(
          future: _getImageSize(imageFile),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final imageSize = snapshot.data!;
            final aspectRatio = imageSize.width / imageSize.height;

            return AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The image
                  Image.file(imageFile, fit: BoxFit.contain),
                  // Bounding boxes overlay
                  if (detectedObjects.isNotEmpty)
                    CustomPaint(
                      painter: _BoundingBoxPainter(
                        detectedObjects: detectedObjects,
                        imageSize: imageSize,
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

/// Custom painter for drawing bounding boxes on the image
class _BoundingBoxPainter extends CustomPainter {
  const _BoundingBoxPainter({
    required this.detectedObjects,
    required this.imageSize,
  });

  final List<ObjectDetectionResult> detectedObjects;
  final Size imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.orange
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Calculate scale factors to map from image coordinates to widget coordinates
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    for (int i = 0; i < detectedObjects.length; i++) {
      final detection = detectedObjects[i];
      final boundingBox = detection.boundingBox;

      // Scale bounding box to widget coordinates
      final scaledRect = Rect.fromLTWH(
        boundingBox.left * scaleX,
        boundingBox.top * scaleY,
        boundingBox.width * scaleX,
        boundingBox.height * scaleY,
      );

      // Draw bounding box
      canvas.drawRect(scaledRect, paint);

      // Draw label
      final topLabel = detection.topLabel;
      if (topLabel != null) {
        final trackingText =
            detection.trackingId != null ? ' #${detection.trackingId}' : '';
        final labelText =
            '${topLabel.text} (${topLabel.confidencePercentage})$trackingText';

        textPainter.text = TextSpan(
          text: labelText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black),
            ],
          ),
        );

        textPainter.layout();

        // Draw background for text
        final textRect = Rect.fromLTWH(
          scaledRect.left,
          scaledRect.top - textPainter.height - 4,
          textPainter.width + 8,
          textPainter.height + 4,
        );

        canvas.drawRect(
          textRect,
          Paint()..color = Colors.orange.withValues(alpha: 0.8),
        );

        // Draw text
        textPainter.paint(
          canvas,
          Offset(scaledRect.left + 4, scaledRect.top - textPainter.height - 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Section displaying classified objects
class _DetectedObjects extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectDetectionCubit, ObjectDetectionState>(
      builder: (context, state) {
        if (!state.hasDetectedObjects) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Classified Objects (${state.detectedObjectsCount})',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: state.detectedObjects!.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final detection = state.detectedObjects![index];
                  return _ObjectDetectionCard(detection: detection);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Individual card for displaying object classification result
class _ObjectDetectionCard extends StatelessWidget {
  const _ObjectDetectionCard({required this.detection});

  final ObjectDetectionResult detection;

  @override
  Widget build(BuildContext context) {
    final topLabel = detection.topLabel;
    final boundingBox = detection.boundingBox;
    final trackingText =
        detection.trackingId != null ? ' #${detection.trackingId}' : '';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with main label and confidence
            Row(
              children: [
                Icon(Icons.crop_free, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${topLabel?.text ?? 'Unknown Object'}$trackingText',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    detection.confidencePercentage,
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            // Bounding box info
            const SizedBox(height: 8),
            Text(
              'Position: (${boundingBox.left.toInt()}, ${boundingBox.top.toInt()}) '
              'Size: ${boundingBox.width.toInt()}×${boundingBox.height.toInt()}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
