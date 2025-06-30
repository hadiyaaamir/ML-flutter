import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ml_flutter/services/services.dart';
import 'ml_media_cubit.dart';

/// Provider widget that provides MLMediaCubit to its child
/// This allows any ML feature to access media operations
class MLMediaProvider extends StatelessWidget {
  const MLMediaProvider({super.key, required this.child});

  /// The child widget that will have access to MLMediaCubit
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MLMediaCubit>(
      create: (context) => MLMediaCubit(mlMediaService: MLMediaService()),
      child: child,
    );
  }
}

/// Extension to easily access MLMediaCubit from context
extension MLMediaCubitContext on BuildContext {
  /// Get the MLMediaCubit from context
  MLMediaCubit get mlMediaCubit => read<MLMediaCubit>();

  /// Watch the MLMediaCubit state
  MLMediaCubit get watchMLMediaCubit => watch<MLMediaCubit>();
}
