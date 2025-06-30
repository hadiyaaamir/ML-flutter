import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/cubit.dart';

/// Reusable image display widget for ML media operations
class MLImageDisplay extends StatelessWidget {
  const MLImageDisplay({
    super.key,
    this.title = 'Captured Image',
    this.maxHeight = 300.0,
  });

  /// Title for the image display section
  final String title;

  /// Maximum height for the image display
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MLMediaCubit, MLMediaState>(
      builder: (context, state) {
        // Only show image in static mode
        if (state.mode == MLMediaMode.live || state.image == null) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxHeight: maxHeight),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(state.image!, fit: BoxFit.contain),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
