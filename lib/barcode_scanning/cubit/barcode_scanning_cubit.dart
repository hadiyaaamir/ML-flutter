import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:ml_flutter/common/common.dart';
import 'package:ml_flutter/barcode_scanning/models/models.dart';
import 'package:ml_flutter/ml_media/ml_media.dart';

part 'barcode_scanning_state.dart';

/// Cubit for managing barcode scanning functionality
class BarcodeScanningCubit extends Cubit<BarcodeScanningState> {
  final MLMediaCubit _mlMediaCubit;
  late final BarcodeScanner _barcodeScanner;
  bool _isInitialized = false;
  StreamSubscription<CameraImage>? _cameraStreamSubscription;
  StreamSubscription<MLMediaState>? _mlMediaStateSubscription;
  Timer? _processingTimer;
  bool _isProcessingFrame = false;
  int _frameCount = 0;

  BarcodeScanningCubit({required MLMediaCubit mlMediaCubit})
    : _mlMediaCubit = mlMediaCubit,
      super(const BarcodeScanningState()) {
    _initializeServices();
    _listenToMLMediaChanges();
  }

  /// Initialize ML services and barcode scanner
  Future<void> _initializeServices() async {
    try {
      emit(state.copyWith(barcodeScanningDataState: DataState.loading()));

      // Initialize BarcodeScanner with optimized settings for real-time processing
      _barcodeScanner = BarcodeScanner(
        formats: [BarcodeFormat.all], // Scan all barcode formats
      );

      _isInitialized = true;
      emit(state.copyWith(barcodeScanningDataState: DataState.initial()));
    } catch (e) {
      emit(
        state.copyWith(
          barcodeScanningDataState: state.barcodeScanningDataState.toFailure(
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

      // Update our state to reflect ML media state
      emit(
        state.copyWith(
          mode:
              mlMediaState.mode == MLMediaMode.live
                  ? BarcodeScanningMode.live
                  : BarcodeScanningMode.static,
          isLiveCameraActive: mlMediaState.isLiveCameraActive,
          image: mlMediaState.image,
          barcodes: imageCleared ? () => null : null,
          timestamp: imageCleared ? () => null : null,
          barcodeScanningDataState:
              imageCleared
                  ? DataState.initial()
                  : state.barcodeScanningDataState,
        ),
      );
    });
  }

  /// Capture image from camera (delegates to ML media cubit)
  Future<void> captureImage() async {
    if (!_isInitialized) {
      emit(
        state.copyWith(
          barcodeScanningDataState: state.barcodeScanningDataState.toFailure(
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
          barcodeScanningDataState: state.barcodeScanningDataState.toFailure(
            error: Exception('Services not initialized'),
          ),
        ),
      );
      return;
    }

    await _mlMediaCubit.pickImageFromGallery();
  }

  /// Process the captured/selected image to detect barcodes
  Future<void> processImage(File imageFile) async {
    if (!_isInitialized) {
      emit(
        state.copyWith(
          barcodeScanningDataState: state.barcodeScanningDataState.toFailure(
            error: Exception('Services not initialized'),
          ),
        ),
      );
      return;
    }

    try {
      emit(
        state.copyWith(
          barcodeScanningDataState: state.barcodeScanningDataState.toLoading(),
        ),
      );

      // Create InputImage from file
      final inputImage = InputImage.fromFile(imageFile);

      // Process image with ML Kit
      final barcodes = await _barcodeScanner.processImage(inputImage);

      // Convert to our model
      final barcodeResults =
          barcodes
              .map((barcode) => BarcodeResult.fromBarcode(barcode))
              .toList();

      emit(
        state.copyWith(
          image: imageFile,
          barcodes: () => barcodeResults,
          timestamp: () => DateTime.now(),
          barcodeScanningDataState: state.barcodeScanningDataState.toLoaded(
            data: barcodeResults,
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          barcodeScanningDataState: state.barcodeScanningDataState.toFailure(
            error: e,
          ),
          previousState: BarcodeScanningState(image: imageFile),
        ),
      );
    }
  }

  /// Clear current results and go back to initial state
  void clearResults() {
    _mlMediaCubit.clearResults();
    emit(BarcodeScanningState(mode: state.mode));
  }

  /// Switch between static and live camera modes (delegates to ML media cubit)
  Future<void> switchMode(BarcodeScanningMode mode) async {
    final mlMediaMode =
        mode == BarcodeScanningMode.live
            ? MLMediaMode.live
            : MLMediaMode.static;

    await _mlMediaCubit.switchMode(mlMediaMode);
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
          barcodeScanningDataState: state.barcodeScanningDataState.toFailure(
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

      emit(state.copyWith(isLiveCameraActive: false, liveCameraBarcodes: []));
    } catch (e) {
      emit(
        state.copyWith(
          barcodeScanningDataState: state.barcodeScanningDataState.toFailure(
            error: e,
          ),
        ),
      );
    }
  }

  /// Switch camera (front/back) during live mode (delegates to ML media cubit)
  Future<void> switchCamera() async {
    if (!state.isLiveCameraActive) return;

    try {
      // Temporarily pause processing during camera switch
      _processingTimer?.cancel();
      _isProcessingFrame = false;

      // Stop current image stream
      await _cameraStreamSubscription?.cancel();
      _cameraStreamSubscription = null;

      // Switch camera using the ML media cubit
      await _mlMediaCubit.switchCamera();

      // Restart image stream if camera is still active
      if (state.isLiveCameraActive) {
        final imageStream = _mlMediaCubit.getCameraStream();
        _cameraStreamSubscription = imageStream.listen(_processLiveCameraFrame);
      }
    } catch (e) {
      emit(
        state.copyWith(
          barcodeScanningDataState: state.barcodeScanningDataState.toFailure(
            error: Exception('Failed to switch camera: $e'),
          ),
        ),
      );
    }
  }

  /// Process camera frame for real-time barcode detection
  void _processLiveCameraFrame(CameraImage cameraImage) {
    _frameCount++;

    // Skip if already processing a frame (ML Kit best practice)
    if (_isProcessingFrame) {
      return;
    }

    // Only process every 10th frame to throttle performance (faster than object detection)
    if (_frameCount % 10 != 0) {
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
      final barcodes = await _barcodeScanner.processImage(inputImage);

      // Convert to our model
      final barcodeResults =
          barcodes
              .map((barcode) => BarcodeResult.fromBarcode(barcode))
              .toList();

      // Update state with new barcodes only if camera is still active
      if (state.isLiveCameraActive) {
        emit(
          state.copyWith(
            liveCameraBarcodes: barcodeResults,
            timestamp: () => DateTime.now(),
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
      final camera = _mlMediaCubit.cameraController?.description;
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
    if (currentState.barcodeScanningDataState.isFailure) {
      if (currentState.previousState != null) {
        emit(currentState.previousState!);
      } else {
        emit(state.copyWith(barcodeScanningDataState: DataState.initial()));
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

  /// Get current barcodes if available
  List<BarcodeResult>? get currentBarcodes {
    final currentState = state;
    if (currentState.barcodes != null) {
      return currentState.barcodes;
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
    await _barcodeScanner.close();

    return super.close();
  }
}
