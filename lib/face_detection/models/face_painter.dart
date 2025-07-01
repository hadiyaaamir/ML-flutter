import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Custom painter to draw face detection results
class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final ui.Image? image;
  final bool showContours;
  final bool showLabels;

  FacePainter({
    required this.faces,
    required this.imageSize,
    this.image,
    this.showContours = true,
    this.showLabels = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (image != null) {
      // Calculate how to fit the image in the container (similar to BoxFit.contain)
      final imageAspectRatio = image!.width / image!.height;
      final containerAspectRatio = size.width / size.height;

      double drawWidth, drawHeight, offsetX, offsetY;

      if (imageAspectRatio > containerAspectRatio) {
        // Image is wider than container - fit to width
        drawWidth = size.width;
        drawHeight = size.width / imageAspectRatio;
        offsetX = 0;
        offsetY = (size.height - drawHeight) / 2;
      } else {
        // Image is taller than container - fit to height
        drawHeight = size.height;
        drawWidth = size.height * imageAspectRatio;
        offsetX = (size.width - drawWidth) / 2;
        offsetY = 0;
      }

      // Draw the image to fit the container
      canvas.drawImageRect(
        image!,
        Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
        Rect.fromLTWH(offsetX, offsetY, drawWidth, drawHeight),
        Paint(),
      );

      // Update scaling factors based on the actual drawn image size
      final scaleX = drawWidth / image!.width;
      final scaleY = drawHeight / image!.height;

      // Draw face detection overlays with proper scaling and offset
      _drawFaceOverlays(canvas, scaleX, scaleY, offsetX, offsetY);
    }
  }

  void _drawFaceOverlays(
    Canvas canvas,
    double scaleX,
    double scaleY,
    double offsetX,
    double offsetY,
  ) {
    // Paint for face rectangles
    final facePaint =
        Paint()
          ..color = Colors.green
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;

    // Paint for contours
    final contourPaint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    // Paint for text
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    for (final face in faces) {
      // Draw face bounding box with offset (only if showLabels is true)
      if (showLabels) {
        final rect = Rect.fromLTRB(
          face.boundingBox.left * scaleX + offsetX,
          face.boundingBox.top * scaleY + offsetY,
          face.boundingBox.right * scaleX + offsetX,
          face.boundingBox.bottom * scaleY + offsetY,
        );
        canvas.drawRect(rect, facePaint);

        // Draw face ID if tracking is enabled
        if (face.trackingId != null) {
          final textPainter = TextPainter(
            text: TextSpan(text: 'ID: ${face.trackingId}', style: textStyle),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(rect.left, rect.top - 20));
        }

        // Draw classification results (smiling, eyes open/closed)
        String classificationText = '';
        if (face.smilingProbability != null) {
          final smiling =
              face.smilingProbability! > 0.5 ? 'Smiling' : 'Not Smiling';
          classificationText +=
              '$smiling (${(face.smilingProbability! * 100).toInt()}%) ';
        }
        if (face.leftEyeOpenProbability != null &&
            face.rightEyeOpenProbability != null) {
          final leftEyeOpen = face.leftEyeOpenProbability! > 0.5;
          final rightEyeOpen = face.rightEyeOpenProbability! > 0.5;
          if (leftEyeOpen && rightEyeOpen) {
            classificationText += '\nEyes Open';
          } else if (!leftEyeOpen && !rightEyeOpen) {
            classificationText += '\nEyes Closed';
          } else {
            classificationText += '\nOne Eye Closed';
          }
        }

        if (classificationText.isNotEmpty) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: classificationText,
              style: textStyle.copyWith(fontSize: 10),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(rect.left, rect.bottom + 5));
        }
      }

      // Draw contours with offset (independent of showLabels)
      for (final contour in face.contours.values) {
        if (contour != null && showContours) {
          final path = Path();
          bool isFirst = true;
          for (final point in contour.points) {
            final scaledPoint = Offset(
              point.x * scaleX + offsetX,
              point.y * scaleY + offsetY,
            );
            if (isFirst) {
              path.moveTo(scaledPoint.dx, scaledPoint.dy);
              isFirst = false;
            } else {
              path.lineTo(scaledPoint.dx, scaledPoint.dy);
            }
          }
          canvas.drawPath(path, contourPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is FacePainter &&
        (oldDelegate.faces != faces ||
            oldDelegate.imageSize != imageSize ||
            oldDelegate.showContours != showContours ||
            oldDelegate.showLabels != showLabels);
  }
}

/// Custom painter specifically for live camera face detection overlay
class LiveCameraFacePainter extends CustomPainter {
  final List<Face> faces;
  final Size cameraPreviewSize; // This is the displayed preview size (rotated)
  final Size containerSize;
  final bool showContours;
  final bool showLabels;

  LiveCameraFacePainter({
    required this.faces,
    required this.cameraPreviewSize,
    required this.containerSize,
    this.showContours = true,
    this.showLabels = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // The camera preview is displayed with AspectRatio and BoxFit.cover
    // We need to calculate the actual visible camera preview area within the container

    final previewAspectRatio =
        cameraPreviewSize.width / cameraPreviewSize.height;

    // The camera preview is constrained by AspectRatio widget
    // Calculate the actual displayed camera preview size within the container
    double actualPreviewWidth, actualPreviewHeight;

    if (size.width / size.height > previewAspectRatio) {
      // Container is wider than preview aspect ratio
      // Preview height fills the container height
      actualPreviewHeight = size.height;
      actualPreviewWidth = size.height * previewAspectRatio;
    } else {
      // Container is taller than preview aspect ratio
      // Preview width fills the container width
      actualPreviewWidth = size.width;
      actualPreviewHeight = size.width / previewAspectRatio;
    }

    // Center the preview within the container
    final previewOffsetX = (size.width - actualPreviewWidth) / 2;
    final previewOffsetY = (size.height - actualPreviewHeight) / 2;

    // Now calculate scaling within the actual preview area
    // The camera preview uses BoxFit.cover within its own area
    final cameraAspectRatio =
        cameraPreviewSize.width / cameraPreviewSize.height;
    final previewDisplayRatio = actualPreviewWidth / actualPreviewHeight;

    double scaleX, scaleY, cropOffsetX, cropOffsetY;

    if (cameraAspectRatio > previewDisplayRatio) {
      // Camera is wider - fit to height, crop sides
      scaleY = actualPreviewHeight / cameraPreviewSize.height;
      scaleX = scaleY;

      final scaledWidth = cameraPreviewSize.width * scaleX;
      cropOffsetX = (actualPreviewWidth - scaledWidth) / 2;
      cropOffsetY = 0;
    } else {
      // Camera is taller - fit to width, crop top/bottom
      scaleX = actualPreviewWidth / cameraPreviewSize.width;
      scaleY = scaleX;

      final scaledHeight = cameraPreviewSize.height * scaleY;
      cropOffsetX = 0;
      cropOffsetY = (actualPreviewHeight - scaledHeight) / 2;
    }

    // Final transformation: preview offset + crop offset
    final finalOffsetX = previewOffsetX + cropOffsetX;
    final finalOffsetY = previewOffsetY + cropOffsetY;

    // Draw face detection overlays with correct scaling and offset
    _drawFaceOverlaysFixed(
      canvas,
      scaleX,
      scaleY,
      finalOffsetX,
      finalOffsetY,
      size,
    );
  }

  void _drawFaceOverlaysFixed(
    Canvas canvas,
    double scaleX,
    double scaleY,
    double offsetX,
    double offsetY,
    Size containerSize,
  ) {
    // Paint for face rectangles
    final facePaint =
        Paint()
          ..color = Colors.green
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;

    // Paint for contours
    final contourPaint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    // Paint for text
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    for (final face in faces) {
      // Apply coordinate transformation (no crop adjustment needed now)
      if (showLabels) {
        final rect = Rect.fromLTRB(
          face.boundingBox.left * scaleX + offsetX,
          face.boundingBox.top * scaleY + offsetY,
          face.boundingBox.right * scaleX + offsetX,
          face.boundingBox.bottom * scaleY + offsetY,
        );
        canvas.drawRect(rect, facePaint);

        // Draw face ID if tracking is enabled
        if (face.trackingId != null) {
          final textPainter = TextPainter(
            text: TextSpan(text: 'ID: ${face.trackingId}', style: textStyle),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(rect.left, rect.top - 20));
        }

        // Draw classification results (smiling, eyes open/closed)
        String classificationText = '';
        if (face.smilingProbability != null) {
          final smiling =
              face.smilingProbability! > 0.5 ? 'Smiling' : 'Not Smiling';
          classificationText +=
              '$smiling (${(face.smilingProbability! * 100).toInt()}%) ';
        }
        if (face.leftEyeOpenProbability != null &&
            face.rightEyeOpenProbability != null) {
          final leftEyeOpen = face.leftEyeOpenProbability! > 0.5;
          final rightEyeOpen = face.rightEyeOpenProbability! > 0.5;
          if (leftEyeOpen && rightEyeOpen) {
            classificationText += '\nEyes Open';
          } else if (!leftEyeOpen && !rightEyeOpen) {
            classificationText += '\nEyes Closed';
          } else {
            classificationText += '\nOne Eye Closed';
          }
        }

        if (classificationText.isNotEmpty) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: classificationText,
              style: textStyle.copyWith(fontSize: 10),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(rect.left, rect.bottom + 5));
        }
      }

      // Draw contours
      if (showContours) {
        for (final contour in face.contours.values) {
          if (contour != null) {
            final path = Path();
            bool isFirst = true;
            for (final point in contour.points) {
              final scaledPoint = Offset(
                point.x * scaleX + offsetX,
                point.y * scaleY + offsetY,
              );
              if (isFirst) {
                path.moveTo(scaledPoint.dx, scaledPoint.dy);
                isFirst = false;
              } else {
                path.lineTo(scaledPoint.dx, scaledPoint.dy);
              }
            }
            canvas.drawPath(path, contourPaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is LiveCameraFacePainter &&
        (oldDelegate.faces != faces ||
            oldDelegate.cameraPreviewSize != cameraPreviewSize ||
            oldDelegate.containerSize != containerSize ||
            oldDelegate.showContours != showContours ||
            oldDelegate.showLabels != showLabels);
  }
}
