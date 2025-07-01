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
