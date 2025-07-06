part of 'text_recognition_cubit.dart';

/// Text recognition processing modes
enum TextRecognitionMode {
  /// Process static images from gallery or camera
  static,

  /// Process live camera feed
  live,
}

/// State for text recognition functionality
class TextRecognitionState extends Equatable {
  const TextRecognitionState({
    this.mode = TextRecognitionMode.static,
    this.isLiveCameraActive = false,
    this.image,
    this.recognizedText,
    this.timestamp,
    this.textRecognitionDataState = const DataState.initial(),
    this.previousState,
  });

  /// Current processing mode
  final TextRecognitionMode mode;

  /// Whether live camera is currently active
  final bool isLiveCameraActive;

  /// Current image being processed (for static mode)
  final File? image;

  /// Recognized text results
  final List<TextRecognitionResult>? recognizedText;

  /// Timestamp of last recognition
  final DateTime? timestamp;

  /// Data state for UI feedback
  final DataState<List<TextRecognitionResult>> textRecognitionDataState;

  /// Previous state for retry functionality
  final TextRecognitionState? previousState;

  /// Whether we have recognized text results
  bool get hasRecognizedText =>
      recognizedText != null && recognizedText!.isNotEmpty;

  /// Count of recognized text blocks
  int get recognizedTextCount => recognizedText?.length ?? 0;

  /// Get all recognized text as a single string
  String get allRecognizedText {
    if (recognizedText == null || recognizedText!.isEmpty) return '';
    return recognizedText!.map((result) => result.text).join('\n');
  }

  /// Copy with method for state updates
  TextRecognitionState copyWith({
    TextRecognitionMode? mode,
    bool? isLiveCameraActive,
    File? Function()? image,
    List<TextRecognitionResult>? Function()? recognizedText,
    DateTime? Function()? timestamp,
    DataState<List<TextRecognitionResult>>? textRecognitionDataState,
    TextRecognitionState? previousState,
  }) {
    return TextRecognitionState(
      mode: mode ?? this.mode,
      isLiveCameraActive: isLiveCameraActive ?? this.isLiveCameraActive,
      image: image != null ? image() : this.image,
      recognizedText:
          recognizedText != null ? recognizedText() : this.recognizedText,
      timestamp: timestamp != null ? timestamp() : this.timestamp,
      textRecognitionDataState:
          textRecognitionDataState ?? this.textRecognitionDataState,
      previousState: previousState ?? this.previousState,
    );
  }

  @override
  List<Object?> get props => [
    mode,
    isLiveCameraActive,
    image,
    recognizedText,
    timestamp,
    textRecognitionDataState,
    previousState,
  ];
}
