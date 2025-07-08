import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/smart_reply_cubit.dart';
import 'smart_reply_view.dart';

class SmartReplyPage extends StatelessWidget {
  const SmartReplyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SmartReplyCubit(),
      child: const SmartReplyView(),
    );
  }
}
