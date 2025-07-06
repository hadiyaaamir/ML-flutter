import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import 'package:ml_flutter/ml_media/ml_media.dart';
import 'package:ml_flutter/text_recognition/text_recognition.dart';

/// Main view for text recognition functionality
class TextRecognitionView extends StatelessWidget {
  const TextRecognitionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Text Recognition'), centerTitle: true),
      body: BlocBuilder<TextRecognitionCubit, TextRecognitionState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TextRecognitionModeToggle(),
                _TextRecognitionStatusCard(),
                _CameraOrActionSection(),
                _RecognizedTextResults(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Custom mode toggle for text recognition
class _TextRecognitionModeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MLModeToggle(title: 'Text Recognition Mode');
  }
}

/// Custom status card for text recognition
class _TextRecognitionStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextRecognitionCubit, TextRecognitionState>(
      builder: (context, state) {
        String statusText;
        Color statusColor;
        IconData statusIcon;
        bool showLoading = false;

        if (state.mode == TextRecognitionMode.live) {
          // Live camera mode status
          if (state.isLiveCameraActive) {
            if (state.hasRecognizedText) {
              final count = state.recognizedTextCount;
              statusText =
                  'Live Recognition: $count text block${count == 1 ? '' : 's'} detected';
              statusColor = Colors.green;
              statusIcon = Icons.text_fields;
            } else {
              statusText = 'Live camera active - Looking for text...';
              statusColor = Colors.blue;
              statusIcon = Icons.videocam;
            }
          } else {
            statusText = 'Ready to start live text recognition';
            statusColor = Colors.blue;
            statusIcon = Icons.videocam;
          }
        } else {
          // Static image mode status
          if (state.textRecognitionDataState.isLoading) {
            statusText = 'Recognizing text...';
            statusColor = Colors.orange;
            statusIcon = Icons.hourglass_empty;
            showLoading = true;
          } else if (state.textRecognitionDataState.isFailure) {
            statusText =
                state.textRecognitionDataState.errorMessage ?? 'Error occurred';
            statusColor = Colors.red;
            statusIcon = Icons.error;
          } else if (state.hasRecognizedText) {
            final count = state.recognizedTextCount;
            statusText = '$count text block${count == 1 ? '' : 's'} recognized';
            statusColor = Colors.green;
            statusIcon = Icons.text_fields;
          } else if (state.image != null) {
            statusText = 'No text detected';
            statusColor = Colors.grey;
            statusIcon = Icons.text_fields_outlined;
          } else {
            statusText = 'Ready to recognize text';
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
    return BlocBuilder<TextRecognitionCubit, TextRecognitionState>(
      builder: (context, state) {
        if (state.mode == TextRecognitionMode.live) {
          return _TextRecognitionCameraPreview();
        } else {
          return Column(
            children: [
              _TextRecognitionActionButtons(),
              const SizedBox(height: 16),
              _TextRecognitionImageDisplay(),
            ],
          );
        }
      },
    );
  }
}

/// Custom camera preview for text recognition
class _TextRecognitionCameraPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextRecognitionCubit, TextRecognitionState>(
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
                      'Live Text Recognition',
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
                // Camera preview with text recognition overlay
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _TextRecognitionCameraPreviewWidget(),
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

/// Specialized camera preview widget with text recognition overlay
class _TextRecognitionCameraPreviewWidget extends StatefulWidget {
  @override
  State<_TextRecognitionCameraPreviewWidget> createState() =>
      _TextRecognitionCameraPreviewWidgetState();
}

class _TextRecognitionCameraPreviewWidgetState
    extends State<_TextRecognitionCameraPreviewWidget> {
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

                return BlocBuilder<TextRecognitionCubit, TextRecognitionState>(
                  builder: (context, textState) {
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

                          // Text recognition overlay
                          if (textState.recognizedText != null &&
                              textState.recognizedText!.isNotEmpty) ...[
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final containerSize = Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                );
                                final previewSize =
                                    cameraController.value.previewSize;

                                if (previewSize != null) {
                                  // Use the original camera dimensions for text recognition
                                  final cameraImageSize = Size(
                                    previewSize.width,
                                    previewSize.height,
                                  );

                                  return CustomPaint(
                                    painter: _LiveCameraTextPainter(
                                      recognizedText: textState.recognizedText!,
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

/// Custom painter for drawing text recognition bounding boxes on live camera feed
class _LiveCameraTextPainter extends CustomPainter {
  const _LiveCameraTextPainter({
    required this.recognizedText,
    required this.cameraPreviewSize,
    required this.containerSize,
  });

  final List<TextRecognitionResult> recognizedText;
  final Size cameraPreviewSize;
  final Size containerSize;

  @override
  void paint(Canvas canvas, Size size) {
    // Use the same coordinate transformation logic as object detection
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

    _drawTextOverlays(canvas, scaleX, scaleY, offsetX, offsetY);
  }

  void _drawTextOverlays(
    Canvas canvas,
    double scaleX,
    double scaleY,
    double offsetX,
    double offsetY,
  ) {
    final paint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < recognizedText.length; i++) {
      final textResult = recognizedText[i];
      final boundingBox = textResult.boundingBox;

      // Apply 90-degree clockwise rotation transformation
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

      // Draw recognized text
      final recognizedTextStr =
          textResult.text.length > 20
              ? '${textResult.text.substring(0, 20)}...'
              : textResult.text;

      textPainter.text = TextSpan(
        text: recognizedTextStr,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
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
        Paint()..color = Colors.blue.withValues(alpha: 0.8),
      );

      // Draw text
      textPainter.paint(
        canvas,
        Offset(scaledRect.left + 4, scaledRect.top - textPainter.height - 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom action buttons for text recognition
class _TextRecognitionActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextRecognitionCubit, TextRecognitionState>(
      builder: (context, state) {
        return MLActionButtons(
          captureButtonText: 'Capture Image',
          galleryButtonText: 'Select Image',
          retryButtonText: 'Try Another Image',
          showRetryButton: true,
          hasResults: state.hasRecognizedText,
        );
      },
    );
  }
}

/// Custom image display for text recognition with bounding boxes
class _TextRecognitionImageDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextRecognitionCubit, TextRecognitionState>(
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
                  'Recognized Text Image',
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
                    child: _ImageWithTextBoundingBoxes(
                      imageFile: state.image!,
                      recognizedText: state.recognizedText ?? [],
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

/// Widget that displays an image with text bounding boxes overlaid
class _ImageWithTextBoundingBoxes extends StatelessWidget {
  const _ImageWithTextBoundingBoxes({
    required this.imageFile,
    required this.recognizedText,
  });

  final File imageFile;
  final List<TextRecognitionResult> recognizedText;

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
                  // Text bounding boxes overlay
                  if (recognizedText.isNotEmpty)
                    CustomPaint(
                      painter: _TextBoundingBoxPainter(
                        recognizedText: recognizedText,
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

/// Custom painter for drawing text bounding boxes on static images
class _TextBoundingBoxPainter extends CustomPainter {
  const _TextBoundingBoxPainter({
    required this.recognizedText,
    required this.imageSize,
  });

  final List<TextRecognitionResult> recognizedText;
  final Size imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Calculate scale factors to map from image coordinates to widget coordinates
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    for (int i = 0; i < recognizedText.length; i++) {
      final textResult = recognizedText[i];
      final boundingBox = textResult.boundingBox;

      // Scale bounding box to widget coordinates
      final scaledRect = Rect.fromLTWH(
        boundingBox.left * scaleX,
        boundingBox.top * scaleY,
        boundingBox.width * scaleX,
        boundingBox.height * scaleY,
      );

      // Draw bounding box
      canvas.drawRect(scaledRect, paint);

      // Draw recognized text (truncated if too long)
      final recognizedTextStr =
          textResult.text.length > 30
              ? '${textResult.text.substring(0, 30)}...'
              : textResult.text;

      textPainter.text = TextSpan(
        text: recognizedTextStr,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
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
        Paint()..color = Colors.blue.withValues(alpha: 0.8),
      );

      // Draw text
      textPainter.paint(
        canvas,
        Offset(scaledRect.left + 4, scaledRect.top - textPainter.height - 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Section displaying recognized text results
class _RecognizedTextResults extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextRecognitionCubit, TextRecognitionState>(
      builder: (context, state) {
        if (!state.hasRecognizedText) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recognized Text (${state.recognizedTextCount})',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed:
                      () => _copyAllText(context, state.allRecognizedText),
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy all text',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: state.recognizedText!.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final textResult = state.recognizedText![index];
                  return _TextRecognitionCard(textResult: textResult);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _copyAllText(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Text copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Individual card for displaying text recognition result
class _TextRecognitionCard extends StatelessWidget {
  const _TextRecognitionCard({required this.textResult});

  final TextRecognitionResult textResult;

  @override
  Widget build(BuildContext context) {
    final boundingBox = textResult.boundingBox;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with confidence and copy button
            Row(
              children: [
                Icon(Icons.text_fields, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Confidence: ${textResult.confidencePercentage}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _copyText(context, textResult.text),
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'Copy text',
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),

            // Recognized text
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                textResult.text,
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              ),
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

  void _copyText(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Text copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
