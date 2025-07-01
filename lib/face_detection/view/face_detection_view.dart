part of 'view.dart';

/// Main view for face detection
class FaceDetectionView extends StatelessWidget {
  const FaceDetectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Detection'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocBuilder<FaceDetectionCubit, FaceDetectionState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                MLModeToggle(title: 'Face Detection Mode'),
                _FaceDetectionStatusCard(),
                // Live mode: filters and toggles above camera
                if (state.mode == FaceDetectionMode.live) ...[
                  if (state.currentFaces.isNotEmpty || state.isLiveCameraActive)
                    _FaceDetectionCameraPreview(),
                ] else ...[
                  // Static mode: action buttons, then image with toggles, then filters
                  _FaceDetectionActionButtons(),
                  _FaceDetectionImageDisplay(),
                  if (state.currentFaces.isNotEmpty) _FaceFilterSection(),
                ],
                _DetectedFaces(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Face filter selection section
class _FaceFilterSection extends StatelessWidget {
  const _FaceFilterSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FaceDetectionCubit, FaceDetectionState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Face Filters',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FaceFilterSelector(
              selectedFilter: state.selectedFilter,
              onFilterSelected: (filter) {
                context.read<FaceDetectionCubit>().selectFilter(filter);
              },
            ),
          ],
        );
      },
    );
  }
}

/// Custom status card for face detection
class _FaceDetectionStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FaceDetectionCubit, FaceDetectionState>(
      builder: (context, state) {
        String statusText;
        Color statusColor;
        IconData statusIcon;
        bool showLoading = false;

        if (state.mode == FaceDetectionMode.live) {
          // Live camera mode status
          if (state.isLiveCameraActive) {
            if (state.liveCameraFaces?.isNotEmpty == true) {
              statusText = 'Faces detected: ${state.liveCameraFaces!.length}';
              statusColor = Colors.green;
              statusIcon = Icons.face;
            } else {
              statusText = 'Live face detection active';
              statusColor = Colors.blue;
              statusIcon = Icons.videocam;
            }
          } else {
            statusText = 'Ready to start live detection';
            statusColor = Colors.blue;
            statusIcon = Icons.videocam;
          }
        } else {
          // Static image mode status
          if (state.faceDetectionDataState.isInitial) {
            statusText = 'Ready to detect faces';
            statusColor = Colors.blue;
            statusIcon = Icons.camera_alt;
          } else if (state.faceDetectionDataState.isLoading) {
            statusText = 'Detecting faces...';
            statusColor = Colors.orange;
            statusIcon = Icons.hourglass_empty;
            showLoading = true;
          } else if (state.faceDetectionDataState.isFailure) {
            statusText =
                state.faceDetectionDataState.errorMessage ?? 'Error occurred';
            statusColor = Colors.red;
            statusIcon = Icons.error;
          } else if (state.currentFaces.isNotEmpty) {
            statusText = 'Found ${state.currentFaces.length} face(s)';
            statusColor = Colors.purple;
            statusIcon = Icons.face;
          } else if (state.image != null) {
            statusText = 'No faces detected';
            statusColor = Colors.grey;
            statusIcon = Icons.face_unlock_outlined;
          } else {
            statusText = 'Ready to detect faces';
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

/// Custom camera preview for face detection with overlay
class _FaceDetectionCameraPreview extends StatelessWidget {
  const _FaceDetectionCameraPreview();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FaceDetectionCubit, FaceDetectionState>(
      builder: (context, state) {
        if (!state.isLiveCameraActive) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            // Custom camera preview card with integrated toggles
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with title and switch camera button
                    Row(
                      children: [
                        const Text(
                          'Live Face Detection',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed:
                              () => context.read<MLMediaCubit>().switchCamera(),
                          icon: const Icon(Icons.switch_camera),
                          tooltip: 'Switch Camera',
                        ),
                      ],
                    ),

                    // Toggles row directly below title
                    Row(
                      children: [
                        _LabelsToggle(showLabels: state.showLabels),
                        const SizedBox(width: 16),
                        _ContoursToggle(showContours: state.showContours),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Camera preview
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 400),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: const _CameraPreviewWidget(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.liveCameraFaces?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _FaceFilterSection(),
            ],
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
                      state.liveCameraFaces?.isNotEmpty == true
                          ? Icons.face
                          : Icons.search,
                      color:
                          state.liveCameraFaces?.isNotEmpty == true
                              ? Colors.green
                              : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.liveCameraFaces?.isNotEmpty == true
                          ? 'Faces detected: ${state.liveCameraFaces?.length}'
                          : 'Looking for faces...',
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

/// Camera preview widget that reuses existing components for face detection overlay
class _CameraPreviewWidget extends StatefulWidget {
  const _CameraPreviewWidget();

  @override
  State<_CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<_CameraPreviewWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MLMediaCubit, MLMediaState>(
      builder: (context, mlState) {
        final cubit = context.read<MLMediaCubit>();
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
          key: ValueKey(
            '${cameraController.description.name}_${mlState.timestamp?.millisecondsSinceEpoch}',
          ),
          builder: (context) {
            try {
              // Double-check that controller is still valid before building preview
              if (cameraController.value.isInitialized) {
                // Get the camera's aspect ratio to prevent squishing
                final aspectRatio = cameraController.value.aspectRatio;

                return BlocBuilder<FaceDetectionCubit, FaceDetectionState>(
                  builder: (context, faceState) {
                    return AspectRatio(
                      aspectRatio: aspectRatio,
                      child: Stack(
                        children: [
                          // Camera preview base
                          OverflowBox(
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width:
                                    cameraController
                                        .value
                                        .previewSize
                                        ?.height ??
                                    1,
                                height:
                                    cameraController.value.previewSize?.width ??
                                    1,
                                child: CameraPreview(cameraController),
                              ),
                            ),
                          ),

                          // Face detection overlay - REUSE existing FacePainter and FaceImageFilterOverlay
                          if (faceState.liveCameraFaces?.isNotEmpty == true)
                            Positioned.fill(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final previewSize =
                                      cameraController.value.previewSize;
                                  if (previewSize == null) {
                                    return const SizedBox.shrink();
                                  }

                                  final containerSize = Size(
                                    constraints.maxWidth,
                                    constraints.maxHeight,
                                  );

                                  return Stack(
                                    children: [
                                      // Use specialized LiveCameraFacePainter for face detection overlay
                                      CustomPaint(
                                        painter: LiveCameraFacePainter(
                                          faces: faceState.liveCameraFaces!,
                                          cameraPreviewSize: Size(
                                            previewSize.height,
                                            previewSize.width,
                                          ),
                                          containerSize: containerSize,
                                          showContours: faceState.showContours,
                                          showLabels: faceState.showLabels,
                                        ),
                                        child: Container(),
                                      ),

                                      // Use specialized LiveCameraFilterOverlay for filters
                                      if (faceState.selectedFilter !=
                                          FaceFilterType.none)
                                        LiveCameraFilterOverlay(
                                          faces: faceState.liveCameraFaces!,
                                          cameraPreviewSize: Size(
                                            previewSize.height,
                                            previewSize.width,
                                          ),
                                          containerSize: containerSize,
                                          selectedFilter:
                                              faceState.selectedFilter,
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
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
                          () => context.read<MLMediaCubit>().switchMode(
                            MLMediaMode.live,
                          ),
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

/// Custom image display for face detection with overlay
class _FaceDetectionImageDisplay extends StatelessWidget {
  const _FaceDetectionImageDisplay();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FaceDetectionCubit, FaceDetectionState>(
      builder: (context, state) {
        if (state.mode == FaceDetectionMode.live || state.image == null) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with toggles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Face Detection Result',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Toggles column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    _LabelsToggle(showLabels: state.showLabels),
                    _ContoursToggle(showContours: state.showContours),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Image display with contours and labels
            FaceDetectionImageDisplay(
              image: state.image,
              faces: state.faces ?? [],
              title: '', // No title since we show it above
              maxHeight: 400,
              showContours: state.showContours,
              showLabels: state.showLabels,
              selectedFilter: state.selectedFilter,
            ),
          ],
        );
      },
    );
  }
}

class _ContoursToggle extends StatelessWidget {
  const _ContoursToggle({required this.showContours});

  final bool showContours;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timeline,
          size: 16,
          color: showContours ? Colors.blue : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          'Contours',
          style: TextStyle(
            fontSize: 12,
            color: showContours ? Colors.blue : Colors.grey,
          ),
        ),
        Transform.scale(
          scale: 0.5,
          child: SizedBox(
            height: 20,
            width: 40,
            child: Switch(
              value: showContours,
              onChanged: (_) {
                context.read<FaceDetectionCubit>().toggleContours();
              },
              activeColor: Colors.blue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }
}

class _LabelsToggle extends StatelessWidget {
  const _LabelsToggle({required this.showLabels});

  final bool showLabels;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.label,
          size: 16,
          color: showLabels ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          'Labels',
          style: TextStyle(
            fontSize: 12,
            color: showLabels ? Colors.green : Colors.grey,
          ),
        ),

        Transform.scale(
          scale: 0.5,
          child: SizedBox(
            width: 40,
            height: 20,
            child: Switch(
              value: showLabels,
              padding: EdgeInsets.zero,
              onChanged: (_) {
                context.read<FaceDetectionCubit>().toggleLabels();
              },
              activeColor: Colors.green,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom action buttons for face detection
class _FaceDetectionActionButtons extends StatelessWidget {
  const _FaceDetectionActionButtons();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FaceDetectionCubit, FaceDetectionState>(
      builder: (context, state) {
        return MLActionButtons(
          captureButtonText: 'Detect Faces',
          galleryButtonText: 'Select Image',
          retryButtonText: 'Try Another Image',
          hasResults: state.currentFaces.isNotEmpty,
          showRetryButton: true,
        );
      },
    );
  }
}

/// Widget to display detected faces with detailed information
class _DetectedFaces extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FaceDetectionCubit, FaceDetectionState>(
      builder: (context, state) {
        final faces = state.currentFaces;

        if (faces.isEmpty) {
          // Show "no faces" message if we processed an image but found no faces
          if (state.mode == FaceDetectionMode.static &&
              state.image != null &&
              state.faceDetectionDataState.isLoaded) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.face_unlock_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No faces detected',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try a different image or angle',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Detected Faces (${faces.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: faces.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final face = faces[index];
                    return _FaceCard(face: face, faceIndex: index);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Card widget for displaying individual face information
class _FaceCard extends StatelessWidget {
  final Face face;
  final int faceIndex;

  const _FaceCard({required this.face, required this.faceIndex});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.face,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Face ${faceIndex + 1}${face.trackingId != null ? ' (ID: ${face.trackingId})' : ''}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Bounding box info
            Text(
              'Position: (${face.boundingBox.left.toInt()}, ${face.boundingBox.top.toInt()}) - (${face.boundingBox.right.toInt()}, ${face.boundingBox.bottom.toInt()})',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),

            // Classification results
            if (face.smilingProbability != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    face.smilingProbability! > 0.5
                        ? Icons.sentiment_satisfied
                        : Icons.sentiment_neutral,
                    size: 16,
                    color:
                        face.smilingProbability! > 0.5
                            ? Colors.green
                            : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Smiling: ${(face.smilingProbability! * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],

            if (face.leftEyeOpenProbability != null &&
                face.rightEyeOpenProbability != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    face.leftEyeOpenProbability! > 0.5 &&
                            face.rightEyeOpenProbability! > 0.5
                        ? Icons.visibility
                        : Icons.visibility_off,
                    size: 16,
                    color:
                        face.leftEyeOpenProbability! > 0.5 &&
                                face.rightEyeOpenProbability! > 0.5
                            ? Colors.blue
                            : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Eyes Open: L${(face.leftEyeOpenProbability! * 100).toInt()}% R${(face.rightEyeOpenProbability! * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],

            // Head pose
            if (face.headEulerAngleY != null) ...[
              const SizedBox(height: 4),
              Text(
                'Head Pose: Y${face.headEulerAngleY!.toInt()}° Z${face.headEulerAngleZ?.toInt() ?? 0}°',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],

            // Feature counts
            const SizedBox(height: 4),
            Text(
              'Features: ${face.landmarks.length} landmarks, ${face.contours.length} contours',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
