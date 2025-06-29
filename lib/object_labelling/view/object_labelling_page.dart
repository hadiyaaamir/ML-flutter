part of 'view.dart';

/// Screen for object labelling functionality
class ObjectLabellingPage extends StatelessWidget {
  const ObjectLabellingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => ObjectLabellingCubit(mlMediaService: MLMediaService()),
      child: const ObjectLabellingView(),
    );
  }
}
