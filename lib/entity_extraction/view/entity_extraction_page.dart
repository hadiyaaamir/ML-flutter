import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/entity_extraction_cubit.dart';
import 'entity_extraction_view.dart';

class EntityExtractionPage extends StatelessWidget {
  const EntityExtractionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EntityExtractionCubit(),
      child: const EntityExtractionView(),
    );
  }
}
