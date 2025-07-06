import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

/// Represents a detected object with its bounding box and classification
class ObjectDetectionResult extends Equatable {
  const ObjectDetectionResult({
    required this.boundingBox,
    required this.labels,
    required this.trackingId,
  });

  /// The bounding box of the detected object
  final Rect boundingBox;

  /// List of possible labels for this object with confidence scores
  final List<DetectedObjectLabel> labels;

  /// Unique tracking ID for this object (useful for video/live detection)
  final int? trackingId;

  /// Create ObjectDetectionResult from ML Kit DetectedObject
  factory ObjectDetectionResult.fromDetectedObject(
    DetectedObject detectedObject,
  ) {
    return ObjectDetectionResult(
      boundingBox: detectedObject.boundingBox,
      trackingId: detectedObject.trackingId,
      labels:
          detectedObject.labels
              .map((label) => DetectedObjectLabel.fromLabel(label))
              .toList(),
    );
  }

  /// Get the most confident label
  DetectedObjectLabel? get topLabel {
    if (labels.isEmpty) return null;
    return labels.reduce((a, b) => a.confidence > b.confidence ? a : b);
  }

  /// Get formatted confidence percentage for the top label
  String get confidencePercentage {
    final topLabelConfidence = topLabel?.confidence ?? 0.0;
    return '${(topLabelConfidence * 100).toStringAsFixed(1)}%';
  }

  @override
  List<Object?> get props => [boundingBox, labels, trackingId];

  @override
  String toString() =>
      'ObjectDetectionResult('
      'boundingBox: $boundingBox, '
      'labels: $labels, '
      'trackingId: $trackingId)';
}

/// Represents a label for a detected object
class DetectedObjectLabel extends Equatable {
  const DetectedObjectLabel({
    required this.text,
    required this.confidence,
    required this.index,
  });

  /// The label text (e.g., "person", "car", "bicycle")
  final String text;

  /// Confidence score (0.0 to 1.0)
  final double confidence;

  /// Label index from the model
  final int index;

  /// Create DetectedObjectLabel from ML Kit Label
  factory DetectedObjectLabel.fromLabel(Label label) {
    return DetectedObjectLabel(
      text: label.text,
      confidence: label.confidence,
      index: label.index,
    );
  }

  /// Get formatted confidence percentage
  String get confidencePercentage =>
      '${(confidence * 100).toStringAsFixed(1)}%';

  @override
  List<Object> get props => [text, confidence, index];

  @override
  String toString() =>
      'DetectedObjectLabel('
      'text: $text, '
      'confidence: $confidence, '
      'index: $index)';
}
