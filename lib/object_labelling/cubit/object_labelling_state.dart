part of 'object_labelling_cubit.dart';

typedef ObjectLabellingDataState = DataState<List<LabelResult>>;

enum ObjectLabellingMode {
  static, // Single image processing
  live, // Live camera streaming
}

class ObjectLabellingState extends Equatable {
  const ObjectLabellingState({
    this.image,
    this.labels,
    this.timestamp,
    this.objectLabellingDataState = const DataState.initial(),
    this.previousState,
    this.mode = ObjectLabellingMode.static,
    this.isLiveCameraActive = false,
    this.liveCameraLabels = const [],
  });

  final File? image;
  final List<LabelResult>? labels;
  final DateTime? timestamp;
  final ObjectLabellingDataState objectLabellingDataState;
  final ObjectLabellingState? previousState;
  final ObjectLabellingMode mode;
  final bool isLiveCameraActive;
  final List<LabelResult> liveCameraLabels;

  ObjectLabellingState copyWith({
    File? image,
    List<LabelResult>? Function()? labels,
    DateTime? Function()? timestamp,
    ObjectLabellingDataState? objectLabellingDataState,
    ObjectLabellingState? previousState,
    ObjectLabellingMode? mode,
    bool? isLiveCameraActive,
    List<LabelResult>? liveCameraLabels,
  }) {
    return ObjectLabellingState(
      image: image ?? this.image,
      labels: labels != null ? labels() : this.labels,
      timestamp: timestamp != null ? timestamp() : this.timestamp,
      objectLabellingDataState:
          objectLabellingDataState ?? this.objectLabellingDataState,
      previousState: previousState ?? this.previousState,
      mode: mode ?? this.mode,
      isLiveCameraActive: isLiveCameraActive ?? this.isLiveCameraActive,
      liveCameraLabels: liveCameraLabels ?? this.liveCameraLabels,
    );
  }

  @override
  List<Object?> get props => [
    image,
    labels,
    timestamp,
    objectLabellingDataState,
    previousState,
    mode,
    isLiveCameraActive,
    liveCameraLabels,
  ];
}

extension StateValues on ObjectLabellingState {
  /// Returns only confident labels (above threshold)
  List<LabelResult> getConfidentLabels([double threshold = 0.5]) {
    final labelsToCheck =
        mode == ObjectLabellingMode.live ? liveCameraLabels : (labels ?? []);
    return labelsToCheck
        .where((label) => label.isConfident(threshold))
        .toList();
  }

  /// Returns the top N labels by confidence
  List<LabelResult> getTopLabels(int count) {
    final labelsToCheck =
        mode == ObjectLabellingMode.live ? liveCameraLabels : (labels ?? []);
    final sortedLabels = List<LabelResult>.from(labelsToCheck)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return sortedLabels.take(count).toList();
  }

  /// Get current labels based on mode
  List<LabelResult> get currentLabels {
    return mode == ObjectLabellingMode.live ? liveCameraLabels : (labels ?? []);
  }
}
