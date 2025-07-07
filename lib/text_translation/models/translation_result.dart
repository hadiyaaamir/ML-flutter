import 'package:equatable/equatable.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Represents the result of a text translation operation
class TranslationResult extends Equatable {
  const TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.timestamp,
  });

  /// The original text that was translated
  final String originalText;

  /// The translated text
  final String translatedText;

  /// The source language code (e.g., 'en', 'es', 'fr')
  final TranslateLanguage sourceLanguage;

  /// The target language code (e.g., 'en', 'es', 'fr')
  final TranslateLanguage targetLanguage;

  /// When the translation was performed
  final DateTime timestamp;

  /// Get the display name for source language
  String get sourceLanguageDisplayName =>
      _getLanguageDisplayName(sourceLanguage);

  /// Get the display name for target language
  String get targetLanguageDisplayName =>
      _getLanguageDisplayName(targetLanguage);

  /// Get a formatted timestamp string
  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Check if the translation is empty
  bool get isEmpty =>
      originalText.trim().isEmpty || translatedText.trim().isEmpty;

  /// Check if the translation is not empty
  bool get isNotEmpty => !isEmpty;

  /// Get word count of original text
  int get originalWordCount => originalText.trim().split(RegExp(r'\s+')).length;

  /// Get word count of translated text
  int get translatedWordCount =>
      translatedText.trim().split(RegExp(r'\s+')).length;

  /// Create a copy with updated values
  TranslationResult copyWith({
    String? originalText,
    String? translatedText,
    TranslateLanguage? sourceLanguage,
    TranslateLanguage? targetLanguage,
    DateTime? timestamp,
  }) {
    return TranslationResult(
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
    originalText,
    translatedText,
    sourceLanguage,
    targetLanguage,
    timestamp,
  ];

  @override
  String toString() {
    return 'TranslationResult('
        'originalText: $originalText, '
        'translatedText: $translatedText, '
        'sourceLanguage: $sourceLanguage, '
        'targetLanguage: $targetLanguage, '
        'timestamp: $timestamp'
        ')';
  }

  /// Helper method to get display name for language
  static String _getLanguageDisplayName(TranslateLanguage language) {
    switch (language) {
      case TranslateLanguage.afrikaans:
        return 'Afrikaans';
      case TranslateLanguage.arabic:
        return 'Arabic';
      case TranslateLanguage.belarusian:
        return 'Belarusian';
      case TranslateLanguage.bulgarian:
        return 'Bulgarian';
      case TranslateLanguage.bengali:
        return 'Bengali';
      case TranslateLanguage.catalan:
        return 'Catalan';
      case TranslateLanguage.czech:
        return 'Czech';
      case TranslateLanguage.welsh:
        return 'Welsh';
      case TranslateLanguage.danish:
        return 'Danish';
      case TranslateLanguage.german:
        return 'German';
      case TranslateLanguage.greek:
        return 'Greek';
      case TranslateLanguage.english:
        return 'English';
      case TranslateLanguage.esperanto:
        return 'Esperanto';
      case TranslateLanguage.spanish:
        return 'Spanish';
      case TranslateLanguage.estonian:
        return 'Estonian';
      case TranslateLanguage.persian:
        return 'Persian';
      case TranslateLanguage.finnish:
        return 'Finnish';
      case TranslateLanguage.french:
        return 'French';
      case TranslateLanguage.irish:
        return 'Irish';
      case TranslateLanguage.galician:
        return 'Galician';
      case TranslateLanguage.gujarati:
        return 'Gujarati';
      case TranslateLanguage.hebrew:
        return 'Hebrew';
      case TranslateLanguage.hindi:
        return 'Hindi';
      case TranslateLanguage.croatian:
        return 'Croatian';
      case TranslateLanguage.haitian:
        return 'Haitian';
      case TranslateLanguage.hungarian:
        return 'Hungarian';
      case TranslateLanguage.indonesian:
        return 'Indonesian';
      case TranslateLanguage.icelandic:
        return 'Icelandic';
      case TranslateLanguage.italian:
        return 'Italian';
      case TranslateLanguage.japanese:
        return 'Japanese';
      case TranslateLanguage.georgian:
        return 'Georgian';
      case TranslateLanguage.kannada:
        return 'Kannada';
      case TranslateLanguage.korean:
        return 'Korean';
      case TranslateLanguage.lithuanian:
        return 'Lithuanian';
      case TranslateLanguage.latvian:
        return 'Latvian';
      case TranslateLanguage.macedonian:
        return 'Macedonian';
      case TranslateLanguage.marathi:
        return 'Marathi';
      case TranslateLanguage.malay:
        return 'Malay';
      case TranslateLanguage.maltese:
        return 'Maltese';
      case TranslateLanguage.dutch:
        return 'Dutch';
      case TranslateLanguage.norwegian:
        return 'Norwegian';
      case TranslateLanguage.polish:
        return 'Polish';
      case TranslateLanguage.portuguese:
        return 'Portuguese';
      case TranslateLanguage.romanian:
        return 'Romanian';
      case TranslateLanguage.russian:
        return 'Russian';
      case TranslateLanguage.slovak:
        return 'Slovak';
      case TranslateLanguage.slovenian:
        return 'Slovenian';
      case TranslateLanguage.albanian:
        return 'Albanian';
      case TranslateLanguage.swedish:
        return 'Swedish';
      case TranslateLanguage.swahili:
        return 'Swahili';
      case TranslateLanguage.tamil:
        return 'Tamil';
      case TranslateLanguage.telugu:
        return 'Telugu';
      case TranslateLanguage.thai:
        return 'Thai';
      case TranslateLanguage.tagalog:
        return 'Tagalog';
      case TranslateLanguage.turkish:
        return 'Turkish';
      case TranslateLanguage.ukrainian:
        return 'Ukrainian';
      case TranslateLanguage.urdu:
        return 'Urdu';
      case TranslateLanguage.vietnamese:
        return 'Vietnamese';
      case TranslateLanguage.chinese:
        return 'Chinese';
    }
  }
}

/// Extension to provide commonly used language pairs
extension TranslateLanguageExtension on TranslateLanguage {
  /// Get the display name for this language
  String get displayName => TranslationResult._getLanguageDisplayName(this);

  /// Get the flag emoji for this language (simplified mapping)
  String get flagEmoji {
    switch (this) {
      case TranslateLanguage.english:
        return '🇺🇸';
      case TranslateLanguage.spanish:
        return '🇪🇸';
      case TranslateLanguage.french:
        return '🇫🇷';
      case TranslateLanguage.german:
        return '🇩🇪';
      case TranslateLanguage.italian:
        return '🇮🇹';
      case TranslateLanguage.portuguese:
        return '🇵🇹';
      case TranslateLanguage.russian:
        return '🇷🇺';
      case TranslateLanguage.chinese:
        return '🇨🇳';
      case TranslateLanguage.japanese:
        return '🇯🇵';
      case TranslateLanguage.korean:
        return '🇰🇷';
      case TranslateLanguage.arabic:
        return '🇸🇦';
      case TranslateLanguage.hindi:
        return '🇮🇳';
      case TranslateLanguage.dutch:
        return '🇳🇱';
      case TranslateLanguage.swedish:
        return '🇸🇪';
      case TranslateLanguage.norwegian:
        return '🇳🇴';
      case TranslateLanguage.danish:
        return '🇩🇰';
      case TranslateLanguage.polish:
        return '🇵🇱';
      case TranslateLanguage.turkish:
        return '🇹🇷';
      case TranslateLanguage.thai:
        return '🇹🇭';
      case TranslateLanguage.vietnamese:
        return '🇻🇳';
      case TranslateLanguage.urdu:
        return '🇵🇰';
      default:
        return '🌐';
    }
  }
}

/// Helper class for common language pairs and operations
class TranslationLanguages {
  /// Most commonly used languages
  static const List<TranslateLanguage> popularLanguages = [
    TranslateLanguage.english,
    TranslateLanguage.spanish,
    TranslateLanguage.french,
    TranslateLanguage.german,
    TranslateLanguage.italian,
    TranslateLanguage.portuguese,
    TranslateLanguage.russian,
    TranslateLanguage.chinese,
    TranslateLanguage.japanese,
    TranslateLanguage.korean,
    TranslateLanguage.arabic,
    TranslateLanguage.hindi,
    TranslateLanguage.urdu,
  ];

  /// All available languages
  static const List<TranslateLanguage> allLanguages = TranslateLanguage.values;

  /// Get language by code
  static TranslateLanguage? getLanguageByCode(String code) {
    try {
      return TranslateLanguage.values.firstWhere(
        (lang) => lang.name.toLowerCase() == code.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if a language is popular
  static bool isPopularLanguage(TranslateLanguage language) {
    return popularLanguages.contains(language);
  }
}

/// Represents a language option in the dropdown (either a specific language or detect option)
class LanguageOption extends Equatable {
  /// Create a specific language option
  const LanguageOption.language(TranslateLanguage this.language)
    : isDetectOption = false,
      displayName = null,
      flagEmoji = null;

  /// Create the detect language option
  const LanguageOption.detectLanguage()
    : isDetectOption = true,
      language = null,
      displayName = 'Detect Language',
      flagEmoji = '🔍';

  /// Whether this is the detect language option
  final bool isDetectOption;

  /// The specific language (null for detect option)
  final TranslateLanguage? language;

  /// Display name override (used for detect option)
  final String? displayName;

  /// Flag emoji override (used for detect option)
  final String? flagEmoji;

  /// Get the display name for this option
  String get actualDisplayName {
    if (isDetectOption) return displayName!;
    return language!.displayName;
  }

  /// Get the flag emoji for this option
  String get actualFlagEmoji {
    if (isDetectOption) return flagEmoji!;
    return language!.flagEmoji;
  }

  @override
  List<Object?> get props => [isDetectOption, language, displayName, flagEmoji];
}
