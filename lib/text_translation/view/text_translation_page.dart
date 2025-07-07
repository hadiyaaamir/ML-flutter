import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ml_flutter/text_translation/cubit/text_translation_cubit.dart';
import 'package:ml_flutter/text_translation/view/text_translation_view.dart';

/// Page wrapper for text translation functionality
class TextTranslationPage extends StatelessWidget {
  const TextTranslationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TextTranslationCubit(),
      child: const TextTranslationView(),
    );
  }
}
