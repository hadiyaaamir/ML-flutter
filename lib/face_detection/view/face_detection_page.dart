part of 'view.dart';

/// Page widget for face detection functionality
class FaceDetectionPage extends StatelessWidget {
  const FaceDetectionPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (context) => const FaceDetectionPage());
  }

  @override
  Widget build(BuildContext context) {
    return MLMediaProvider(
      child: Builder(
        builder: (context) {
          final mlMediaCubit = context.read<MLMediaCubit>();
          return BlocProvider(
            create: (context) => FaceDetectionCubit(mlMediaCubit: mlMediaCubit),
            child: const FaceDetectionView(),
          );
        },
      ),
    );
  }
}
