part of 'pose_detection_cubit.dart';

/// Pose detection processing modes
enum PoseDetectionMode {
  /// Process static images from gallery or camera
  static,

  /// Process live camera feed
  live,
}

/// State for pose detection functionality
class PoseDetectionState extends Equatable {
  const PoseDetectionState({
    this.mode = PoseDetectionMode.static,
    this.isLiveCameraActive = false,
    this.image,
    this.detectedPoses,
    this.timestamp,
    this.poseDetectionDataState = const DataState.initial(),
    this.previousState,
  });

  /// Current processing mode
  final PoseDetectionMode mode;

  /// Whether live camera is currently active
  final bool isLiveCameraActive;

  /// Current image being processed (for static mode)
  final File? image;

  /// Detected pose results
  final List<PoseDetectionResult>? detectedPoses;

  /// Timestamp of last detection
  final DateTime? timestamp;

  /// Data state for UI feedback
  final DataState<List<PoseDetectionResult>> poseDetectionDataState;

  /// Previous state for retry functionality
  final PoseDetectionState? previousState;

  /// Whether we have detected poses
  bool get hasDetectedPoses =>
      detectedPoses != null && detectedPoses!.isNotEmpty;

  /// Count of detected poses
  int get detectedPosesCount => detectedPoses?.length ?? 0;

  /// Get the primary pose (first detected pose)
  PoseDetectionResult? get primaryPose =>
      hasDetectedPoses ? detectedPoses!.first : null;

  /// Get all poses with full body landmarks
  List<PoseDetectionResult> get fullBodyPoses =>
      detectedPoses?.where((pose) => pose.hasFullBody).toList() ?? [];

  /// Copy with method for state updates
  PoseDetectionState copyWith({
    PoseDetectionMode? mode,
    bool? isLiveCameraActive,
    File? Function()? image,
    List<PoseDetectionResult>? Function()? detectedPoses,
    DateTime? Function()? timestamp,
    DataState<List<PoseDetectionResult>>? poseDetectionDataState,
    PoseDetectionState? previousState,
  }) {
    return PoseDetectionState(
      mode: mode ?? this.mode,
      isLiveCameraActive: isLiveCameraActive ?? this.isLiveCameraActive,
      image: image != null ? image() : this.image,
      detectedPoses:
          detectedPoses != null ? detectedPoses() : this.detectedPoses,
      timestamp: timestamp != null ? timestamp() : this.timestamp,
      poseDetectionDataState:
          poseDetectionDataState ?? this.poseDetectionDataState,
      previousState: previousState ?? this.previousState,
    );
  }

  @override
  List<Object?> get props => [
    mode,
    isLiveCameraActive,
    image,
    detectedPoses,
    timestamp,
    poseDetectionDataState,
    previousState,
  ];
}
