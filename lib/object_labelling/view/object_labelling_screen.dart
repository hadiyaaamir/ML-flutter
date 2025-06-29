part of 'view.dart';

class ObjectLabellingView extends StatelessWidget {
  const ObjectLabellingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Labelling'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: const [_ClearResultsButton()],
      ),
      body: BlocConsumer<ObjectLabellingCubit, ObjectLabellingState>(
        listener: (context, state) {
          if (state.objectLabellingDataState.isFailure) {
            context.errorSnackbar(
              state.objectLabellingDataState.errorMessage ??
                  'An error occurred',
              () => context.read<ObjectLabellingCubit>().retry(),
            );
          }
        },
        builder: (context, state) {
          return const SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Card
                _StatusCard(),
                SizedBox(height: 16),

                // Action Buttons
                _ActionButtons(),
                SizedBox(height: 16),

                // Image Display
                _ImageDisplay(),

                // Labels Display
                _LabelsDisplay(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ClearResultsButton extends StatelessWidget {
  const _ClearResultsButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectLabellingCubit, ObjectLabellingState>(
      builder: (context, state) {
        if (state.image != null || state.labels != null) {
          return IconButton(
            onPressed: () {
              context.read<ObjectLabellingCubit>().clearResults();
            },
            icon: const Icon(Icons.clear),
            tooltip: 'Clear Results',
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectLabellingCubit, ObjectLabellingState>(
      builder: (context, state) {
        String statusText;
        Color statusColor;
        IconData statusIcon;
        bool showLoading = false;

        if (state.objectLabellingDataState.isInitial) {
          statusText = 'Ready to capture or select an image';
          statusColor = Colors.blue;
          statusIcon = Icons.camera_alt;
        } else if (state.objectLabellingDataState.isLoading) {
          statusText = 'Processing...';
          statusColor = Colors.orange;
          statusIcon = Icons.hourglass_empty;
          showLoading = true;
        } else if (state.objectLabellingDataState.isFailure) {
          statusText =
              state.objectLabellingDataState.errorMessage ?? 'Error occurred';
          statusColor = Colors.red;
          statusIcon = Icons.error;
        } else if (state.labels != null && state.labels!.isNotEmpty) {
          statusText = 'Found ${state.labels!.length} labels';
          statusColor = Colors.purple;
          statusIcon = Icons.label;
        } else if (state.image != null) {
          statusText = 'Image captured! Processing...';
          statusColor = Colors.green;
          statusIcon = Icons.analytics;
          showLoading = true;
        } else {
          statusText = 'Ready to start';
          statusColor = Colors.blue;
          statusIcon = Icons.camera_alt;
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (showLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectLabellingCubit, ObjectLabellingState>(
      builder: (context, state) {
        final cubit = context.read<ObjectLabellingCubit>();
        final isLoading = state.objectLabellingDataState.isLoading;
        final hasResults = state.labels != null && state.labels!.isNotEmpty;

        return Column(
          children: [
            // Capture/Select Image Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : () => cubit.captureImage(),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Capture Image'),
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
                    label: const Text('Select Image'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            // Try Again Button (only show if we have results)
            if (hasResults) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : () => cubit.clearResults(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Another Image'),
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

class _ImageDisplay extends StatelessWidget {
  const _ImageDisplay();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectLabellingCubit, ObjectLabellingState>(
      builder: (context, state) {
        if (state.image == null) return const SizedBox.shrink();

        return Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Captured Image',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 300),
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

class _LabelsDisplay extends StatelessWidget {
  const _LabelsDisplay();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectLabellingCubit, ObjectLabellingState>(
      builder: (context, state) {
        if (state.labels == null) return const SizedBox.shrink();

        if (state.labels!.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No objects detected',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.label, color: Colors.purple),
                    const SizedBox(width: 8),
                    const Text(
                      'Detected Objects',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Chip(
                      label: Text('${state.labels!.length} found'),
                      backgroundColor: Colors.purple.withValues(alpha: 0.1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...state.labels!.map((label) => _LabelItem(label: label)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LabelItem extends StatelessWidget {
  const _LabelItem({required this.label});

  final LabelResult label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: label.isConfident() ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Confidence: ${label.confidencePercentage}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  label.isConfident()
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label.confidencePercentage,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: label.isConfident() ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
