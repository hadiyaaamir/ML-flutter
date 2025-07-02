part of 'face_detection_cubit.dart';

typedef FaceDetectionDataState = DataState<List<Face>>;

/// Enum for face detection modes
enum FaceDetectionMode { static, live }

/// State for face detection functionality
class FaceDetectionState extends Equatable {
  const FaceDetectionState({
    this.image,
    this.faces,
    this.timestamp,
    this.faceDetectionDataState = const DataState.initial(),
    this.previousState,
    this.mode = FaceDetectionMode.static,
    this.isLiveCameraActive = false,
    this.liveCameraFaces,
    this.showContours = false,
    this.showLabels = true,
    this.selectedFilter = FaceFilterType.none,
  });

  final File? image;
  final List<Face>? faces;
  final DateTime? timestamp;
  final DataState<List<Face>> faceDetectionDataState;
  final FaceDetectionState? previousState;
  final FaceDetectionMode mode;
  final bool isLiveCameraActive;
  final List<Face>? liveCameraFaces;
  final bool showContours;
  final bool showLabels;
  final FaceFilterType selectedFilter;

  FaceDetectionState copyWith({
    File? Function()? image,
    List<Face>? Function()? faces,
    DateTime? Function()? timestamp,
    DataState<List<Face>>? faceDetectionDataState,
    FaceDetectionState? previousState,
    FaceDetectionMode? mode,
    bool? isLiveCameraActive,
    List<Face>? liveCameraFaces,
    bool? showContours,
    bool? showLabels,
    FaceFilterType? selectedFilter,
  }) {
    return FaceDetectionState(
      image: image != null ? image() : this.image,
      faces: faces != null ? faces() : this.faces,
      timestamp: timestamp != null ? timestamp() : this.timestamp,
      faceDetectionDataState:
          faceDetectionDataState ?? this.faceDetectionDataState,
      previousState: previousState ?? this.previousState,
      mode: mode ?? this.mode,
      isLiveCameraActive: isLiveCameraActive ?? this.isLiveCameraActive,
      liveCameraFaces: liveCameraFaces ?? this.liveCameraFaces,
      showContours: showContours ?? this.showContours,
      showLabels: showLabels ?? this.showLabels,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }

  @override
  List<Object?> get props => [
    image,
    faces,
    timestamp,
    faceDetectionDataState,
    previousState,
    mode,
    isLiveCameraActive,
    liveCameraFaces,
    showContours,
    showLabels,
    selectedFilter,
  ];
}

extension StateValues on FaceDetectionState {
  /// Get current faces based on mode
  List<Face> get currentFaces {
    return mode == FaceDetectionMode.live
        ? liveCameraFaces ?? []
        : (faces ?? []);
  }
}
