part of 'models.dart';

/// Represents a single label result from image labelling
class LabelResult extends Equatable {
  final String label;
  final double confidence;
  final int? index;

  const LabelResult({
    required this.label,
    required this.confidence,
    this.index,
  });

  /// Creates a LabelResult from Google ML Kit ImageLabel
  factory LabelResult.fromImageLabel(dynamic imageLabel) {
    return LabelResult(
      label: imageLabel.label,
      confidence: imageLabel.confidence,
      index: imageLabel.index,
    );
  }

  /// Returns confidence as a percentage string
  String get confidencePercentage =>
      '${(confidence * 100).toStringAsFixed(1)}%';

  /// Returns true if confidence is above threshold (default 50%)
  bool isConfident([double threshold = 0.5]) => confidence >= threshold;

  @override
  List<Object?> get props => [label, confidence, index];

  @override
  String toString() =>
      'LabelResult(label: $label, confidence: $confidencePercentage)';
}
