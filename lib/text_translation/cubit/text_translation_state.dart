part of 'text_translation_cubit.dart';

/// State for text translation functionality
class TextTranslationState extends Equatable {
  const TextTranslationState({
    this.sourceLanguage = TranslateLanguage.english,
    this.targetLanguage = TranslateLanguage.spanish,
    this.inputText = '',
    this.currentTranslation,
    this.translationHistory = const [],
    this.translationDataState = const DataState.initial(),
    this.statusMessage = '',
    this.shouldDetectLanguage = false,
  });

  /// Source language for translation
  final TranslateLanguage sourceLanguage;

  /// Target language for translation
  final TranslateLanguage targetLanguage;

  /// Input text to be translated
  final String inputText;

  /// Current translation result
  final TranslationResult? currentTranslation;

  /// History of translations
  final List<TranslationResult> translationHistory;

  /// Data state for translation operations
  final DataState translationDataState;

  /// Status message for user feedback
  final String statusMessage;

  /// Whether to detect language automatically before translation
  final bool shouldDetectLanguage;

  /// Check if translation is in progress
  bool get isTranslating => translationDataState.isLoading;

  /// Check if translation has failed
  bool get hasTranslationError => translationDataState.isFailure;

  /// Check if there's a current translation
  bool get hasCurrentTranslation => currentTranslation != null;

  /// Check if there's translation history
  bool get hasHistory => translationHistory.isNotEmpty;

  /// Get the error message if translation failed
  String? get translationErrorMessage => translationDataState.errorMessage;

  /// Check if input text is not empty
  bool get hasInputText => inputText.trim().isNotEmpty;

  /// Get word count of input text
  int get inputWordCount => inputText.trim().split(RegExp(r'\s+')).length;

  /// Get character count of input text
  int get inputCharCount => inputText.length;

  /// Check if languages are different (valid for translation)
  bool get languagesAreDifferent => sourceLanguage != targetLanguage;

  /// Check if ready to translate
  bool get isReadyToTranslate {
    return hasInputText &&
        (shouldDetectLanguage || sourceLanguage != targetLanguage) &&
        !isTranslating;
  }

  /// Get language pair description
  String get languagePairDescription =>
      '${sourceLanguage.displayName} → ${targetLanguage.displayName}';

  /// Create a copy with updated values
  TextTranslationState copyWith({
    TranslateLanguage? sourceLanguage,
    TranslateLanguage? targetLanguage,
    String? inputText,
    TranslationResult? currentTranslation,
    List<TranslationResult>? translationHistory,
    DataState? translationDataState,
    String? statusMessage,
    bool? shouldDetectLanguage,
  }) {
    return TextTranslationState(
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      inputText: inputText ?? this.inputText,
      currentTranslation: currentTranslation ?? this.currentTranslation,
      translationHistory: translationHistory ?? this.translationHistory,
      translationDataState: translationDataState ?? this.translationDataState,
      statusMessage: statusMessage ?? this.statusMessage,
      shouldDetectLanguage: shouldDetectLanguage ?? this.shouldDetectLanguage,
    );
  }

  @override
  List<Object?> get props => [
    sourceLanguage,
    targetLanguage,
    inputText,
    currentTranslation,
    translationHistory,
    translationDataState,
    statusMessage,
    shouldDetectLanguage,
  ];

  @override
  String toString() {
    return 'TextTranslationState('
        'sourceLanguage: $sourceLanguage, '
        'targetLanguage: $targetLanguage, '
        'inputText: $inputText, '
        'currentTranslation: $currentTranslation, '
        'translationHistory: ${translationHistory.length} items, '
        'translationDataState: $translationDataState, '
        'statusMessage: $statusMessage, '
        'shouldDetectLanguage: $shouldDetectLanguage'
        ')';
  }
}
