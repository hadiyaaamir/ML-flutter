import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ml_flutter/common/common.dart';
import 'package:ml_flutter/pose_detection/models/pose_detection_result.dart';
import 'package:ml_flutter/ml_media/ml_media.dart';

part 'pose_detection_state.dart';

/// Cubit for managing pose detection functionality
class PoseDetectionCubit extends Cubit<PoseDetectionState> {
  final MLMediaCubit _mlMediaCubit;
  late final PoseDetector _staticImageDetector;
  late final PoseDetector _liveStreamDetector;
  bool _isInitialized = false;
  StreamSubscription<CameraImage>? _cameraStreamSubscription;
  StreamSubscription<MLMediaState>? _mlMediaStateSubscription;
  Timer? _processingTimer;
  bool _isProcessingFrame = false;
  int _frameCount = 0;

  PoseDetectionCubit({required MLMediaCubit mlMediaCubit})
    : _mlMediaCubit = mlMediaCubit,
      super(const PoseDetectionState()) {
    _initializeServices();
    _listenToMLMediaChanges();
  }

  /// Initialize ML services and pose detector
  Future<void> _initializeServices() async {
    try {
      emit(state.copyWith(poseDetectionDataState: DataState.loading()));

      // Initialize PoseDetector for static images
      _staticImageDetector = PoseDetector(options: PoseDetectorOptions());

      // Initialize PoseDetector for live stream
      _liveStreamDetector = PoseDetector(options: PoseDetectorOptions());

      _isInitialized = true;
      emit(state.copyWith(poseDetectionDataState: DataState.initial()));
    } catch (e, stackTrace) {
      emit(
        state.copyWith(
          poseDetectionDataState: state.poseDetectionDataState.toFailure(
            error: e,
          ),
        ),
      );
    }
  }

  /// Listen to ML media state changes and process images automatically
  void _listenToMLMediaChanges() {
    _mlMediaStateSubscription = _mlMediaCubit.stream.listen((mlMediaState) {
      // Auto-process image when a new image is captured/selected
      if (mlMediaState.image != null &&
          mlMediaState.image != state.image &&
          mlMediaState.mode == MLMediaMode.static) {
        processImage(mlMediaState.image!);
      }

      // Handle live camera mode changes
      if (mlMediaState.mode == MLMediaMode.live &&
          mlMediaState.isLiveCameraActive &&
          !state.isLiveCameraActive) {
        _startLiveCameraProcessing();
      } else if (mlMediaState.mode == MLMediaMode.static ||
          !mlMediaState.isLiveCameraActive) {
        _stopLiveCameraProcessing();
      }

      // Check if image was cleared (went from having an image to null)
      final imageCleared = state.image != null && mlMediaState.image == null;

      // Check if mode changed
      final modeChanged =
          (mlMediaState.mode == MLMediaMode.live
              ? PoseDetectionMode.live
              : PoseDetectionMode.static) !=
          state.mode;

      // Update our state to reflect ML media state
      final newState = state.copyWith(
        mode:
            mlMediaState.mode == MLMediaMode.live
                ? PoseDetectionMode.live
                : PoseDetectionMode.static,
        isLiveCameraActive: mlMediaState.isLiveCameraActive,
        image: () => mlMediaState.image,
        // Clear detected poses and results when:
        // 1. Image was cleared, OR
        // 2. Mode changed (switching between static and live)
        detectedPoses: (imageCleared || modeChanged) ? () => null : null,
        timestamp: (imageCleared || modeChanged) ? () => null : null,
        poseDetectionDataState:
            (imageCleared || modeChanged)
                ? DataState.initial()
                : state.poseDetectionDataState,
      );

      emit(newState);
    });
  }

  /// Capture image from camera (delegates to ML media cubit)
  Future<void> captureImage() async {
    if (!_isInitialized) {
      emit(
        state.copyWith(
          poseDetectionDataState: state.poseDetectionDataState.toFailure(
            error: Exception('Services not initialized'),
          ),
        ),
      );
      return;
    }

    await _mlMediaCubit.captureImage();
  }

  /// Pick image from gallery (delegates to ML media cubit)
  Future<void> pickImageFromGallery() async {
    if (!_isInitialized) {
      emit(
        state.copyWith(
          poseDetectionDataState: state.poseDetectionDataState.toFailure(
            error: Exception('Services not initialized'),
          ),
        ),
      );
      return;
    }

    await _mlMediaCubit.pickImageFromGallery();
  }

  /// Process the captured/selected image to detect poses
  Future<void> processImage(File imageFile) async {
    if (!_isInitialized) {
      emit(
        state.copyWith(
          poseDetectionDataState: state.poseDetectionDataState.toFailure(
            error: Exception('Services not initialized'),
          ),
        ),
      );
      return;
    }

    try {
      emit(
        state.copyWith(
          poseDetectionDataState: state.poseDetectionDataState.toLoading(),
        ),
      );

      // Start minimum loading time and actual processing simultaneously
      final minimumLoadingTime = Future.delayed(
        const Duration(milliseconds: 500),
      );

      // Create InputImage from file
      final inputImage = InputImage.fromFile(imageFile);

      // Process image with ML Kit with timeout
      final detectedPosesFuture = _staticImageDetector
          .processImage(inputImage)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Pose detection timed out after 30 seconds');
            },
          );

      // Wait for both minimum loading time and processing to complete
      final results = await Future.wait([
        minimumLoadingTime,
        detectedPosesFuture,
      ]);

      final detectedPoses = results[1] as List<Pose>;

      // Convert to our model
      final poseResults =
          detectedPoses
              .map((pose) => PoseDetectionResult.fromPose(pose))
              .toList();

      emit(
        state.copyWith(
          image: () => imageFile,
          detectedPoses: () => poseResults,
          timestamp: () => DateTime.now(),
          poseDetectionDataState: state.poseDetectionDataState.toLoaded(
            data: poseResults,
          ),
        ),
      );
    } catch (e, stackTrace) {
      emit(
        state.copyWith(
          poseDetectionDataState: state.poseDetectionDataState.toFailure(
            error: e,
          ),
          previousState: PoseDetectionState(image: imageFile),
        ),
      );
    }
  }

  /// Clear current results and go back to initial state
  void clearResults() {
    _mlMediaCubit.clearResults();
    // Don't emit a fresh state here - let _listenToMLMediaChanges handle it
    // to avoid race conditions with the MLMediaCubit state update
  }

  /// Switch between static and live camera modes (delegates to ML media cubit)
  Future<void> switchMode(PoseDetectionMode mode) async {
    final mlMediaMode =
        mode == PoseDetectionMode.live ? MLMediaMode.live : MLMediaMode.static;

    await _mlMediaCubit.switchMode(mlMediaMode);
  }

  /// Switch camera (delegates to ML media cubit)
  Future<void> switchCamera() async {
    await _mlMediaCubit.switchCamera();
  }

  /// Start live camera processing
  void _startLiveCameraProcessing() {
    if (!_isInitialized) {
      return;
    }

    _cameraStreamSubscription?.cancel();
    _cameraStreamSubscription = _mlMediaCubit.getCameraStream().listen((
      CameraImage cameraImage,
    ) {
      _frameCount++;

      // Process every 10th frame for pose detection
      final processingInterval = 10;

      if (_frameCount % processingInterval == 0 && !_isProcessingFrame) {
        _processLiveCameraFrame(cameraImage);
      }
    });

    emit(state.copyWith(isLiveCameraActive: true));
  }

  /// Stop live camera processing
  void _stopLiveCameraProcessing() {
    _cameraStreamSubscription?.cancel();
    _cameraStreamSubscription = null;
    _processingTimer?.cancel();
    _processingTimer = null;
    _isProcessingFrame = false;
    _frameCount = 0;

    emit(
      state.copyWith(
        isLiveCameraActive: false,
        detectedPoses: () => null,
        timestamp: () => null,
        poseDetectionDataState: DataState.initial(),
      ),
    );
  }

  /// Process a single frame from live camera
  Future<void> _processLiveCameraFrame(CameraImage cameraImage) async {
    if (_isProcessingFrame || !_isInitialized) {
      return;
    }

    _isProcessingFrame = true;

    try {
      // Convert CameraImage to InputImage for ML Kit
      final inputImage = _convertCameraImageToInputImage(cameraImage);
      if (inputImage == null) {
        return;
      }

      // Process with ML Kit with timeout for live camera
      final detectedPoses = await _liveStreamDetector
          .processImage(inputImage)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              return <Pose>[];
            },
          );

      // Convert to our model
      final poseResults =
          detectedPoses
              .map((pose) => PoseDetectionResult.fromPose(pose))
              .toList();

      if (state.isLiveCameraActive) {
        emit(
          state.copyWith(
            detectedPoses: () => poseResults,
            timestamp: () => DateTime.now(),
            poseDetectionDataState: state.poseDetectionDataState.toLoaded(
              data: poseResults,
            ),
          ),
        );
      }
    } catch (e) {
      if (state.isLiveCameraActive) {
        emit(
          state.copyWith(
            poseDetectionDataState: state.poseDetectionDataState.toFailure(
              error: e,
            ),
          ),
        );
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Convert CameraImage to InputImage for ML Kit processing
  InputImage? _convertCameraImageToInputImage(CameraImage cameraImage) {
    try {
      // Get camera description from ML media cubit
      final cameraDescription = _mlMediaCubit.cameraController?.description;
      if (cameraDescription == null) {
        return null;
      }

      // Get image rotation
      final sensorOrientation = cameraDescription.sensorOrientation;
      InputImageRotation? rotation;

      if (Platform.isIOS) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      } else if (Platform.isAndroid) {
        var rotationCompensation =
            orientations[cameraDescription.sensorOrientation] ?? 0;
        if (cameraDescription.lensDirection == CameraLensDirection.front) {
          rotationCompensation =
              (sensorOrientation + rotationCompensation) % 360;
        } else {
          rotationCompensation =
              (sensorOrientation - rotationCompensation + 360) % 360;
        }
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      }

      if (rotation == null) {
        return null;
      }

      // Get image format
      final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw);

      if (format == null) {
        return null;
      }

      // Handle different plane configurations
      if (cameraImage.planes.isEmpty) {
        return null;
      }

      // For most formats, we can use the first plane
      final plane = cameraImage.planes.first;

      // Compose InputImage using bytes from the camera image
      final inputImage = InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(
            cameraImage.width.toDouble(),
            cameraImage.height.toDouble(),
          ),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );

      return inputImage;
    } catch (e) {
      return null;
    }
  }

  /// Retry the last operation if there was an error
  void retry() {
    final currentState = state;
    if (currentState.poseDetectionDataState.isFailure) {
      if (currentState.previousState != null) {
        emit(currentState.previousState!);
      } else {
        emit(state.copyWith(poseDetectionDataState: DataState.initial()));
      }
    }
  }

  /// Check if services are initialized
  bool get isInitialized => _isInitialized;

  /// Get current image if available
  File? get currentImage {
    final currentState = state;
    if (currentState.image != null) {
      return currentState.image!;
    }
    return null;
  }

  /// Get current detected poses if available
  List<PoseDetectionResult>? get currentDetectedPoses {
    final currentState = state;
    if (currentState.detectedPoses != null) {
      return currentState.detectedPoses;
    }
    return null;
  }

  /// Get camera controller for live camera preview (delegates to ML media cubit)
  CameraController? get cameraController {
    return _mlMediaCubit.cameraController;
  }

  @override
  Future<void> close() {
    _cameraStreamSubscription?.cancel();
    _mlMediaStateSubscription?.cancel();
    _processingTimer?.cancel();

    // Dispose pose detectors
    _staticImageDetector.close();
    _liveStreamDetector.close();

    return super.close();
  }
}

/// Platform-specific orientation mappings for camera image processing
const Map<int, int> orientations = {0: 0, 90: 90, 180: 180, 270: 270};
