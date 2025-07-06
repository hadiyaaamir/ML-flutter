import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ml_flutter/services/services.dart';
import 'package:ml_flutter/pose_detection/cubit/pose_detection_cubit.dart';
import 'package:ml_flutter/pose_detection/view/pose_detection_view.dart';
import 'package:ml_flutter/ml_media/ml_media.dart';

/// Page wrapper for pose detection functionality
class PoseDetectionPage extends StatelessWidget {
  const PoseDetectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MLMediaCubit>(
          create: (context) => MLMediaCubit(mlMediaService: MLMediaService()),
        ),
        BlocProvider<PoseDetectionCubit>(
          create:
              (context) => PoseDetectionCubit(
                mlMediaCubit: context.read<MLMediaCubit>(),
              ),
        ),
      ],
      child: const PoseDetectionView(),
    );
  }
}
