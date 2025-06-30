import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/cubit.dart';

/// Reusable widget for toggling between static and live camera modes
class MLModeToggle extends StatelessWidget {
  const MLModeToggle({super.key, this.title = 'Detection Mode'});

  /// Title text for the mode toggle section
  final String title;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MLMediaCubit, MLMediaState>(
      builder: (context, state) {
        final cubit = context.read<MLMediaCubit>();
        final isLoading = state.mlMediaDataState.isLoading;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MLModeButton(
                        icon: Icons.photo_camera,
                        label: 'Static Image',
                        isSelected: state.mode == MLMediaMode.static,
                        onPressed:
                            isLoading
                                ? null
                                : () => cubit.switchMode(MLMediaMode.static),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MLModeButton(
                        icon: Icons.videocam,
                        label: 'Live Camera',
                        isSelected: state.mode == MLMediaMode.live,
                        onPressed:
                            isLoading
                                ? null
                                : () => cubit.switchMode(MLMediaMode.live),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MLModeButton extends StatelessWidget {
  const _MLModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor:
            isSelected ? Theme.of(context).colorScheme.primary : null,
        foregroundColor:
            isSelected ? Theme.of(context).colorScheme.onPrimary : null,
      ),
    );
  }
}
