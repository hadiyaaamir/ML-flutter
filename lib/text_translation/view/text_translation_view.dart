import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:ml_flutter/text_translation/cubit/text_translation_cubit.dart';
import 'package:ml_flutter/text_translation/models/translation_result.dart';

/// Main view for text translation functionality
class TextTranslationView extends StatelessWidget {
  const TextTranslationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Translation'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showModelManagementDialog(context),
            icon: const Icon(Icons.download),
            tooltip: 'Manage Models',
          ),
        ],
      ),
      body: BlocBuilder<TextTranslationCubit, TextTranslationState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TranslationStatusCard(),
                _LanguageSelectionCard(),
                _TextInputCard(),
                _TranslationResultCard(),
                _TranslationHistoryCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Show model management dialog
  void _showModelManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<TextTranslationCubit>(),
            child: _ModelManagementDialog(),
          ),
    );
  }
}

/// Status card showing translation state
class _TranslationStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextTranslationCubit, TextTranslationState>(
      builder: (context, state) {
        String statusText;
        Color statusColor;
        IconData statusIcon;
        bool showLoading = false;

        if (state.isTranslating) {
          statusText = 'Translating...';
          statusColor = Colors.orange;
          statusIcon = Icons.translate;
          showLoading = true;
        } else if (state.hasTranslationError) {
          statusText = state.translationErrorMessage ?? 'Translation failed';
          statusColor = Colors.red;
          statusIcon = Icons.error;
        } else if (state.hasCurrentTranslation) {
          statusText = 'Translation completed';
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
        } else if (state.statusMessage.isNotEmpty) {
          statusText = state.statusMessage;
          statusColor = Colors.blue;
          statusIcon = Icons.info;
        } else {
          statusText = 'Ready to translate';
          statusColor = Colors.blue;
          statusIcon = Icons.translate;
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (showLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Language selection card
class _LanguageSelectionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextTranslationCubit, TextTranslationState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Translation Languages',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SourceLanguageSelector(
                        selectedLanguage: state.sourceLanguage,
                        shouldDetectLanguage: state.shouldDetectLanguage,
                        onLanguageSelected: (option) {
                          if (option.isDetectOption) {
                            context
                                .read<TextTranslationCubit>()
                                .setSourceLanguageToDetect();
                          } else {
                            context
                                .read<TextTranslationCubit>()
                                .setSourceLanguageToSpecific(option.language!);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      onPressed: () {
                        context.read<TextTranslationCubit>().swapLanguages();
                      },
                      icon: const Icon(Icons.swap_horiz),
                      tooltip: 'Swap Languages',
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: _LanguageSelector(
                        title: 'To',
                        selectedLanguage: state.targetLanguage,
                        onLanguageSelected: (language) {
                          context
                              .read<TextTranslationCubit>()
                              .setTargetLanguage(language);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Language selector dropdown
class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.title,
    required this.selectedLanguage,
    required this.onLanguageSelected,
  });

  final String title;
  final TranslateLanguage selectedLanguage;
  final ValueChanged<TranslateLanguage> onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<TranslateLanguage>(
            value: selectedLanguage,
            isExpanded: true,
            underline: const SizedBox(),
            onChanged: (language) {
              if (language != null) {
                onLanguageSelected(language);
              }
            },
            items:
                TranslationLanguages.popularLanguages.map((language) {
                  return DropdownMenuItem(
                    value: language,
                    child: Row(
                      children: [
                        Text(language.flagEmoji),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            language.displayName,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Source language selector dropdown (includes detect option)
class _SourceLanguageSelector extends StatelessWidget {
  const _SourceLanguageSelector({
    required this.selectedLanguage,
    required this.shouldDetectLanguage,
    required this.onLanguageSelected,
  });

  final TranslateLanguage selectedLanguage;
  final bool shouldDetectLanguage;
  final ValueChanged<LanguageOption> onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    // Create list of language options
    final List<LanguageOption> languageOptions = [
      const LanguageOption.detectLanguage(),
      ...TranslationLanguages.popularLanguages.map(
        (lang) => LanguageOption.language(lang),
      ),
    ];

    // Determine current selection
    final LanguageOption currentSelection =
        shouldDetectLanguage
            ? const LanguageOption.detectLanguage()
            : LanguageOption.language(selectedLanguage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'From',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<LanguageOption>(
            value: currentSelection,
            isExpanded: true,
            underline: const SizedBox(),
            onChanged: (option) {
              if (option != null) {
                onLanguageSelected(option);
              }
            },
            items:
                languageOptions.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Row(
                      children: [
                        Text(option.actualFlagEmoji),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            option.actualDisplayName,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Text input card
class _TextInputCard extends StatefulWidget {
  @override
  State<_TextInputCard> createState() => _TextInputCardState();
}

class _TextInputCardState extends State<_TextInputCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      context.read<TextTranslationCubit>().setInputText(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextTranslationCubit, TextTranslationState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Enter Text to Translate',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (state.hasInputText)
                      Text(
                        '${state.inputCharCount} chars, ${state.inputWordCount} words',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Type or paste text here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed:
                          state.isReadyToTranslate && !state.isTranslating
                              ? () {
                                context
                                    .read<TextTranslationCubit>()
                                    .translateText();
                              }
                              : null,
                      icon: const Icon(Icons.translate),
                      label: const Text('Translate'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed:
                          state.hasInputText
                              ? () {
                                _controller.clear();
                                context
                                    .read<TextTranslationCubit>()
                                    .clearInputText();
                              }
                              : null,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Translation result card
class _TranslationResultCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextTranslationCubit, TextTranslationState>(
      builder: (context, state) {
        if (!state.hasCurrentTranslation) {
          return const SizedBox.shrink();
        }

        final translation = state.currentTranslation!;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.translate, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'Translation Result',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: translation.translatedText),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Translation copied!')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy Translation',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _TranslationDisplay(translation: translation),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Translation display widget
class _TranslationDisplay extends StatelessWidget {
  const _TranslationDisplay({required this.translation});

  final TranslationResult translation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Source text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(translation.sourceLanguage.flagEmoji),
                  const SizedBox(width: 8),
                  Text(
                    translation.sourceLanguageDisplayName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                translation.originalText,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Arrow
        const Center(child: Icon(Icons.arrow_downward, color: Colors.grey)),
        const SizedBox(height: 12),
        // Translated text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(translation.targetLanguage.flagEmoji),
                  const SizedBox(width: 8),
                  Text(
                    translation.targetLanguageDisplayName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                translation.translatedText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Translation info
        Row(
          children: [
            Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              translation.formattedTimestamp,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(width: 16),
            Icon(Icons.text_fields, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              '${translation.originalWordCount} → ${translation.translatedWordCount} words',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

/// Translation history card
class _TranslationHistoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextTranslationCubit, TextTranslationState>(
      builder: (context, state) {
        if (!state.hasHistory) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Translation History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        context.read<TextTranslationCubit>().clearHistory();
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.translationHistory.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final translation = state.translationHistory[index];
                    return _TranslationHistoryItem(
                      translation: translation,
                      onDelete: () {
                        context.read<TextTranslationCubit>().removeFromHistory(
                          translation,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Translation history item
class _TranslationHistoryItem extends StatelessWidget {
  const _TranslationHistoryItem({
    required this.translation,
    required this.onDelete,
  });

  final TranslationResult translation;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(translation.sourceLanguage.flagEmoji),
              const SizedBox(width: 4),
              Text(
                translation.sourceLanguageDisplayName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.arrow_right_alt, size: 16),
              Text(translation.targetLanguage.flagEmoji),
              const SizedBox(width: 4),
              Text(
                translation.targetLanguageDisplayName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                translation.formattedTimestamp,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                iconSize: 16,
                tooltip: 'Delete',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            translation.originalText,
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            translation.translatedText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.green,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Model management dialog
class _ModelManagementDialog extends StatefulWidget {
  @override
  State<_ModelManagementDialog> createState() => _ModelManagementDialogState();
}

class _ModelManagementDialogState extends State<_ModelManagementDialog> {
  List<TranslateLanguage> availableModels = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableModels();
  }

  Future<void> _loadAvailableModels() async {
    final models =
        await context.read<TextTranslationCubit>().getAvailableModels();
    setState(() {
      availableModels = models;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Translation Models'),
      content: SizedBox(
        width: double.maxFinite,
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Pre-download language models for better performance. Models will also be downloaded automatically when needed.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: TranslationLanguages.popularLanguages.length,
                        itemBuilder: (context, index) {
                          final language =
                              TranslationLanguages.popularLanguages[index];
                          final isDownloaded = availableModels.contains(
                            language,
                          );

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Text(language.flagEmoji),
                            title: Text(language.displayName),
                            trailing:
                                isDownloaded
                                    ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        IconButton(
                                          onPressed:
                                              () => _deleteModel(language),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          tooltip: 'Delete Model',
                                        ),
                                      ],
                                    )
                                    : ElevatedButton(
                                      onPressed: () => _downloadModel(language),
                                      child: const Text('Download'),
                                    ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _downloadModel(TranslateLanguage language) async {
    await context.read<TextTranslationCubit>().downloadModel(language);
    await _loadAvailableModels();
  }

  Future<void> _deleteModel(TranslateLanguage language) async {
    await context.read<TextTranslationCubit>().deleteModel(language);
    await _loadAvailableModels();
  }
}
