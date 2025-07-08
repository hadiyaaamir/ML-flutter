part of 'entity_extraction_cubit.dart';

class EntityExtractionState extends Equatable {
  const EntityExtractionState({
    this.inputText = '',
    this.entityExtractionDataState = const DataState.initial(),
  });

  final String inputText;
  final DataState<List<ExtractedEntity>> entityExtractionDataState;

  /// Get entities from data state
  List<ExtractedEntity> get entities => entityExtractionDataState.data ?? [];

  /// Check if loading
  bool get isLoading => entityExtractionDataState.isLoading;

  /// Get error message
  String? get error => entityExtractionDataState.errorMessage;

  EntityExtractionState copyWith({
    String? inputText,
    DataState<List<ExtractedEntity>>? entityExtractionDataState,
  }) {
    return EntityExtractionState(
      inputText: inputText ?? this.inputText,
      entityExtractionDataState:
          entityExtractionDataState ?? this.entityExtractionDataState,
    );
  }

  @override
  List<Object?> get props => [inputText, entityExtractionDataState];
}
