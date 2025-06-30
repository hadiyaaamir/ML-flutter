part of 'view.dart';

class BarcodeScanningPage extends StatelessWidget {
  const BarcodeScanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MLMediaProvider(
      child: Builder(
        builder: (context) {
          final mlMediaCubit = context.read<MLMediaCubit>();
          return BlocProvider(
            create:
                (context) => BarcodeScanningCubit(mlMediaCubit: mlMediaCubit),
            child: const BarcodeScanningView(),
          );
        },
      ),
    );
  }
}
