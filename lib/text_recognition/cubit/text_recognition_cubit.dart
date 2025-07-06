import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ml_flutter/common/common.dart';
import 'package:ml_flutter/text_recognition/models/text_recognition_result.dart';
import 'package:ml_flutter/ml_media/ml_media.dart';

part 'text_recognition_state.dart';

/// Cubit for managing text recognition functionality
class TextRecognitionCubit extends Cubit<TextRecognitionState> {
  final MLMediaCubit _mlMediaCubit;
  late final TextRecognizer _staticImageRecognizer;
  late final TextRecognizer _liveStreamRecognizer;
  bool _isInitialized = false;
  StreamSubscription<CameraImage>? _cameraStreamSubscription;
  StreamSubscription<MLMediaState>? _mlMediaStateSubscription;
  Timer? _processingTimer;
  bool _isProcessingFrame = false;
  int _frameCount = 0;

  TextRecognitionCubit({required MLMediaCubit mlMediaCubit})
    : _mlMediaCubit = mlMediaCubit,
      super(const TextRecognitionState()) {
    _initializeServices();
    _listenToMLMediaChanges();
  }

  /// Initialize ML services and text recognizer
  Future<void> _initializeServices() async {
    try {
      emit(state.copyWith(textRecognitionDataState: DataState.loading()));

      // Initialize TextRecognizer for static images
      _staticImageRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      // Initialize TextRecognizer for live stream
      _liveStreamRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      _isInitialized = true;
      emit(state.copyWith(textRecognitionDataState: DataState.initial()));
    } catch (e, stackTrace) {
      emit(
        state.copyWith(
          textRecognitionDataState: state.textRecognitionDataState.toFailure(
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
              ? TextRecognitionMode.live
              : TextRecognitionMode.static) !=
          state.mode;

      // Update our state to reflect ML media state
      final newState = state.copyWith(
        mode:
            mlMediaState.mode == MLMediaMode.live
                ? TextRecognitionMode.live
                : TextRecognitionMode.static,
        isLiveCameraActive: mlMediaState.isLiveCameraActive,
        image: () => mlMediaState.image,
        // Clear recognized text and results when:
        // 1. Image was cleared, OR
        // 2. Mode changed (switching between static and live)
        recognizedText: (imageCleared || modeChanged) ? () => null : null,
        timestamp: (imageCleared || modeChanged) ? () => null : null,
        textRecognitionDataState:
            (imageCleared || modeChanged)
                ? DataState.initial()
                : state.textRecognitionDataState,
      );

      emit(newState);
    });
  }

  /// Capture image from camera (delegates to ML media cubit)
  Future<void> captureImage() async {
    if (!_isInitialized) {
      emit(
        state.copyWith(
          textRecognitionDataState: state.textRecognitionDataState.toFailure(
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
          textRecognitionDataState: state.textRecognitionDataState.toFailure(
            error: Exception('Services not initialized'),
          ),
        ),
      );
      return;
    }

    await _mlMediaCubit.pickImageFromGallery();
  }

  /// Process the captured/selected image to recognize text
  Future<void> processImage(File imageFile) async {
    if (!_isInitialized) {
      emit(
        state.copyWith(
          textRecognitionDataState: state.textRecognitionDataState.toFailure(
            error: Exception('Services not initialized'),
          ),
        ),
      );
      return;
    }

    try {
      emit(
        state.copyWith(
          textRecognitionDataState: state.textRecognitionDataState.toLoading(),
        ),
      );

      // Start minimum loading time and actual processing simultaneously
      final minimumLoadingTime = Future.delayed(
        const Duration(milliseconds: 500),
      );

      // Create InputImage from file
      final inputImage = InputImage.fromFile(imageFile);

      // Process image with ML Kit with timeout
      final recognizedTextFuture = _staticImageRecognizer
          .processImage(inputImage)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Text recognition timed out after 30 seconds');
            },
          );

      // Wait for both minimum loading time and processing to complete
      final results = await Future.wait([
        minimumLoadingTime,
        recognizedTextFuture,
      ]);

      final recognizedText = results[1] as RecognizedText;

      // Convert to our model - group text by blocks for better organization
      final textResults = <TextRecognitionResult>[];

      for (final block in recognizedText.blocks) {
        // Create a result for each text block
        final blockResult = TextRecognitionResult(
          text: block.text,
          boundingBox: block.boundingBox,
          confidence: _calculateBlockConfidence(block),
          textBlocks: [block],
        );
        textResults.add(blockResult);
      }

      // If no blocks, create a single result with all text
      if (textResults.isEmpty && recognizedText.text.isNotEmpty) {
        final overallResult = TextRecognitionResult.fromRecognizedText(
          recognizedText,
        );
        textResults.add(overallResult);
      }

      emit(
        state.copyWith(
          image: () => imageFile,
          recognizedText: () => textResults,
          timestamp: () => DateTime.now(),
          textRecognitionDataState: state.textRecognitionDataState.toLoaded(
            data: textResults,
          ),
        ),
      );
    } catch (e, stackTrace) {
      emit(
        state.copyWith(
          textRecognitionDataState: state.textRecognitionDataState.toFailure(
            error: e,
          ),
          previousState: TextRecognitionState(image: imageFile),
        ),
      );
    }
  }

  /// Calculate confidence for a text block
  double _calculateBlockConfidence(TextBlock block) {
    double totalConfidence = 0.0;
    int elementCount = 0;

    for (final line in block.lines) {
      for (final element in line.elements) {
        totalConfidence += element.confidence ?? 0.0;
        elementCount++;
      }
    }

    return elementCount > 0 ? totalConfidence / elementCount : 0.0;
  }

  /// Clear current results and go back to initial state
  void clearResults() {
    _mlMediaCubit.clearResults();
    // Don't emit a fresh state here - let _listenToMLMediaChanges handle it
    // to avoid race conditions with the MLMediaCubit state update
  }

  /// Switch between static and live camera modes (delegates to ML media cubit)
  Future<void> switchMode(TextRecognitionMode mode) async {
    final mlMediaMode =
        mode == TextRecognitionMode.live
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

      // Process every 15th frame for text recognition (less frequent than object detection)
      final processingInterval = 15;

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
        recognizedText: () => null,
        timestamp: () => null,
        textRecognitionDataState: DataState.initial(),
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
      final recognizedText = await _liveStreamRecognizer
          .processImage(inputImage)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              return RecognizedText(text: '', blocks: []);
            },
          );

      // Convert to our model - group text by blocks
      final textResults = <TextRecognitionResult>[];

      for (final block in recognizedText.blocks) {
        final blockResult = TextRecognitionResult(
          text: block.text,
          boundingBox: block.boundingBox,
          confidence: _calculateBlockConfidence(block),
          textBlocks: [block],
        );
        textResults.add(blockResult);
      }

      if (state.isLiveCameraActive) {
        emit(
          state.copyWith(
            recognizedText: () => textResults,
            timestamp: () => DateTime.now(),
            textRecognitionDataState: state.textRecognitionDataState.toLoaded(
              data: textResults,
            ),
          ),
        );
      }
    } catch (e) {
      if (state.isLiveCameraActive) {
        emit(
          state.copyWith(
            textRecognitionDataState: state.textRecognitionDataState.toFailure(
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
    if (currentState.textRecognitionDataState.isFailure) {
      if (currentState.previousState != null) {
        emit(currentState.previousState!);
      } else {
        emit(state.copyWith(textRecognitionDataState: DataState.initial()));
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

  /// Get current recognized text if available
  List<TextRecognitionResult>? get currentRecognizedText {
    final currentState = state;
    if (currentState.recognizedText != null) {
      return currentState.recognizedText;
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

    // Dispose text recognizers
    _staticImageRecognizer.close();
    _liveStreamRecognizer.close();

    return super.close();
  }
}

/// Platform-specific orientation mappings for camera image processing
const Map<int, int> orientations = {0: 0, 90: 90, 180: 180, 270: 270};
