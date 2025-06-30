import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/cubit.dart';

/// Reusable action buttons widget for ML media operations
class MLActionButtons extends StatelessWidget {
  const MLActionButtons({
    super.key,
    this.captureButtonText = 'Capture Image',
    this.galleryButtonText = 'Select Image',
    this.retryButtonText = 'Try Another Image',
    this.showRetryButton = true,
    this.hasResults = false,
  });

  /// Text for the capture button
  final String captureButtonText;

  /// Text for the gallery selection button
  final String galleryButtonText;

  /// Text for the retry button
  final String retryButtonText;

  /// Whether to show the retry button when results are available
  final bool showRetryButton;

  /// Whether there are processing results available
  final bool hasResults;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MLMediaCubit, MLMediaState>(
      builder: (context, state) {
        final cubit = context.read<MLMediaCubit>();
        final isLoading = state.mlMediaDataState.isLoading;

        return Column(
          children: [
            // Capture/Select Image Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : () => cubit.captureImage(),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(captureButtonText),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        isLoading ? null : () => cubit.pickImageFromGallery(),
                    icon: const Icon(Icons.photo_library),
                    label: Text(galleryButtonText),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            // Retry Button (only show if we have results and it's enabled)
            if (hasResults && showRetryButton) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : () => cubit.clearResults(),
                  icon: const Icon(Icons.refresh),
                  label: Text(retryButtonText),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
