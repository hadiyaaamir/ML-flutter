import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:equatable/equatable.dart';
import 'package:ml_flutter/text_translation/models/translation_result.dart';
import 'package:ml_flutter/common/data_state.dart';

part 'text_translation_state.dart';

/// Cubit for managing text translation functionality
class TextTranslationCubit extends Cubit<TextTranslationState> {
  TextTranslationCubit() : super(const TextTranslationState());

  /// Map to store translators for different language pairs
  final Map<String, OnDeviceTranslator> _translators = {};

  /// Map to store model download status
  final Map<String, bool> _modelDownloadStatus = {};

  /// Model manager for downloading translation models
  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  /// Language identifier for detecting input language
  final LanguageIdentifier _languageIdentifier = LanguageIdentifier(
    confidenceThreshold: 0.5,
  );

  @override
  Future<void> close() async {
    // Clean up all translators
    for (final translator in _translators.values) {
      await translator.close();
    }
    _translators.clear();

    // Clean up language identifier
    await _languageIdentifier.close();

    return super.close();
  }

  /// Set source language
  void setSourceLanguage(TranslateLanguage language) {
    emit(state.copyWith(sourceLanguage: language));
  }

  /// Set source language to detect mode
  void setSourceLanguageToDetect() {
    emit(state.copyWith(shouldDetectLanguage: true));
  }

  /// Set source language to specific language (disable detect mode)
  void setSourceLanguageToSpecific(TranslateLanguage language) {
    emit(state.copyWith(sourceLanguage: language, shouldDetectLanguage: false));
  }

  /// Set target language
  void setTargetLanguage(TranslateLanguage language) {
    emit(state.copyWith(targetLanguage: language));
  }

  /// Swap source and target languages
  void swapLanguages() {
    // If detect language is enabled, disable it and use current source language
    if (state.shouldDetectLanguage) {
      emit(
        state.copyWith(
          sourceLanguage: state.targetLanguage,
          targetLanguage: state.sourceLanguage,
          shouldDetectLanguage: false,
        ),
      );
    } else {
      emit(
        state.copyWith(
          sourceLanguage: state.targetLanguage,
          targetLanguage: state.sourceLanguage,
        ),
      );
    }
  }

  /// Set input text
  void setInputText(String text) {
    emit(state.copyWith(inputText: text));
  }

  /// Clear input text
  void clearInputText() {
    emit(state.copyWith(inputText: ''));
  }

  /// Check if model is downloaded for a language pair
  Future<bool> isModelDownloaded(TranslateLanguage language) async {
    try {
      return await _modelManager.isModelDownloaded(language.bcpCode);
    } catch (e) {
      return false;
    }
  }

  /// Download model for a language
  Future<void> downloadModel(TranslateLanguage language) async {
    try {
      emit(
        state.copyWith(
          translationDataState: const DataState.loading(),
          statusMessage: 'Downloading model...',
        ),
      );

      await _modelManager.downloadModel(language.bcpCode);

      emit(
        state.copyWith(
          translationDataState: const DataState.loaded(),
          statusMessage: 'Model downloaded successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          translationDataState: DataState.failure(error: e.toString()),
          statusMessage: 'Failed to download model: ${e.toString()}',
        ),
      );
    }
  }

  /// Delete model for a language
  Future<void> deleteModel(TranslateLanguage language) async {
    try {
      await _modelManager.deleteModel(language.bcpCode);

      emit(state.copyWith(statusMessage: 'Model deleted successfully'));
    } catch (e) {
      emit(
        state.copyWith(
          statusMessage: 'Failed to delete model: ${e.toString()}',
        ),
      );
    }
  }

  /// Get available models
  Future<List<TranslateLanguage>> getAvailableModels() async {
    try {
      // Since the API doesn't provide a direct method to get available models,
      // we'll check popular languages individually
      final availableModels = <TranslateLanguage>[];

      for (final language in TranslationLanguages.popularLanguages) {
        final isDownloaded = await _modelManager.isModelDownloaded(
          language.bcpCode,
        );
        if (isDownloaded) {
          availableModels.add(language);
        }
      }

      return availableModels;
    } catch (e) {
      return [];
    }
  }

  /// Translate text
  Future<void> translateText() async {
    final inputText = state.inputText.trim();
    if (inputText.isEmpty) {
      emit(state.copyWith(statusMessage: 'Please enter text to translate'));
      return;
    }

    emit(
      state.copyWith(
        translationDataState: const DataState.loading(),
        statusMessage: 'Preparing translation...',
      ),
    );

    try {
      TranslateLanguage actualSourceLanguage = state.sourceLanguage;

      // If detect language is enabled, detect the language first
      if (state.shouldDetectLanguage) {
        emit(state.copyWith(statusMessage: 'Detecting language...'));

        final identifiedLanguages = await _languageIdentifier
            .identifyPossibleLanguages(inputText);

        if (identifiedLanguages.isEmpty) {
          emit(
            state.copyWith(
              translationDataState: DataState.failure(
                error: 'Could not detect language',
              ),
              statusMessage: 'Language detection failed',
            ),
          );
          return;
        }

        // Get the most likely language
        final detectedLanguageCode = identifiedLanguages.first.languageTag;

        // Convert BCP-47 language code to TranslateLanguage
        final detectedLanguage = _convertBcpCodeToTranslateLanguage(
          detectedLanguageCode,
        );

        if (detectedLanguage == null) {
          emit(
            state.copyWith(
              translationDataState: DataState.failure(
                error:
                    'Detected language ($detectedLanguageCode) is not supported for translation',
              ),
              statusMessage: 'Detected language not supported',
            ),
          );
          return;
        }

        actualSourceLanguage = detectedLanguage;
        emit(
          state.copyWith(
            statusMessage:
                'Detected: ${detectedLanguage.displayName}. Translating...',
          ),
        );
      }

      // Check if source and target languages are the same
      if (actualSourceLanguage == state.targetLanguage) {
        emit(
          state.copyWith(
            translationDataState: DataState.failure(
              error: 'Source and target languages cannot be the same',
            ),
            statusMessage: 'Please select different target language',
          ),
        );
        return;
      }

      // Check if models are downloaded for both source and target languages
      final sourceModelDownloaded = await _checkAndDownloadModel(
        actualSourceLanguage,
        'source',
      );

      final targetModelDownloaded = await _checkAndDownloadModel(
        state.targetLanguage,
        'target',
      );

      if (!sourceModelDownloaded || !targetModelDownloaded) {
        // If we reach here, download failed
        return; // Error already emitted in _checkAndDownloadModel
      }

      // Update status to translating
      emit(state.copyWith(statusMessage: 'Translating...'));

      // Get or create translator
      final translator = await _getTranslator(
        actualSourceLanguage,
        state.targetLanguage,
      );

      // Perform translation with timeout
      final translatedText = await translator
          .translateText(inputText)
          .timeout(const Duration(seconds: 30));

      // Create translation result
      final result = TranslationResult(
        originalText: inputText,
        translatedText: translatedText,
        sourceLanguage: actualSourceLanguage,
        targetLanguage: state.targetLanguage,
        timestamp: DateTime.now(),
      );

      // Add to history
      final updatedHistory = [result, ...state.translationHistory];

      emit(
        state.copyWith(
          translationDataState: const DataState.loaded(),
          currentTranslation: result,
          translationHistory: updatedHistory,
          statusMessage: 'Translation completed successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          translationDataState: DataState.failure(error: e.toString()),
          statusMessage: 'Translation failed: ${e.toString()}',
        ),
      );
    }
  }

  /// Check if model is downloaded, and download if not available
  Future<bool> _checkAndDownloadModel(
    TranslateLanguage language,
    String modelType,
  ) async {
    try {
      // Check if model is already downloaded
      final isDownloaded = await _modelManager.isModelDownloaded(
        language.bcpCode,
      );

      if (isDownloaded) {
        // Update cache
        final key = _getLanguagePairKey(language, language);
        _modelDownloadStatus[key] = true;
        return true;
      }

      // Model not downloaded, download it
      emit(
        state.copyWith(
          statusMessage: 'Downloading ${language.displayName} model...',
        ),
      );

      await _modelManager.downloadModel(language.bcpCode);

      // Update cache
      final key = _getLanguagePairKey(language, language);
      _modelDownloadStatus[key] = true;

      emit(
        state.copyWith(
          statusMessage:
              '${language.displayName} model downloaded successfully',
        ),
      );

      return true;
    } catch (e) {
      emit(
        state.copyWith(
          translationDataState: DataState.failure(
            error:
                'Failed to download ${language.displayName} model: ${e.toString()}',
          ),
          statusMessage: 'Model download failed',
        ),
      );
      return false;
    }
  }

  /// Clear current translation
  void clearTranslation() {
    emit(
      state.copyWith(
        currentTranslation: null,
        translationDataState: const DataState.initial(),
        statusMessage: '',
      ),
    );
  }

  /// Clear translation history
  void clearHistory() {
    emit(state.copyWith(translationHistory: []));
  }

  /// Remove translation from history
  void removeFromHistory(TranslationResult translation) {
    final updatedHistory =
        state.translationHistory.where((t) => t != translation).toList();
    emit(state.copyWith(translationHistory: updatedHistory));
  }

  /// Get or create translator for language pair
  Future<OnDeviceTranslator> _getTranslator(
    TranslateLanguage sourceLanguage,
    TranslateLanguage targetLanguage,
  ) async {
    final key = _getLanguagePairKey(sourceLanguage, targetLanguage);

    if (_translators.containsKey(key)) {
      return _translators[key]!;
    }

    final translator = OnDeviceTranslator(
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );

    _translators[key] = translator;
    return translator;
  }

  /// Generate key for language pair
  String _getLanguagePairKey(
    TranslateLanguage sourceLanguage,
    TranslateLanguage targetLanguage,
  ) {
    return '${sourceLanguage.bcpCode}_${targetLanguage.bcpCode}';
  }

  /// Get model download progress (placeholder for future implementation)
  Stream<double>? getModelDownloadProgress(TranslateLanguage language) {
    // This would require additional implementation to track download progress
    // For now, return null as the ML Kit API doesn't provide progress callbacks
    return null;
  }

  /// Check if translation is possible with current settings
  bool get canTranslate {
    return state.inputText.trim().isNotEmpty &&
        state.sourceLanguage != state.targetLanguage;
  }

  /// Check if translation can be done immediately (models already downloaded)
  Future<bool> get canTranslateImmediately async {
    if (!canTranslate) return false;

    try {
      final sourceDownloaded = await _modelManager.isModelDownloaded(
        state.sourceLanguage.bcpCode,
      );
      final targetDownloaded = await _modelManager.isModelDownloaded(
        state.targetLanguage.bcpCode,
      );

      return sourceDownloaded && targetDownloaded;
    } catch (e) {
      return false;
    }
  }

  /// Get estimated translation time (placeholder)
  Duration get estimatedTranslationTime {
    final wordCount = state.inputText.trim().split(RegExp(r'\s+')).length;
    // Rough estimate: 100 words per second for on-device translation
    return Duration(milliseconds: (wordCount / 100 * 1000).round());
  }

  /// Convert BCP-47 language code to TranslateLanguage enum
  TranslateLanguage? _convertBcpCodeToTranslateLanguage(String bcpCode) {
    for (final language in TranslationLanguages.popularLanguages) {
      if (language.bcpCode == bcpCode) {
        return language;
      }
    }
    return null;
  }
}
