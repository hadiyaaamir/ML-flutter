import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Types of face filters available
enum FaceFilterType {
  none,
  googlyEyes,
  mustache,
  sunglasses,
  hat,
  clownNose,
  beard,
  eyepatch,
  crown,
  bunnyEars,
}

/// Configuration for a face filter
class FaceFilter {
  const FaceFilter({
    required this.type,
    required this.name,
    required this.icon,
    required this.description,
    this.color = Colors.blue,
  });

  final FaceFilterType type;
  final String name;
  final IconData icon;
  final String description;
  final Color color;

  /// Get all available filters
  static const List<FaceFilter> allFilters = [
    FaceFilter(
      type: FaceFilterType.none,
      name: 'None',
      icon: Icons.clear,
      description: 'No filter',
      color: Colors.grey,
    ),
    FaceFilter(
      type: FaceFilterType.googlyEyes,
      name: 'Googly Eyes',
      icon: Icons.visibility,
      description: 'Fun googly eyes',
      color: Colors.orange,
    ),
    FaceFilter(
      type: FaceFilterType.mustache,
      name: 'Mustache',
      icon: Icons.face,
      description: 'Classic mustache',
      color: Colors.brown,
    ),
    FaceFilter(
      type: FaceFilterType.sunglasses,
      name: 'Sunglasses',
      icon: Icons.wb_sunny,
      description: 'Cool sunglasses',
      color: Colors.black,
    ),
    FaceFilter(
      type: FaceFilterType.hat,
      name: 'Top Hat',
      icon: Icons.celebration,
      description: 'Fancy top hat',
      color: Colors.purple,
    ),
    FaceFilter(
      type: FaceFilterType.clownNose,
      name: 'Clown Nose',
      icon: Icons.sentiment_very_satisfied,
      description: 'Red clown nose',
      color: Colors.red,
    ),
    FaceFilter(
      type: FaceFilterType.beard,
      name: 'Beard',
      icon: Icons.face_2,
      description: 'Full beard',
      color: Colors.brown,
    ),
    FaceFilter(
      type: FaceFilterType.eyepatch,
      name: 'Eyepatch',
      icon: Icons.remove_red_eye,
      description: 'Pirate eyepatch',
      color: Colors.black,
    ),
    FaceFilter(
      type: FaceFilterType.crown,
      name: 'Crown',
      icon: Icons.star,
      description: 'Royal crown',
      color: Colors.yellow,
    ),
    FaceFilter(
      type: FaceFilterType.bunnyEars,
      name: 'Bunny Ears',
      icon: Icons.pets,
      description: 'Cute bunny ears',
      color: Colors.pink,
    ),
  ];

  /// Get filter by type
  static FaceFilter getFilter(FaceFilterType type) {
    return allFilters.firstWhere((filter) => filter.type == type);
  }
}

/// Helper class for calculating filter positions and sizes
class FilterPositionHelper {
  /// Calculate googly eyes positions and sizes
  static List<FilterElement> calculateGooglyEyes(Face face) {
    final elements = <FilterElement>[];

    // Left eye
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    if (leftEye != null) {
      final eyeSize = _calculateEyeSize(face);
      elements.add(
        FilterElement(
          type: FilterElementType.googlyEye,
          position: Offset(
            leftEye.position.x.toDouble(),
            leftEye.position.y.toDouble(),
          ),
          size: Size(eyeSize, eyeSize),
          rotation: 0,
          isLeft: true,
        ),
      );
    }

    // Right eye
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    if (rightEye != null) {
      final eyeSize = _calculateEyeSize(face);
      elements.add(
        FilterElement(
          type: FilterElementType.googlyEye,
          position: Offset(
            rightEye.position.x.toDouble(),
            rightEye.position.y.toDouble(),
          ),
          size: Size(eyeSize, eyeSize),
          rotation: 0,
          isLeft: false,
        ),
      );
    }

    return elements;
  }

  /// Calculate mustache position and size
  static List<FilterElement> calculateMustache(Face face) {
    final elements = <FilterElement>[];

    final noseBase = face.landmarks[FaceLandmarkType.noseBase];
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];

    if (noseBase != null && bottomMouth != null) {
      final faceWidth = face.boundingBox.width;
      final mustacheWidth = faceWidth * 0.3;
      final mustacheHeight = mustacheWidth * 0.4;

      // Position closer to the nose base, not between nose and mouth
      final x = noseBase.position.x.toDouble();
      final y =
          noseBase.position.y.toDouble() +
          (faceWidth * 0.05); // Just below nose

      elements.add(
        FilterElement(
          type: FilterElementType.mustache,
          position: Offset(x, y),
          size: Size(mustacheWidth, mustacheHeight),
          rotation: face.headEulerAngleZ ?? 0,
        ),
      );
    }

    return elements;
  }

  /// Calculate sunglasses position and size
  static List<FilterElement> calculateSunglasses(Face face) {
    final elements = <FilterElement>[];

    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    if (leftEye != null && rightEye != null) {
      final faceWidth = face.boundingBox.width;
      final glassesWidth = faceWidth * 0.8;
      final glassesHeight = glassesWidth * 0.4;

      // Center between eyes, slightly higher
      final centerX =
          (leftEye.position.x.toDouble() + rightEye.position.x.toDouble()) / 2;
      final centerY =
          (leftEye.position.y.toDouble() + rightEye.position.y.toDouble()) / 2 -
          (faceWidth * 0.02);

      // Calculate proper rotation based on the angle between the eyes
      final deltaX =
          rightEye.position.x.toDouble() - leftEye.position.x.toDouble();
      final deltaY =
          rightEye.position.y.toDouble() - leftEye.position.y.toDouble();
      final eyeAngle = math.atan2(deltaY, deltaX) * 180 / math.pi;

      elements.add(
        FilterElement(
          type: FilterElementType.sunglasses,
          position: Offset(centerX, centerY),
          size: Size(glassesWidth, glassesHeight),
          rotation: eyeAngle, // Use eye-line angle for natural tilt
        ),
      );
    }

    return elements;
  }

  /// Calculate hat position and size
  static List<FilterElement> calculateHat(Face face) {
    final elements = <FilterElement>[];

    final faceWidth = face.boundingBox.width;
    final hatWidth = faceWidth * 0.9;
    final hatHeight = hatWidth * 0.8;

    // Position slightly higher above the head
    final x = face.boundingBox.center.dx;
    final y =
        face.boundingBox.top - hatHeight * 0.2; // Moved up from 0.1 to 0.2

    elements.add(
      FilterElement(
        type: FilterElementType.hat,
        position: Offset(x, y),
        size: Size(hatWidth, hatHeight),
        rotation: face.headEulerAngleZ ?? 0,
      ),
    );

    return elements;
  }

  /// Calculate clown nose position and size
  static List<FilterElement> calculateClownNose(Face face) {
    final elements = <FilterElement>[];

    final noseBase = face.landmarks[FaceLandmarkType.noseBase];
    if (noseBase != null) {
      final faceWidth = face.boundingBox.width;
      final noseSize = faceWidth * 0.12; // Slightly smaller

      // Position directly on the nose base
      elements.add(
        FilterElement(
          type: FilterElementType.clownNose,
          position: Offset(
            noseBase.position.x.toDouble(),
            noseBase.position.y.toDouble(),
          ),
          size: Size(noseSize, noseSize),
          rotation: 0,
        ),
      );
    }

    return elements;
  }

  /// Calculate beard position and size
  static List<FilterElement> calculateBeard(Face face) {
    final elements = <FilterElement>[];

    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];
    if (bottomMouth != null) {
      final faceWidth = face.boundingBox.width;
      final beardWidth = faceWidth * 0.7;
      final beardHeight = beardWidth * 0.8;

      // Position below mouth
      final x = bottomMouth.position.x.toDouble();
      final y = bottomMouth.position.y.toDouble() + beardHeight * 0.3;

      elements.add(
        FilterElement(
          type: FilterElementType.beard,
          position: Offset(x, y),
          size: Size(beardWidth, beardHeight),
          rotation: face.headEulerAngleZ ?? 0,
        ),
      );
    }

    return elements;
  }

  /// Calculate eyepatch position and size (on left eye)
  static List<FilterElement> calculateEyepatch(Face face) {
    final elements = <FilterElement>[];

    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    if (leftEye != null) {
      final eyeSize = _calculateEyeSize(face) * 1.2; // Slightly smaller

      elements.add(
        FilterElement(
          type: FilterElementType.eyepatch,
          position: Offset(
            leftEye.position.x.toDouble(),
            leftEye.position.y.toDouble(),
          ),
          size: Size(eyeSize, eyeSize),
          rotation: face.headEulerAngleZ ?? 0,
        ),
      );
    }

    return elements;
  }

  /// Calculate crown position and size
  static List<FilterElement> calculateCrown(Face face) {
    final elements = <FilterElement>[];

    final faceWidth = face.boundingBox.width;
    final crownWidth = faceWidth * 1.0; // Slightly smaller
    final crownHeight = crownWidth * 0.5; // Shorter

    // Position slightly higher above the head
    final x = face.boundingBox.center.dx;
    final y =
        face.boundingBox.top - crownHeight * 0.3; // Moved up from 0.1 to 0.3

    elements.add(
      FilterElement(
        type: FilterElementType.crown,
        position: Offset(x, y),
        size: Size(crownWidth, crownHeight),
        rotation: face.headEulerAngleZ ?? 0,
      ),
    );

    return elements;
  }

  /// Calculate bunny ears position and size
  static List<FilterElement> calculateBunnyEars(Face face) {
    final elements = <FilterElement>[];

    final faceWidth = face.boundingBox.width;
    final earWidth = faceWidth * 0.2; // Smaller
    final earHeight = earWidth * 1.8; // Shorter

    // Left ear - closer to head
    final leftX = face.boundingBox.left + faceWidth * 0.25;
    final leftY = face.boundingBox.top - earHeight * 0.2; // Much closer
    elements.add(
      FilterElement(
        type: FilterElementType.bunnyEar,
        position: Offset(leftX, leftY),
        size: Size(earWidth, earHeight),
        rotation: (face.headEulerAngleZ ?? 0) - 15,
        isLeft: true,
      ),
    );

    // Right ear - closer to head
    final rightX = face.boundingBox.right - faceWidth * 0.25;
    final rightY = face.boundingBox.top - earHeight * 0.2; // Much closer
    elements.add(
      FilterElement(
        type: FilterElementType.bunnyEar,
        position: Offset(rightX, rightY),
        size: Size(earWidth, earHeight),
        rotation: (face.headEulerAngleZ ?? 0) + 15,
        isLeft: false,
      ),
    );

    return elements;
  }

  /// Helper method to calculate eye size based on face dimensions
  static double _calculateEyeSize(Face face) {
    final faceWidth = face.boundingBox.width;
    return faceWidth * 0.18; // 18% of face width
  }

  /// Get filter elements for a specific filter type
  static List<FilterElement> getFilterElements(FaceFilterType type, Face face) {
    switch (type) {
      case FaceFilterType.none:
        return [];
      case FaceFilterType.googlyEyes:
        return calculateGooglyEyes(face);
      case FaceFilterType.mustache:
        return calculateMustache(face);
      case FaceFilterType.sunglasses:
        return calculateSunglasses(face);
      case FaceFilterType.hat:
        return calculateHat(face);
      case FaceFilterType.clownNose:
        return calculateClownNose(face);
      case FaceFilterType.beard:
        return calculateBeard(face);
      case FaceFilterType.eyepatch:
        return calculateEyepatch(face);
      case FaceFilterType.crown:
        return calculateCrown(face);
      case FaceFilterType.bunnyEars:
        return calculateBunnyEars(face);
    }
  }
}

/// Types of filter elements
enum FilterElementType {
  googlyEye,
  mustache,
  sunglasses,
  hat,
  clownNose,
  beard,
  eyepatch,
  crown,
  bunnyEar,
}

/// Individual filter element with position and properties
class FilterElement {
  const FilterElement({
    required this.type,
    required this.position,
    required this.size,
    this.rotation = 0,
    this.opacity = 1.0,
    this.isLeft = false,
  });

  final FilterElementType type;
  final Offset position;
  final Size size;
  final double rotation;
  final double opacity;
  final bool isLeft; // For distinguishing left/right elements (eyes, ears)
}
