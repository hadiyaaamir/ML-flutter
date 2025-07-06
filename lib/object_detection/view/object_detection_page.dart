import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ml_flutter/ml_media/ml_media.dart';
import 'package:ml_flutter/object_detection/object_detection.dart';

/// Page that provides the object classification functionality with ML media integration
class ObjectDetectionPage extends StatelessWidget {
  const ObjectDetectionPage({super.key});

  /// Create a route to the object classification page
  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const ObjectDetectionPage());
  }

  @override
  Widget build(BuildContext context) {
    return MLMediaProvider(
      child: Builder(
        builder: (context) {
          return BlocProvider(
            create:
                (context) => ObjectDetectionCubit(
                  mlMediaCubit: context.read<MLMediaCubit>(),
                ),
            child: const ObjectDetectionView(),
          );
        },
      ),
    );
  }
}
