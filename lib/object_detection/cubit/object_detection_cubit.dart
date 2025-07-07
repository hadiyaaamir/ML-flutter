import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:ml_flutter/common/common.dart';
import 'package:ml_flutter/object_detection/object_detection.dart';
import 'package:ml_flutter/ml_media/ml_media.dart';

part 'object_detection_state.dart';

/// Cubit for managing object classification functionality
class ObjectDetectionCubit extends Cubit<ObjectDetectionState> {
  final MLMediaCubit _mlMediaCubit;
  late final ObjectDetector _staticImageDetector;
  late final ObjectDetector _liveStreamDetector;
  bool _isInitialized = false;
  StreamSubscription<CameraImage>? _cameraStreamSubscription;
  StreamSubscription<MLMediaState>? _mlMediaStateSubscription;
  Timer? _processingTimer;
  bool _isProcessingFrame = false;
  int _frameCount = 0;

  ObjectDetectionCubit({required MLMediaCubit mlMediaCubit})
    : _mlMediaCubit = mlMediaCubit,
      super(const ObjectDetectionState()) {
    _initializeServices();
    _listenToMLMediaChanges();
  }

  /// Initialize ML services and object detector
  Future<void> _initializeServices() async {
    try {
      emit(state.copyWith(objectDetectionDataState: DataState.loading()));

      // Initialize ObjectDetector for static images (better accuracy)
      _staticImageDetector = ObjectDetector(
        options: ObjectDetectorOptions(
          mode: DetectionMode.single,
          classifyObjects: true,
          multipleObjects: true,
        ),
      );

      // Initialize ObjectDetector for live stream (with tracking IDs)
      // Let's try using the same configuration as static for now
      _liveStreamDetector = ObjectDetector(
        options: ObjectDetectorOptions(
          mode: DetectionMode.single, // Try single mode for live camera too
          classifyObjects: true,
          multipleObjects: true,
        ),
      );

      _isInitialized = true;
      emit(state.copyWith(objectDetectionDataState: DataState.initial()));
    } catch (e, _) {
      emit(
        state.copyWith(
          objectDetectionDataState: state.objectDetectionDataState.toFailure(
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
              ? ObjectDetectionMode.live
              : ObjectDetectionMode.static) !=
          state.mode;

      // Update our state to reflect ML media state
      final newState = state.copyWith(
        mode:
            mlMediaState.mode == MLMediaMode.live
                ? ObjectDetectionMode.live
                : ObjectDetectionMode.static,
        isLiveCameraActive: mlMediaState.isLiveCameraActive,
        image: () => mlMediaState.image,
        // Clear detected objects and results when:
        // 1. Image was cleared, OR
        // 2. Mode changed (switching between static and live)
        detectedObjects: (imageCleared || modeChanged) ? () => null : null,
        timestamp: (imageCleared || modeChanged) ? () => null : null,
        objectDetectionDataState:
            (imageCleared || modeChanged)
                ? DataState.initial()
                : state.objectDetectionDataState,
      );

      emit(newState);
    });
  }

  /// Capture image from camera (delegates to ML media cubit)
  Future<void> captureImage() async {
    if (!_isInitialized) {
      emit(
        state.copyWith(
          objectDetectionDataState: state.objectDetectionDataState.toFailure(
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
          objectDetectionDataState: state.objectDetectionDataState.toFailure(
            error: Exception('Services not initialized'),
          ),
        ),
      );
      return;
    }

    await _mlMediaCubit.pickImageFromGallery();
  }

  /// Process the captured/selected image to detect objects
  Future<void> processImage(File imageFile) async {
    if (!_isInitialized) {
      emit(
        state.copyWith(
          objectDetectionDataState: state.objectDetectionDataState.toFailure(
            error: Exception('Services not initialized'),
          ),
        ),
      );
      return;
    }

    try {
      emit(
        state.copyWith(
          objectDetectionDataState: state.objectDetectionDataState.toLoading(),
        ),
      );

      // Start minimum loading time and actual processing simultaneously
      final minimumLoadingTime = Future.delayed(
        const Duration(milliseconds: 500),
      );

      // Create InputImage from file
      final inputImage = InputImage.fromFile(imageFile);

      // Process image with ML Kit with timeout
      final detectedObjectsFuture = _staticImageDetector
          .processImage(inputImage)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Object classification timed out after 30 seconds',
              );
            },
          );

      // Wait for both minimum loading time and processing to complete
      final results = await Future.wait([
        minimumLoadingTime,
        detectedObjectsFuture,
      ]);

      final detectedObjects = results[1] as List<DetectedObject>;

      // Convert to our model and assign manual tracking IDs for static images
      final objectResults =
          detectedObjects.asMap().entries.map((entry) {
            final index = entry.key;
            final obj = entry.value;

            // For static images, ML Kit doesn't provide tracking IDs in SINGLE_IMAGE_MODE
            // so we'll assign sequential IDs manually
            final result = ObjectDetectionResult.fromDetectedObject(obj);

            // Assign sequential tracking IDs for static images (starting from 1)
            return ObjectDetectionResult(
              boundingBox: result.boundingBox,
              labels: result.labels,
              trackingId: index + 1, // Start from 1 for better UX
            );
          }).toList();

      emit(
        state.copyWith(
          image: () => imageFile,
          detectedObjects: () => objectResults,
          timestamp: () => DateTime.now(),
          objectDetectionDataState: state.objectDetectionDataState.toLoaded(
            data: objectResults,
          ),
        ),
      );
    } catch (e, _) {
      emit(
        state.copyWith(
          objectDetectionDataState: state.objectDetectionDataState.toFailure(
            error: e,
          ),
          previousState: ObjectDetectionState(image: imageFile),
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
  Future<void> switchMode(ObjectDetectionMode mode) async {
    final mlMediaMode =
        mode == ObjectDetectionMode.live
            ? MLMediaMode.live
            : MLMediaMode.static;

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

      // For the first 50 frames, process every 20th frame to give detector time to warm up
      // After that, process every 10th frame for better performance
      final processingInterval = _frameCount < 500 ? 20 : 10;

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
        detectedObjects: () => null,
        timestamp: () => null,
        objectDetectionDataState: DataState.initial(),
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
      final detectedObjects = await _liveStreamDetector
          .processImage(inputImage)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              return <DetectedObject>[];
            },
          );

      // Convert to our model - live stream detector should provide tracking IDs
      final results =
          detectedObjects.asMap().entries.map((entry) {
            final index = entry.key;
            final obj = entry.value;
            final result = ObjectDetectionResult.fromDetectedObject(obj);

            // If tracking ID is still null (shouldn't happen in stream mode),
            // assign a sequential ID as fallback
            if (result.trackingId == null) {
              return ObjectDetectionResult(
                boundingBox: result.boundingBox,
                labels: result.labels,
                trackingId: index + 1,
              );
            }

            return result;
          }).toList();

      if (state.isLiveCameraActive) {
        emit(
          state.copyWith(
            detectedObjects: () => results,
            timestamp: () => DateTime.now(),
            objectDetectionDataState: state.objectDetectionDataState.toLoaded(
              data: results,
            ),
          ),
        );
      }
    } catch (e) {
      if (state.isLiveCameraActive) {
        emit(
          state.copyWith(
            objectDetectionDataState: state.objectDetectionDataState.toFailure(
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
    if (currentState.objectDetectionDataState.isFailure) {
      if (currentState.previousState != null) {
        emit(currentState.previousState!);
      } else {
        emit(state.copyWith(objectDetectionDataState: DataState.initial()));
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

  /// Get current detected objects if available
  List<ObjectDetectionResult>? get currentDetectedObjects {
    final currentState = state;
    if (currentState.detectedObjects != null) {
      return currentState.detectedObjects;
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

    // Dispose object detectors
    _staticImageDetector.close();
    _liveStreamDetector.close();

    return super.close();
  }
}

/// Platform-specific orientation mappings for camera image processing
const Map<int, int> orientations = {0: 0, 90: 90, 180: 180, 270: 270};
