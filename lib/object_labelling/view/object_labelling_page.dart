part of 'view.dart';

/// Screen for object labelling functionality
class ObjectLabellingPage extends StatelessWidget {
  const ObjectLabellingPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (context) => const ObjectLabellingPage());
  }

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
