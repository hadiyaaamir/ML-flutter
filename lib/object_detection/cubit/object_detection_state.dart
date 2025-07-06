part of 'object_detection_cubit.dart';

/// Enum for object classification modes
enum ObjectDetectionMode { static, live }

/// State for object classification functionality
class ObjectDetectionState extends Equatable {
  const ObjectDetectionState({
    this.mode = ObjectDetectionMode.static,
    this.isLiveCameraActive = false,
    this.image,
    this.detectedObjects,
    this.timestamp,
    this.objectDetectionDataState = const DataState.initial(),
    this.previousState,
  });

  /// Current mode (static image or live camera)
  final ObjectDetectionMode mode;

  /// Whether live camera is currently active
  final bool isLiveCameraActive;

  /// Currently selected/captured image
  final File? image;

  /// List of detected objects in the current image/frame
  final List<ObjectDetectionResult>? detectedObjects;

  /// Timestamp of the last detection
  final DateTime? timestamp;

  /// Data state for object classification operations
  final DataState<List<ObjectDetectionResult>> objectDetectionDataState;

  /// Previous state for retry functionality
  final ObjectDetectionState? previousState;

  /// Whether there are any detected objects
  bool get hasDetectedObjects =>
      detectedObjects != null && detectedObjects!.isNotEmpty;

  /// Count of detected objects
  int get detectedObjectsCount => detectedObjects?.length ?? 0;

  /// Whether the current state is ready for processing
  bool get isReadyForProcessing =>
      !objectDetectionDataState.isLoading && image != null;

  /// Get the most confident detection
  ObjectDetectionResult? get topDetection {
    if (detectedObjects?.isEmpty ?? true) return null;
    return detectedObjects!.reduce((a, b) {
      final aConfidence = a.topLabel?.confidence ?? 0.0;
      final bConfidence = b.topLabel?.confidence ?? 0.0;
      return aConfidence > bConfidence ? a : b;
    });
  }

  /// Create a copy of the state with updated values
  ObjectDetectionState copyWith({
    ObjectDetectionMode? mode,
    bool? isLiveCameraActive,
    File? Function()? image,
    List<ObjectDetectionResult>? Function()? detectedObjects,
    DateTime? Function()? timestamp,
    DataState<List<ObjectDetectionResult>>? objectDetectionDataState,
    ObjectDetectionState? previousState,
  }) {
    return ObjectDetectionState(
      mode: mode ?? this.mode,
      isLiveCameraActive: isLiveCameraActive ?? this.isLiveCameraActive,
      image: image != null ? image() : this.image,
      detectedObjects:
          detectedObjects != null ? detectedObjects() : this.detectedObjects,
      timestamp: timestamp != null ? timestamp() : this.timestamp,
      objectDetectionDataState:
          objectDetectionDataState ?? this.objectDetectionDataState,
      previousState: previousState ?? this.previousState,
    );
  }

  @override
  List<Object?> get props => [
    mode,
    isLiveCameraActive,
    image,
    detectedObjects,
    timestamp,
    objectDetectionDataState,
    previousState,
  ];

  @override
  String toString() =>
      'ObjectDetectionState('
      'mode: $mode, '
      'isLiveCameraActive: $isLiveCameraActive, '
      'image: $image, '
      'detectedObjects: ${detectedObjects?.length}, '
      'timestamp: $timestamp)';
}
