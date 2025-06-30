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
                // Mode Toggle
                _ModeToggle(),
                SizedBox(height: 16),

                // Status Card
                _StatusCard(),
                SizedBox(height: 16),

                // Live Camera View or Action Buttons
                _CameraOrActionSection(),
                SizedBox(height: 16),

                // Image Display (for static mode)
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

class _ModeToggle extends StatelessWidget {
  const _ModeToggle();

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
                      child: _ModeButton(
                        icon: Icons.photo_camera,
                        label: 'Static Image',
                        isSelected: state.mode == ObjectLabellingMode.static,
                        onPressed:
                            isLoading
                                ? null
                                : () => cubit.switchMode(
                                  ObjectLabellingMode.static,
                                ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ModeButton(
                        icon: Icons.videocam,
                        label: 'Live Camera',
                        isSelected: state.mode == ObjectLabellingMode.live,
                        onPressed:
                            isLoading
                                ? null
                                : () =>
                                    cubit.switchMode(ObjectLabellingMode.live),
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

class _ModeButton extends StatelessWidget {
  const _ModeButton({
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

class _CameraOrActionSection extends StatelessWidget {
  const _CameraOrActionSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectLabellingCubit, ObjectLabellingState>(
      builder: (context, state) {
        if (state.mode == ObjectLabellingMode.live) {
          return const _LiveCameraView();
        } else {
          return const _ActionButtons();
        }
      },
    );
  }
}

class _LiveCameraView extends StatelessWidget {
  const _LiveCameraView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectLabellingCubit, ObjectLabellingState>(
      builder: (context, state) {
        final cubit = context.read<ObjectLabellingCubit>();

        if (!state.isLiveCameraActive) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Live Camera Feed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => cubit.switchCamera(),
                      icon: const Icon(Icons.switch_camera),
                      tooltip: 'Switch Camera',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const _CameraPreviewWidget(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
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
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CameraPreviewWidget extends StatefulWidget {
  const _CameraPreviewWidget();

  @override
  State<_CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<_CameraPreviewWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectLabellingCubit, ObjectLabellingState>(
      builder: (context, state) {
        final cubit = context.read<ObjectLabellingCubit>();
        final cameraController = cubit.cameraController;

        if (cameraController == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Initializing camera...'),
              ],
            ),
          );
        }

        if (!cameraController.value.isInitialized) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Setting up camera...'),
              ],
            ),
          );
        }

        // Wrap CameraPreview in error handling
        return Builder(
          builder: (context) {
            try {
              // Double-check that controller is still valid before building preview
              if (cameraController.value.isInitialized) {
                return CameraPreview(cameraController);
              } else {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text('Camera not ready'),
                    ],
                  ),
                );
              }
            } catch (e) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Camera error: ${e.toString()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed:
                          () => cubit.switchMode(ObjectLabellingMode.live),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
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

        if (state.mode == ObjectLabellingMode.live) {
          // Live camera mode status
          if (state.objectLabellingDataState.isLoading) {
            statusText = 'Starting live camera...';
            statusColor = Colors.orange;
            statusIcon = Icons.videocam;
            showLoading = true;
          } else if (state.isLiveCameraActive) {
            if (state.liveCameraLabels.isNotEmpty) {
              statusText =
                  'Live detection: ${state.liveCameraLabels.length} objects found';
              statusColor = Colors.green;
              statusIcon = Icons.visibility;
            } else {
              statusText = 'Live camera active - Looking for objects...';
              statusColor = Colors.blue;
              statusIcon = Icons.videocam;
            }
          } else if (state.objectLabellingDataState.isFailure) {
            statusText =
                state.objectLabellingDataState.errorMessage ?? 'Camera error';
            statusColor = Colors.red;
            statusIcon = Icons.error;
          } else {
            statusText = 'Ready to start live detection';
            statusColor = Colors.blue;
            statusIcon = Icons.videocam;
          }
        } else {
          // Static image mode status
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
        // Only show image in static mode
        if (state.mode == ObjectLabellingMode.live || state.image == null) {
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
        // Get labels based on current mode
        final labels =
            state.mode == ObjectLabellingMode.live
                ? state.liveCameraLabels
                : state.labels;

        if (labels == null || labels.isEmpty) {
          // Only show "no objects" message if we're not in live mode or if live mode has no labels
          if (state.mode == ObjectLabellingMode.static && state.image != null) {
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
            padding: const EdgeInsets.all(16.0),
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
                    ),
                    const SizedBox(width: 8),
                    Text(
                      modeText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Chip(
                      label: Text('${labels.length} found'),
                      backgroundColor: Colors.purple.withValues(alpha: 0.1),
                    ),
                  ],
                ),
                if (state.mode == ObjectLabellingMode.live) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.update, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Updates in real-time',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
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
