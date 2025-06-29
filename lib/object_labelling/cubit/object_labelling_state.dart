part of 'object_labelling_cubit.dart';

typedef ObjectLabellingDataState = DataState<List<LabelResult>>;

class ObjectLabellingState extends Equatable {
  const ObjectLabellingState({
    this.image,
    this.labels,
    this.timestamp,
    this.objectLabellingDataState = const DataState.initial(),
    this.previousState,
  });

  final File? image;
  final List<LabelResult>? labels;
  final DateTime? timestamp;
  final ObjectLabellingDataState objectLabellingDataState;
  final ObjectLabellingState? previousState;

  ObjectLabellingState copyWith({
    File? image,
    List<LabelResult>? labels,
    DateTime? timestamp,
    ObjectLabellingDataState? objectLabellingDataState,
    ObjectLabellingState? previousState,
  }) {
    return ObjectLabellingState(
      image: image ?? this.image,
      labels: labels ?? this.labels,
      timestamp: timestamp ?? this.timestamp,
      objectLabellingDataState:
          objectLabellingDataState ?? this.objectLabellingDataState,
      previousState: previousState ?? this.previousState,
    );
  }

  @override
  List<Object?> get props => [
    image,
    labels,
    timestamp,
    objectLabellingDataState,
    previousState,
  ];
}

extension StateValues on ObjectLabellingState {
  /// Returns only confident labels (above threshold)
  List<LabelResult> getConfidentLabels([double threshold = 0.5]) {
    return labels?.where((label) => label.isConfident(threshold)).toList() ??
        [];
  }

  /// Returns the top N labels by confidence
  List<LabelResult> getTopLabels(int count) {
    final sortedLabels = List<LabelResult>.from(labels ?? [])
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return sortedLabels.take(count).toList();
  }
}
