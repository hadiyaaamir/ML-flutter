import 'dart:math' show acos, pi, sqrt;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Represents a pose detection result with landmarks and confidence
class PoseDetectionResult extends Equatable {
  const PoseDetectionResult({
    required this.landmarks,
    required this.boundingBox,
    required this.confidence,
    this.poseId,
  });

  /// Map of pose landmarks with their positions
  final Map<PoseLandmarkType, PoseLandmark> landmarks;

  /// Bounding box containing the entire pose
  final Rect boundingBox;

  /// Overall confidence score (0.0 to 1.0)
  final double confidence;

  /// Unique identifier for the pose (if available)
  final String? poseId;

  /// Create from ML Kit Pose
  factory PoseDetectionResult.fromPose(Pose pose) {
    // Calculate overall bounding box from all landmarks
    Rect? overallBoundingBox;
    double totalConfidence = 0.0;
    int landmarkCount = 0;

    for (final landmark in pose.landmarks.values) {
      final point = Offset(landmark.x, landmark.y);
      final landmarkRect = Rect.fromCenter(center: point, width: 1, height: 1);

      if (overallBoundingBox == null) {
        overallBoundingBox = landmarkRect;
      } else {
        overallBoundingBox = overallBoundingBox.expandToInclude(landmarkRect);
      }

      totalConfidence += landmark.likelihood;
      landmarkCount++;
    }

    final averageConfidence =
        landmarkCount > 0 ? totalConfidence / landmarkCount : 0.0;

    return PoseDetectionResult(
      landmarks: pose.landmarks,
      boundingBox: overallBoundingBox ?? Rect.zero,
      confidence: averageConfidence,
    );
  }

  /// Get confidence as percentage string
  String get confidencePercentage =>
      '${(confidence * 100).toStringAsFixed(1)}%';

  /// Get specific landmark if available
  PoseLandmark? getLandmark(PoseLandmarkType type) {
    return landmarks[type];
  }

  /// Check if pose has all major body landmarks
  bool get hasFullBody {
    final majorLandmarks = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    return majorLandmarks.every((type) => landmarks.containsKey(type));
  }

  /// Get landmarks for face (if available)
  List<PoseLandmark> get faceLandmarks {
    final faceTypes = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftEyeInner,
      PoseLandmarkType.leftEye,
      PoseLandmarkType.leftEyeOuter,
      PoseLandmarkType.rightEyeInner,
      PoseLandmarkType.rightEye,
      PoseLandmarkType.rightEyeOuter,
      PoseLandmarkType.leftEar,
      PoseLandmarkType.rightEar,
    ];

    return faceTypes
        .where((type) => landmarks.containsKey(type))
        .map((type) => landmarks[type]!)
        .toList();
  }

  /// Get landmarks for upper body
  List<PoseLandmark> get upperBodyLandmarks {
    final upperBodyTypes = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
    ];

    return upperBodyTypes
        .where((type) => landmarks.containsKey(type))
        .map((type) => landmarks[type]!)
        .toList();
  }

  /// Get landmarks for lower body
  List<PoseLandmark> get lowerBodyLandmarks {
    final lowerBodyTypes = [
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    return lowerBodyTypes
        .where((type) => landmarks.containsKey(type))
        .map((type) => landmarks[type]!)
        .toList();
  }

  /// Get landmarks that are visible (likelihood > 0.5)
  List<PoseLandmark> get visibleLandmarks {
    return landmarks.values
        .where((landmark) => landmark.likelihood > 0.5)
        .toList();
  }

  /// Calculate angle between three landmarks (useful for pose analysis)
  double? calculateAngle(
    PoseLandmarkType point1,
    PoseLandmarkType point2,
    PoseLandmarkType point3,
  ) {
    final landmark1 = landmarks[point1];
    final landmark2 = landmarks[point2];
    final landmark3 = landmarks[point3];

    if (landmark1 == null || landmark2 == null || landmark3 == null) {
      return null;
    }

    final vector1 = Offset(
      landmark1.x - landmark2.x,
      landmark1.y - landmark2.y,
    );
    final vector2 = Offset(
      landmark3.x - landmark2.x,
      landmark3.y - landmark2.y,
    );

    final dotProduct = vector1.dx * vector2.dx + vector1.dy * vector2.dy;
    final magnitude1 = sqrt(vector1.dx * vector1.dx + vector1.dy * vector1.dy);
    final magnitude2 = sqrt(vector2.dx * vector2.dx + vector2.dy * vector2.dy);

    if (magnitude1 == 0 || magnitude2 == 0) return null;

    final cosAngle = dotProduct / (magnitude1 * magnitude2);
    final angle = acos(cosAngle.clamp(-1.0, 1.0)) * 180 / pi;

    return angle;
  }

  @override
  List<Object?> get props => [landmarks, boundingBox, confidence, poseId];
}

/// Extension to expand Rect to include another Rect
extension RectExtension on Rect {
  Rect expandToInclude(Rect other) {
    return Rect.fromLTRB(
      left < other.left ? left : other.left,
      top < other.top ? top : other.top,
      right > other.right ? right : other.right,
      bottom > other.bottom ? bottom : other.bottom,
    );
  }
}
