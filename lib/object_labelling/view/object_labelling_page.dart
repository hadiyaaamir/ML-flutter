part of 'view.dart';

/// Screen for object labelling functionality
class ObjectLabellingPage extends StatelessWidget {
  const ObjectLabellingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MLMediaProvider(
      child: BlocProvider(
        create:
            (context) => ObjectLabellingCubit(
              mlMediaCubit: context.read<MLMediaCubit>(),
            ),
        child: const ObjectLabellingView(),
      ),
    );
  }
}
