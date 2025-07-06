import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ml_flutter/ml_media/ml_media.dart';
import 'package:ml_flutter/text_recognition/text_recognition.dart';
import 'package:ml_flutter/services/ml_media_service.dart';

/// Page wrapper for text recognition functionality
class TextRecognitionPage extends StatelessWidget {
  const TextRecognitionPage({super.key});

  /// Create route for navigation
  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const TextRecognitionPage());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => MLMediaCubit(mlMediaService: MLMediaService()),
        ),
        BlocProvider(
          create:
              (context) => TextRecognitionCubit(
                mlMediaCubit: context.read<MLMediaCubit>(),
              ),
        ),
      ],
      child: const TextRecognitionView(),
    );
  }
}
