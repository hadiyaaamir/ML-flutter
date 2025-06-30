import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:ml_flutter/common/common.dart';
import 'package:ml_flutter/object_labelling/object_labelling.dart';
import 'package:ml_flutter/services/services.dart';

part 'object_labelling_state.dart';

/// Cubit for managing object labelling functionality
class ObjectLabellingCubit extends Cubit<ObjectLabellingState> {
  final MLMediaService _mlMediaService;
  late final ImageLabeler _imageLabeler;
  bool _isInitialized = false;
  StreamSubscription<CameraImage>? _cameraStreamSubscription;
  Timer? _processingTimer;
  bool _isProcessingFrame = false;
  int _frameCount = 0; // Add frame counter for debugging

  ObjectLabellingCubit({required MLMediaService mlMediaService})
    : _mlMediaService = mlMediaService,
      super(const ObjectLabellingState()) {
    _initializeServices();
  }

  /// Initialize ML services and image labeler
  Future<void> _initializeServices() async {
    try {
      emit(state.copyWith(objectLabellingDataState: DataState.loading()));

      await _mlMediaService.initialize();

      // Initialize ImageLabeler with optimized settings for real-time processing
      _imageLabeler = ImageLabeler(
        options: ImageLabelerOptions(
          confidenceThreshold: 0.5, // Lower threshold for better detection
        ),
      );

      _isInitialized = true;
      emit(state.copyWith(objectLabellingDataState: DataState.initial()));
    } catch (e) {
      emit(
        state.copyWith(
          objectLabellingDataState: state.objectLabellingDataState.toFailure(
            error: e,
          ),
        ),
      );
    }
  }

  /// Capture image from camera
  Future<void> captureImage() async {
    if (!_isInitialized) {
      emit(
        state.copyWith(
          objectLabellingDataState: state.objectLabellingDataState.toFailure(
            error: Exception('Services not initialized'),
          ),
        ),
      );
      return;
    }

    try {
      emit(
        state.copyWith(
          objectLabellingDataState: state.objectLabellingDataState.toLoading(),
        ),
      );

      final image = await _mlMediaService.captureImageFromCamera();

      if (image != null) {
        await processImage(image);
      } else {
        emit(
          state.copyWith(
            objectLabellingDataState: state.objectLabellingDataState.toFailure(
              error: Exception('Failed to capture image'),
            ),
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          objectLabellingDataState: state.objectLabellingDataState.toFailure(
            error: e,
          ),
        ),
      );
    }
  }

  /// Pick image from gallery
  Future<void> pickImageFromGallery() async {
    if (!_isInitialized) {
      emit(
        state.copyWith(
          objectLabellingDataState: state.objectLabellingDataState.toFailure(
            error: Exception('Services not initialized'),
          ),
        ),
      );
      return;
    }

    try {
      emit(
        state.copyWith(
          objectLabellingDataState: state.objectLabellingDataState.toLoading(),
        ),
      );

      final image = await _mlMediaService.pickImageFromGallery();

      if (image != null) {
        // Automatically process the image after selection
        await processImage(image);
      } else {
        emit(
          state.copyWith(
            objectLabellingDataState: state.objectLabellingDataState.toFailure(
              error: Exception('No image selected'),
            ),
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          objectLabellingDataState: state.objectLabellingDataState.toFailure(
            error: e,
          ),
        ),
      );
    }
  }

  /// Process the captured/selected image to detect labels
  Future<void> processImage(File imageFile) async {
    if (!_isInitialized) {
      emit(
        state.copyWith(
          objectLabellingDataState: state.objectLabellingDataState.toFailure(
            error: Exception('Services not initialized'),
          ),
        ),
      );
      return;
    }

    try {
      emit(
        state.copyWith(
          objectLabellingDataState: state.objectLabellingDataState.toLoading(),
        ),
      );

      // Create InputImage from file
      final inputImage = InputImage.fromFile(imageFile);

      // Process image with ML Kit
      final labels = await _imageLabeler.processImage(inputImage);

      // Convert to our model
      final labelResults =
          labels.map((label) => LabelResult.fromImageLabel(label)).toList();

      // Sort by confidence (highest first)
      labelResults.sort((a, b) => b.confidence.compareTo(a.confidence));

      emit(
        state.copyWith(
          image: imageFile,
          labels: labelResults,
          timestamp: DateTime.now(),
          objectLabellingDataState: state.objectLabellingDataState.toLoaded(
            data: labelResults,
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          objectLabellingDataState: state.objectLabellingDataState.toFailure(
            error: e,
          ),
          previousState: ObjectLabellingState(image: imageFile),
        ),
      );
    }
  }

  /// Clear current results and go back to initial state
  void clearResults() {
    emit(ObjectLabellingState(mode: state.mode));
  }

  /// Switch between static and live camera modes
  Future<void> switchMode(ObjectLabellingMode mode) async {
    if (state.mode == mode) return;

    try {
      if (mode == ObjectLabellingMode.live) {
        await startLiveCamera();
      } else {
        await stopLiveCamera();
        emit(
          state.copyWith(
            mode: ObjectLabellingMode.static,
            isLiveCameraActive: false,
            liveCameraLabels: [],
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          objectLabellingDataState: state.objectLabellingDataState.toFailure(
            error: e,
          ),
        ),
      );
    }
  }

  /// Start live camera for real-time object detection
  Future<void> startLiveCamera() async {
    if (!_isInitialized) {
      emit(
        state.copyWith(
          objectLabellingDataState: state.objectLabellingDataState.toFailure(
            error: Exception('Services not initialized'),
          ),
        ),
      );
      return;
    }

    try {
      emit(
        state.copyWith(
          objectLabellingDataState: state.objectLabellingDataState.toLoading(),
          mode: ObjectLabellingMode.live,
        ),
      );

      // Start ML-optimized camera for object detection
      await _mlMediaService.startMLObjectDetection();

      // Start image stream and process frames
      final imageStream = _mlMediaService.getCameraStream();

      _cameraStreamSubscription = imageStream.listen(
        (cameraImage) {
          _processLiveCameraFrame(cameraImage);
        },
        onError: (error) {
          // Handle stream errors silently or emit error state if needed
        },
      );

      emit(
        state.copyWith(
          mode: ObjectLabellingMode.live,
          isLiveCameraActive: true,
          objectLabellingDataState: state.objectLabellingDataState.toLoaded(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          objectLabellingDataState: state.objectLabellingDataState.toFailure(
            error: e,
          ),
        ),
      );
    }
  }

  /// Stop live camera
  Future<void> stopLiveCamera() async {
    try {
      _processingTimer?.cancel();
      _processingTimer = null;

      await _cameraStreamSubscription?.cancel();
      _cameraStreamSubscription = null;

      await _mlMediaService.stopLiveCamera();

      emit(
        state.copyWith(
          mode: ObjectLabellingMode.static,
          isLiveCameraActive: false,
          liveCameraLabels: [],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          objectLabellingDataState: state.objectLabellingDataState.toFailure(
            error: e,
          ),
        ),
      );
    }
  }

  /// Switch camera (front/back) during live mode
  Future<void> switchCamera() async {
    if (!state.isLiveCameraActive) return;

    try {
      // Temporarily pause processing during camera switch
      _processingTimer?.cancel();
      _isProcessingFrame = false;

      // Stop current image stream
      await _cameraStreamSubscription?.cancel();
      _cameraStreamSubscription = null;

      // Switch camera using the service
      await _mlMediaService.switchCamera();

      // Restart image stream if camera is still active
      if (state.isLiveCameraActive &&
          _mlMediaService.cameraController != null) {
        final imageStream = _mlMediaService.getCameraStream();
        _cameraStreamSubscription = imageStream.listen(_processLiveCameraFrame);
      }
    } catch (e) {
      // If switching fails, try to restart the camera
      try {
        await _restartLiveCamera();
      } catch (restartError) {
        emit(
          state.copyWith(
            objectLabellingDataState: state.objectLabellingDataState.toFailure(
              error: Exception('Failed to switch camera: $e'),
            ),
          ),
        );
      }
    }
  }

  /// Restart live camera after an error
  Future<void> _restartLiveCamera() async {
    await stopLiveCamera();
    await startLiveCamera();
  }

  /// Process camera frame for real-time object detection
  void _processLiveCameraFrame(CameraImage cameraImage) {
    _frameCount++;

    // Skip if already processing a frame (ML Kit best practice)
    if (_isProcessingFrame) {
      return;
    }

    // Only process every 15th frame to throttle performance
    if (_frameCount % 15 != 0) {
      return;
    }

    if (!state.isLiveCameraActive) {
      return;
    }

    _isProcessingFrame = true;

    // Process frame asynchronously to avoid blocking the camera stream
    _processFrameImmediate(cameraImage).whenComplete(() {
      _isProcessingFrame = false;
    });
  }

  /// Process frame immediately without Timer delay
  Future<void> _processFrameImmediate(CameraImage cameraImage) async {
    try {
      // Convert CameraImage to InputImage for ML Kit
      final inputImage = _convertCameraImageToInputImage(cameraImage);
      if (inputImage == null) {
        return;
      }

      // Process with ML Kit
      final labels = await _imageLabeler.processImage(inputImage);

      // Convert to our model and sort by confidence
      final labelResults =
          labels.map((label) => LabelResult.fromImageLabel(label)).toList()
            ..sort((a, b) => b.confidence.compareTo(a.confidence));

      // Update state with new labels only if camera is still active
      if (state.isLiveCameraActive) {
        emit(
          state.copyWith(
            liveCameraLabels: labelResults,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      // Continue processing next frames - don't emit error state for individual frame failures
    }
  }

  /// Convert CameraImage to InputImage for ML Kit processing
  InputImage? _convertCameraImageToInputImage(CameraImage cameraImage) {
    try {
      final camera = _mlMediaService.cameraController?.description;
      if (camera == null) {
        return null;
      }

      // Get image rotation using the official ML Kit approach
      final sensorOrientation = camera.sensorOrientation;
      InputImageRotation? rotation;

      if (Platform.isIOS) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      } else if (Platform.isAndroid) {
        // Get device orientation mappings
        final orientations = {
          DeviceOrientation.portraitUp: 0,
          DeviceOrientation.landscapeLeft: 90,
          DeviceOrientation.portraitDown: 180,
          DeviceOrientation.landscapeRight: 270,
        };

        var rotationCompensation =
            orientations[_mlMediaService
                .cameraController
                ?.value
                .deviceOrientation];
        if (rotationCompensation == null) {
          return null;
        }

        if (camera.lensDirection == CameraLensDirection.front) {
          // front-facing
          rotationCompensation =
              (sensorOrientation + rotationCompensation) % 360;
        } else {
          // back-facing
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

      // Validate format depending on platform - only supported formats:
      // * nv21 for Android
      // * bgra8888 for iOS
      if (format == null ||
          (Platform.isAndroid && format != InputImageFormat.nv21) ||
          (Platform.isIOS && format != InputImageFormat.bgra8888)) {
        return null;
      }

      // Since format is constrained to nv21 or bgra8888, both only have one plane
      if (cameraImage.planes.length != 1) {
        return null;
      }

      final plane = cameraImage.planes.first;

      // Compose InputImage using bytes from the single plane
      final inputImage = InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(
            cameraImage.width.toDouble(),
            cameraImage.height.toDouble(),
          ),
          rotation: rotation, // used only in Android
          format: format, // used only in iOS
          bytesPerRow: plane.bytesPerRow, // used only in iOS
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
    if (currentState.objectLabellingDataState.isFailure) {
      if (currentState.previousState != null) {
        emit(currentState.previousState!);
      } else {
        emit(state.copyWith(objectLabellingDataState: DataState.initial()));
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

  /// Get current labels if available
  List<LabelResult>? get currentLabels {
    final currentState = state;
    if (currentState.labels != null) {
      return currentState.labels;
    }
    return null;
  }

  /// Get camera controller for live camera preview
  CameraController? get cameraController {
    final controller = _mlMediaService.cameraController;
    if (controller == null) return null;

    try {
      // Check if controller is initialized and not disposed
      if (controller.value.isInitialized) {
        return controller;
      }
    } catch (e) {
      // Controller might be disposed, return null
      return null;
    }

    return null;
  }

  @override
  Future<void> close() async {
    // Clean up live camera resources
    _processingTimer?.cancel();
    await _cameraStreamSubscription?.cancel();
    await _mlMediaService.dispose();

    // Clean up ML Kit resources
    await _imageLabeler.close();

    return super.close();
  }
}
