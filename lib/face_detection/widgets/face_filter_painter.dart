import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/face_filter.dart';

/// Custom painter for drawing face filters
class FaceFilterPainter extends CustomPainter {
  FaceFilterPainter({
    required this.faces,
    required this.imageSize,
    required this.filterType,
    this.showBoundingBoxes = false,
  });

  final List<Face> faces;
  final Size imageSize;
  final FaceFilterType filterType;
  final bool showBoundingBoxes;

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate scale factors
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    for (final face in faces) {
      // Draw bounding box if enabled
      if (showBoundingBoxes) {
        _drawBoundingBox(canvas, face, scaleX, scaleY);
      }

      // Draw filter elements
      if (filterType != FaceFilterType.none) {
        final filterElements = FilterPositionHelper.getFilterElements(
          filterType,
          face,
        );
        for (final element in filterElements) {
          _drawFilterElement(canvas, element, scaleX, scaleY);
        }
      }
    }
  }

  void _drawBoundingBox(
    Canvas canvas,
    Face face,
    double scaleX,
    double scaleY,
  ) {
    final paint =
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final rect = Rect.fromLTRB(
      face.boundingBox.left * scaleX,
      face.boundingBox.top * scaleY,
      face.boundingBox.right * scaleX,
      face.boundingBox.bottom * scaleY,
    );

    canvas.drawRect(rect, paint);
  }

  void _drawFilterElement(
    Canvas canvas,
    FilterElement element,
    double scaleX,
    double scaleY,
  ) {
    final scaledPosition = Offset(
      element.position.dx * scaleX,
      element.position.dy * scaleY,
    );
    final scaledSize = Size(
      element.size.width * scaleX,
      element.size.height * scaleY,
    );

    canvas.save();

    // Translate to the element position
    canvas.translate(scaledPosition.dx, scaledPosition.dy);

    // Rotate if needed
    if (element.rotation != 0) {
      canvas.rotate(element.rotation * math.pi / 180);
    }

    // Draw the filter element
    switch (element.type) {
      case FilterElementType.googlyEye:
        _drawGooglyEye(canvas, scaledSize, element.opacity);
        break;
      case FilterElementType.mustache:
        _drawMustache(canvas, scaledSize, element.opacity);
        break;
      case FilterElementType.sunglasses:
        _drawSunglasses(canvas, scaledSize, element.opacity);
        break;
      case FilterElementType.hat:
        _drawHat(canvas, scaledSize, element.opacity);
        break;
      case FilterElementType.clownNose:
        _drawClownNose(canvas, scaledSize, element.opacity);
        break;
      case FilterElementType.beard:
        _drawBeard(canvas, scaledSize, element.opacity);
        break;
      case FilterElementType.eyepatch:
        _drawEyepatch(canvas, scaledSize, element.opacity);
        break;
      case FilterElementType.crown:
        _drawCrown(canvas, scaledSize, element.opacity);
        break;
      case FilterElementType.bunnyEar:
        _drawBunnyEar(canvas, scaledSize, element.opacity);
        break;
    }

    canvas.restore();
  }

  void _drawGooglyEye(Canvas canvas, Size size, double opacity) {
    final center = Offset(0, 0);
    final radius = size.width / 2;

    // White eye background
    final eyePaint =
        Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, eyePaint);

    // Black eye border
    final borderPaint =
        Paint()
          ..color = Colors.black.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius, borderPaint);

    // Black pupil (randomly positioned for googly effect)
    final pupilRadius = radius * 0.4;
    final maxOffset = radius - pupilRadius;
    final pupilOffset = Offset(
      (math.Random().nextDouble() - 0.5) * maxOffset,
      (math.Random().nextDouble() - 0.5) * maxOffset,
    );

    final pupilPaint =
        Paint()
          ..color = Colors.black.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(pupilOffset, pupilRadius, pupilPaint);
  }

  void _drawMustache(Canvas canvas, Size size, double opacity) {
    final paint =
        Paint()
          ..color = Colors.brown.shade800.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

    final path = Path();
    final width = size.width;
    final height = size.height;

    // Draw mustache shape
    path.moveTo(-width / 2, 0);
    path.quadraticBezierTo(-width / 4, -height / 2, 0, -height / 4);
    path.quadraticBezierTo(width / 4, -height / 2, width / 2, 0);
    path.quadraticBezierTo(width / 4, height / 2, 0, height / 4);
    path.quadraticBezierTo(-width / 4, height / 2, -width / 2, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawSunglasses(Canvas canvas, Size size, double opacity) {
    final glassPaint =
        Paint()
          ..color = Colors.black.withValues(alpha: opacity * 0.8)
          ..style = PaintingStyle.fill;

    final framePaint =
        Paint()
          ..color = Colors.black.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

    final width = size.width;
    final height = size.height;
    final lensRadius = height * 0.4;

    // Left lens
    final leftCenter = Offset(-width * 0.25, 0);
    canvas.drawCircle(leftCenter, lensRadius, glassPaint);
    canvas.drawCircle(leftCenter, lensRadius, framePaint);

    // Right lens
    final rightCenter = Offset(width * 0.25, 0);
    canvas.drawCircle(rightCenter, lensRadius, glassPaint);
    canvas.drawCircle(rightCenter, lensRadius, framePaint);

    // Bridge
    canvas.drawLine(
      Offset(-width * 0.25 + lensRadius, 0),
      Offset(width * 0.25 - lensRadius, 0),
      framePaint,
    );
  }

  void _drawHat(Canvas canvas, Size size, double opacity) {
    final hatPaint =
        Paint()
          ..color = Colors.black.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

    final bandPaint =
        Paint()
          ..color = Colors.red.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;

    // Hat brim
    final brimRect = Rect.fromCenter(
      center: Offset(0, height * 0.3),
      width: width,
      height: height * 0.15,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(brimRect, const Radius.circular(8)),
      hatPaint,
    );

    // Hat top
    final topRect = Rect.fromCenter(
      center: Offset(0, -height * 0.1),
      width: width * 0.6,
      height: height * 0.8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(topRect, const Radius.circular(12)),
      hatPaint,
    );

    // Hat band
    final bandRect = Rect.fromCenter(
      center: Offset(0, height * 0.15),
      width: width * 0.65,
      height: height * 0.1,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bandRect, const Radius.circular(4)),
      bandPaint,
    );
  }

  void _drawClownNose(Canvas canvas, Size size, double opacity) {
    final nosePaint =
        Paint()
          ..color = Colors.red.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

    final highlightPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.6)
          ..style = PaintingStyle.fill;

    final radius = size.width / 2;

    // Red nose
    canvas.drawCircle(Offset(0, 0), radius, nosePaint);

    // White highlight
    canvas.drawCircle(
      Offset(-radius * 0.3, -radius * 0.3),
      radius * 0.3,
      highlightPaint,
    );
  }

  void _drawBeard(Canvas canvas, Size size, double opacity) {
    final beardPaint =
        Paint()
          ..color = Colors.brown.shade700.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;

    final path = Path();

    // Draw beard shape
    path.moveTo(-width / 2, -height / 4);
    path.quadraticBezierTo(-width / 3, height / 3, 0, height / 2);
    path.quadraticBezierTo(width / 3, height / 3, width / 2, -height / 4);
    path.quadraticBezierTo(width / 4, -height / 2, 0, -height / 3);
    path.quadraticBezierTo(-width / 4, -height / 2, -width / 2, -height / 4);
    path.close();

    canvas.drawPath(path, beardPaint);
  }

  void _drawEyepatch(Canvas canvas, Size size, double opacity) {
    final patchPaint =
        Paint()
          ..color = Colors.black.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

    final stringPaint =
        Paint()
          ..color = Colors.brown.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final radius = size.width / 2;

    // Black eyepatch
    canvas.drawCircle(Offset(0, 0), radius, patchPaint);

    // String lines
    canvas.drawLine(
      Offset(-radius, 0),
      Offset(-radius * 2, -radius * 0.5),
      stringPaint,
    );
    canvas.drawLine(
      Offset(radius, 0),
      Offset(radius * 2, -radius * 0.5),
      stringPaint,
    );
  }

  void _drawCrown(Canvas canvas, Size size, double opacity) {
    final crownPaint =
        Paint()
          ..color = Colors.amber.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

    final jewelPaint =
        Paint()
          ..color = Colors.red.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;

    final path = Path();

    // Crown base
    path.moveTo(-width / 2, height / 4);
    path.lineTo(-width / 3, -height / 3);
    path.lineTo(-width / 6, -height / 6);
    path.lineTo(0, -height / 2);
    path.lineTo(width / 6, -height / 6);
    path.lineTo(width / 3, -height / 3);
    path.lineTo(width / 2, height / 4);
    path.close();

    canvas.drawPath(path, crownPaint);

    // Crown jewels
    canvas.drawCircle(Offset(0, -height * 0.25), width * 0.05, jewelPaint);
    canvas.drawCircle(
      Offset(-width * 0.2, -height * 0.15),
      width * 0.03,
      jewelPaint,
    );
    canvas.drawCircle(
      Offset(width * 0.2, -height * 0.15),
      width * 0.03,
      jewelPaint,
    );
  }

  void _drawBunnyEar(Canvas canvas, Size size, double opacity) {
    final earPaint =
        Paint()
          ..color = Colors.pink.shade200.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

    final innerPaint =
        Paint()
          ..color = Colors.pink.shade100.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;

    // Outer ear
    final outerPath = Path();
    outerPath.moveTo(0, height / 2);
    outerPath.quadraticBezierTo(
      -width / 4,
      height / 4,
      -width / 6,
      -height / 4,
    );
    outerPath.quadraticBezierTo(-width / 8, -height / 2, 0, -height / 2);
    outerPath.quadraticBezierTo(width / 8, -height / 2, width / 6, -height / 4);
    outerPath.quadraticBezierTo(width / 4, height / 4, 0, height / 2);
    outerPath.close();

    canvas.drawPath(outerPath, earPaint);

    // Inner ear
    final innerPath = Path();
    innerPath.moveTo(0, height / 3);
    innerPath.quadraticBezierTo(
      -width / 8,
      height / 6,
      -width / 12,
      -height / 6,
    );
    innerPath.quadraticBezierTo(-width / 16, -height / 3, 0, -height / 3);
    innerPath.quadraticBezierTo(
      width / 16,
      -height / 3,
      width / 12,
      -height / 6,
    );
    innerPath.quadraticBezierTo(width / 8, height / 6, 0, height / 3);
    innerPath.close();

    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant FaceFilterPainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.filterType != filterType ||
        oldDelegate.showBoundingBoxes != showBoundingBoxes;
  }
}
