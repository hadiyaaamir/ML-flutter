import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Represents a text recognition result with bounding box and confidence
class TextRecognitionResult extends Equatable {
  const TextRecognitionResult({
    required this.text,
    required this.boundingBox,
    required this.confidence,
    this.language,
    this.textBlocks = const [],
  });

  /// The recognized text
  final String text;

  /// Bounding box of the text
  final Rect boundingBox;

  /// Confidence score (0.0 to 1.0)
  final double confidence;

  /// Detected language (if available)
  final String? language;

  /// Individual text blocks for detailed analysis
  final List<TextBlock> textBlocks;

  /// Create from ML Kit RecognizedText
  factory TextRecognitionResult.fromRecognizedText(
    RecognizedText recognizedText,
  ) {
    // Calculate overall bounding box from all text blocks
    Rect? overallBoundingBox;
    double totalConfidence = 0.0;
    int elementCount = 0;

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          if (overallBoundingBox == null) {
            overallBoundingBox = element.boundingBox;
          } else {
            overallBoundingBox = overallBoundingBox.expandToInclude(
              element.boundingBox,
            );
          }
          totalConfidence += element.confidence ?? 0.0;
          elementCount++;
        }
      }
    }

    final averageConfidence =
        elementCount > 0 ? totalConfidence / elementCount : 0.0;

    return TextRecognitionResult(
      text: recognizedText.text,
      boundingBox: overallBoundingBox ?? Rect.zero,
      confidence: averageConfidence,
      textBlocks: recognizedText.blocks,
    );
  }

  /// Get confidence as percentage string
  String get confidencePercentage =>
      '${(confidence * 100).toStringAsFixed(1)}%';

  /// Check if text contains specific pattern
  bool containsPattern(String pattern) {
    return text.toLowerCase().contains(pattern.toLowerCase());
  }

  /// Get text blocks by type (if needed for specific analysis)
  List<TextBlock> getTextBlocksContaining(String pattern) {
    return textBlocks
        .where(
          (block) => block.text.toLowerCase().contains(pattern.toLowerCase()),
        )
        .toList();
  }

  @override
  List<Object?> get props => [
    text,
    boundingBox,
    confidence,
    language,
    textBlocks,
  ];
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
