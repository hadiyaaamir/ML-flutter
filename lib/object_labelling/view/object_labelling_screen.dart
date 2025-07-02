part of 'view.dart';

class ObjectLabellingView extends StatelessWidget {
  const ObjectLabellingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Labelling'),
        centerTitle: true,
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
                // Mode Toggle
                _ObjectLabellingModeToggle(),
                SizedBox(height: 16),

                // Status Card
                _ObjectLabellingStatusCard(),
                SizedBox(height: 16),

                // Live Camera View or Action Buttons
                _CameraOrActionSection(),
                SizedBox(height: 16),

                // Image Display (for static mode)
                _ObjectLabellingImageDisplay(),

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

/// Custom mode toggle that handles object labelling specific logic
class _ObjectLabellingModeToggle extends StatelessWidget {
  const _ObjectLabellingModeToggle();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectLabellingCubit, ObjectLabellingState>(
      builder: (context, state) {
        final cubit = context.read<ObjectLabellingCubit>();
        final isLoading = state.objectLabellingDataState.isLoading;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detection Mode',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            isLoading
                                ? null
                                : () => cubit.switchMode(
                                  ObjectLabellingMode.static,
                                ),
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Static Image'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor:
                              state.mode == ObjectLabellingMode.static
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                          foregroundColor:
                              state.mode == ObjectLabellingMode.static
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            isLoading
                                ? null
                                : () =>
                                    cubit.switchMode(ObjectLabellingMode.live),
                        icon: const Icon(Icons.videocam),
                        label: const Text('Live Camera'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor:
                              state.mode == ObjectLabellingMode.live
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                          foregroundColor:
                              state.mode == ObjectLabellingMode.live
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
                        ),
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

/// Custom status card for object labelling
class _ObjectLabellingStatusCard extends StatelessWidget {
  const _ObjectLabellingStatusCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectLabellingCubit, ObjectLabellingState>(
      builder: (context, state) {
        final config = MLStatusConfig(
          staticResultsMessage:
              state.labels != null && state.labels!.isNotEmpty
                  ? 'Found ${state.labels!.length} labels'
                  : null,
          liveDetectingMessage:
              state.liveCameraLabels.isNotEmpty
                  ? 'Live detection: ${state.liveCameraLabels.length} objects found'
                  : null,
        );

        final hasResults =
            (state.labels != null && state.labels!.isNotEmpty) ||
            state.liveCameraLabels.isNotEmpty;
        final resultCount =
            state.mode == ObjectLabellingMode.live
                ? state.liveCameraLabels.length
                : state.labels?.length ?? 0;

        return MLStatusCard(
          config: config,
          hasResults: hasResults,
          resultCount: resultCount,
        );
      },
    );
  }
}

class _CameraOrActionSection extends StatelessWidget {
  const _CameraOrActionSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectLabellingCubit, ObjectLabellingState>(
      builder: (context, state) {
        if (state.mode == ObjectLabellingMode.live) {
          return const _ObjectLabellingCameraPreview();
        } else {
          return const _ObjectLabellingActionButtons();
        }
      },
    );
  }
}

/// Custom camera preview for object labelling with live detection indicator
class _ObjectLabellingCameraPreview extends StatelessWidget {
  const _ObjectLabellingCameraPreview();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectLabellingCubit, ObjectLabellingState>(
      builder: (context, state) {
        if (!state.isLiveCameraActive) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            const MLCameraPreview(
              title: 'Live Camera Feed',
              showSwitchButton: true,
            ),
            const SizedBox(height: 8),
            // Live detection status indicator
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      state.liveCameraLabels.isNotEmpty
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color:
                          state.liveCameraLabels.isNotEmpty
                              ? Colors.green
                              : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.liveCameraLabels.isNotEmpty
                          ? 'Detecting objects...'
                          : 'Looking for objects...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom action buttons for object labelling
class _ObjectLabellingActionButtons extends StatelessWidget {
  const _ObjectLabellingActionButtons();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectLabellingCubit, ObjectLabellingState>(
      builder: (context, state) {
        final hasResults = state.labels != null && state.labels!.isNotEmpty;

        return MLActionButtons(
          hasResults: hasResults,
          retryButtonText: 'Try Another Image',
        );
      },
    );
  }
}

/// Custom image display for object labelling
class _ObjectLabellingImageDisplay extends StatelessWidget {
  const _ObjectLabellingImageDisplay();

  @override
  Widget build(BuildContext context) {
    return const MLImageDisplay(title: 'Captured Image');
  }
}

class _ClearResultsButton extends StatelessWidget {
  const _ClearResultsButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectLabellingCubit, ObjectLabellingState>(
      builder: (context, state) {
        // Show clear button if we have static results or if we're in live mode
        final hasStaticResults =
            state.image != null ||
            (state.labels != null && state.labels!.isNotEmpty);
        final hasLiveResults =
            state.mode == ObjectLabellingMode.live && state.isLiveCameraActive;

        if (hasStaticResults || hasLiveResults) {
          return IconButton(
            onPressed: () {
              context.read<ObjectLabellingCubit>().clearResults();
            },
            icon: const Icon(Icons.clear),
            tooltip:
                state.mode == ObjectLabellingMode.live
                    ? 'Stop Live Camera'
                    : 'Clear Results',
          );
        }
        return const SizedBox.shrink();
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
        // Get labels based on current mode
        final labels =
            state.mode == ObjectLabellingMode.live
                ? state.liveCameraLabels
                : state.labels;

        if (labels == null || labels.isEmpty) {
          // Only show "no objects" message if we're not in live mode or if live mode has no labels
          if (state.mode == ObjectLabellingMode.static &&
              state.image != null &&
              state.objectLabellingDataState.isNotInitial) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No objects detected',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final modeText =
            state.mode == ObjectLabellingMode.live
                ? 'Live Detection Results'
                : 'Detected Objects';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      state.mode == ObjectLabellingMode.live
                          ? Icons.visibility
                          : Icons.label,
                      color: Colors.purple,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      modeText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Chip(
                      label: Text('${labels.length} found'),
                      backgroundColor: Colors.purple.withValues(alpha: 0.1),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                if (state.mode == ObjectLabellingMode.live) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.update, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Updates in real-time',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                ...labels.map((label) => _LabelItem(label: label)),
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
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: label.isConfident() ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label.label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color:
                  label.isConfident()
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label.confidencePercentage,
              style: TextStyle(
                fontSize: 11,
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
