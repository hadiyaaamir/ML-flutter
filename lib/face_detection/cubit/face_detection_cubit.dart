import 'dart:io';
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:ml_flutter/common/common.dart';
import 'package:ml_flutter/ml_media/ml_media.dart';

import '../models/face_filter.dart';

part 'face_detection_state.dart';

/// Cubit for managing face detection functionality
class FaceDetectionCubit extends Cubit<FaceDetectionState> {
  final MLMediaCubit _mlMediaCubit;
  late FaceDetector _faceDetector;
  bool _isInitialized = false;
  StreamSubscription<CameraImage>? _cameraStreamSubscription;
  StreamSubscription<MLMediaState>? _mlMediaStateSubscription;
  Timer? _processingTimer;
  bool _isProcessingFrame = false;
  int _frameCount = 0;

  FaceDetectionCubit({required MLMediaCubit mlMediaCubit})
    : _mlMediaCubit = mlMediaCubit,
      super(const FaceDetectionState()) {
    _initializeServices();
    _listenToMLMediaChanges();
  }

  /// Initialize ML services
  Future<void> _initializeServices() async {
    try {
      emit(state.copyWith(faceDetectionDataState: DataState.loading()));

      // Initialize FaceDetector with all features enabled
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true, // Enable facial landmarks
          enableContours: true, // Enable face contours
          enableClassification: true, // Enable smile/eyes open classification
          enableTracking: true, // Enable face tracking
          minFaceSize: 0.1, // Minimum face size (10% of image)
          performanceMode: FaceDetectorMode.accurate, // Use accurate mode
        ),
      );

      _isInitialized = true;
      emit(state.copyWith(faceDetectionDataState: DataState.initial()));
    } catch (e) {
      emit(
        state.copyWith(
          faceDetectionDataState: state.faceDetectionDataState.toFailure(
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

      // Handle camera switching in live mode
      // Check if camera switched by comparing timestamps and live camera state
      if (mlMediaState.mode == MLMediaMode.live &&
          mlMediaState.isLiveCameraActive &&
          state.isLiveCameraActive &&
          mlMediaState.timestamp != state.timestamp &&
          mlMediaState.timestamp != null) {
        // Camera was switched, clear current faces and restart processing
        _handleCameraSwitch();
      }

      // Check if image was cleared (went from having an image to null)
      final imageCleared = state.image != null && mlMediaState.image == null;

      // Update our state to reflect ML media state
      emit(
        state.copyWith(
          mode:
              mlMediaState.mode == MLMediaMode.live
                  ? FaceDetectionMode.live
                  : FaceDetectionMode.static,
          isLiveCameraActive: mlMediaState.isLiveCameraActive,
          image: () => mlMediaState.image,
          faces: imageCleared ? () => null : null,
          timestamp: () => mlMediaState.timestamp,
          faceDetectionDataState:
              imageCleared ? DataState.initial() : state.faceDetectionDataState,
        ),
      );
    });
  }

  /// Capture image from camera (delegates to ML media cubit)
  Future<void> captureImage() async {
    if (!_isInitialized) {
      emit(
        state.copyWith(
          faceDetectionDataState: state.faceDetectionDataState.toFailure(
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
          faceDetectionDataState: state.faceDetectionDataState.toFailure(
            error: Exception('Services not initialized'),
          ),
        ),
      );
      return;
    }

    await _mlMediaCubit.pickImageFromGallery();
  }

  /// Process the captured/selected image to detect faces
  Future<void> processImage(File imageFile) async {
    if (!_isInitialized) {
      emit(
        state.copyWith(
          faceDetectionDataState: state.faceDetectionDataState.toFailure(
            error: Exception('Services not initialized'),
          ),
        ),
      );
      return;
    }

    try {
      emit(
        state.copyWith(
          faceDetectionDataState: state.faceDetectionDataState.toLoading(),
        ),
      );

      // Create InputImage from file
      final inputImage = InputImage.fromFile(imageFile);

      // Detect faces using ML Kit
      final faces = await _faceDetector.processImage(inputImage);

      emit(
        state.copyWith(
          image: () => imageFile,
          faces: () => faces,
          timestamp: () => DateTime.now(),
          faceDetectionDataState: state.faceDetectionDataState.toLoaded(
            data: faces,
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          faceDetectionDataState: state.faceDetectionDataState.toFailure(
            error: e,
          ),
          previousState: FaceDetectionState(image: imageFile),
        ),
      );
    }
  }

  /// Clear current results and go back to initial state
  void clearResults() {
    _mlMediaCubit.clearResults();
    // Let _listenToMLMediaChanges handle the state update
  }

  /// Switch between static and live camera modes (delegates to ML media cubit)
  Future<void> switchMode(FaceDetectionMode mode) async {
    final mlMediaMode =
        mode == FaceDetectionMode.live ? MLMediaMode.live : MLMediaMode.static;

    await _mlMediaCubit.switchMode(mlMediaMode);
  }

  /// Toggle contours display
  void toggleContours() {
    emit(state.copyWith(showContours: !state.showContours));
  }

  /// Toggle labels display (face boxes and classification text)
  void toggleLabels() {
    emit(state.copyWith(showLabels: !state.showLabels));
  }

  /// Select a face filter
  void selectFilter(FaceFilterType filterType) {
    emit(state.copyWith(selectedFilter: filterType));
  }

  /// Start live camera processing
  void _startLiveCameraProcessing() async {
    if (!_isInitialized) return;

    try {
      // Start image stream and process frames
      final imageStream = _mlMediaCubit.getCameraStream();

      _cameraStreamSubscription = imageStream.listen(
        (cameraImage) {
          _processLiveCameraFrame(cameraImage);
        },
        onError: (error) {
          // Handle stream errors silently or emit error state if needed
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          faceDetectionDataState: state.faceDetectionDataState.toFailure(
            error: e,
          ),
        ),
      );
    }
  }

  /// Stop live camera processing
  void _stopLiveCameraProcessing() async {
    try {
      _processingTimer?.cancel();
      _processingTimer = null;

      await _cameraStreamSubscription?.cancel();
      _cameraStreamSubscription = null;

      emit(state.copyWith(isLiveCameraActive: false, liveCameraFaces: []));
    } catch (e) {
      emit(
        state.copyWith(
          faceDetectionDataState: state.faceDetectionDataState.toFailure(
            error: e,
          ),
        ),
      );
    }
  }

  /// Handle camera switch in live mode
  void _handleCameraSwitch() async {
    try {
      // Clear current faces immediately
      emit(state.copyWith(liveCameraFaces: []));

      // Cancel current processing
      _processingTimer?.cancel();
      _processingTimer = null;
      _isProcessingFrame = false;
      _frameCount = 0; // Reset frame counter

      // Cancel current stream
      await _cameraStreamSubscription?.cancel();
      _cameraStreamSubscription = null;

      // Restart camera stream with new camera
      if (state.isLiveCameraActive) {
        final imageStream = _mlMediaCubit.getCameraStream();
        _cameraStreamSubscription = imageStream.listen(
          (cameraImage) {
            _processLiveCameraFrame(cameraImage);
          },
          onError: (error) {
            // Handle stream errors silently or emit error state if needed
          },
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          faceDetectionDataState: state.faceDetectionDataState.toFailure(
            error: Exception('Failed to handle camera switch: $e'),
          ),
        ),
      );
    }
  }

  /// Switch camera (front/back) during live mode (delegates to ML media cubit)
  Future<void> switchCamera() async {
    if (!state.isLiveCameraActive) return;

    try {
      // Simply delegate to ML media cubit
      // The _listenToMLMediaChanges will handle clearing faces and restarting stream
      await _mlMediaCubit.switchCamera();
    } catch (e) {
      emit(
        state.copyWith(
          faceDetectionDataState: state.faceDetectionDataState.toFailure(
            error: Exception('Failed to switch camera: $e'),
          ),
        ),
      );
    }
  }

  /// Process camera frame for real-time face detection
  void _processLiveCameraFrame(CameraImage cameraImage) {
    _frameCount++;

    // Skip if already processing a frame
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

    // Process frame asynchronously
    _processFrameImmediate(cameraImage).whenComplete(() {
      _isProcessingFrame = false;
    });
  }

  /// Process frame immediately without Timer delay
  Future<void> _processFrameImmediate(CameraImage cameraImage) async {
    try {
      // Create InputImage from camera image
      final inputImage = _inputImageFromCameraImage(cameraImage);
      if (inputImage == null) return;

      // Detect faces using ML Kit
      final faces = await _faceDetector.processImage(inputImage);

      // Update state with new faces only if camera is still active
      if (state.isLiveCameraActive) {
        emit(
          state.copyWith(
            liveCameraFaces: faces,
            timestamp: () => DateTime.now(),
          ),
        );
      }
    } catch (e) {
      // Continue processing next frames - don't emit error state for individual frame failures
    }
  }

  /// Convert CameraImage to InputImage for ML Kit processing
  InputImage? _inputImageFromCameraImage(CameraImage cameraImage) {
    try {
      final camera = _mlMediaCubit.cameraController?.description;
      if (camera == null) return null;

      // Get image rotation using the official ML Kit approach (same as barcode scanning)
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
            orientations[_mlMediaCubit
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

      if (rotation == null) return null;

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

      // Create InputImage with proper metadata
      return InputImage.fromBytes(
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
    } catch (e) {
      return null;
    }
  }

  /// Retry the last operation if there was an error
  void retry() {
    final currentState = state;
    if (currentState.faceDetectionDataState.isFailure) {
      if (currentState.previousState != null) {
        emit(currentState.previousState!);
      } else {
        emit(state.copyWith(faceDetectionDataState: DataState.initial()));
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

  /// Get current faces if available
  List<Face>? get currentFaces {
    final currentState = state;
    if (currentState.faces != null) {
      return currentState.faces;
    }
    return null;
  }

  /// Get camera controller for live camera preview (delegates to ML media cubit)
  CameraController? get cameraController {
    return _mlMediaCubit.cameraController;
  }

  @override
  Future<void> close() async {
    // Clean up live camera resources
    _processingTimer?.cancel();
    await _cameraStreamSubscription?.cancel();
    await _mlMediaStateSubscription?.cancel();

    // Clean up ML Kit resources
    if (_isInitialized) {
      await _faceDetector.close();
    }

    return super.close();
  }
}
