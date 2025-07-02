import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling live camera footage and streaming
/// Provides real-time camera access for ML processing
class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isInitialized = false;
  StreamController<CameraImage>? _imageStreamController;

  /// Get available cameras
  List<CameraDescription> get cameras => _cameras;

  /// Get current camera controller
  CameraController? get controller => _controller;

  /// Check if camera is initialized
  bool get isInitialized => _isInitialized;

  /// Get back camera
  CameraDescription? get backCamera {
    return _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse:
          () =>
              _cameras.isNotEmpty
                  ? _cameras.first
                  : throw Exception('No cameras available'),
    );
  }

  /// Get front camera
  CameraDescription? get frontCamera {
    try {
      return _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
    } catch (e) {
      debugPrint('Front camera not available: $e');
      return null; // Front camera might not be available
    }
  }

  /// Check if front camera is available
  bool get hasFrontCamera {
    return _cameras.any(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
  }

  /// Check if back camera is available
  bool get hasBackCamera {
    return _cameras.any(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );
  }

  /// Initialize camera service
  Future<void> initialize() async {
    try {
      // Check camera permission
      if (!await _checkCameraPermission()) {
        throw Exception('Camera permission denied');
      }

      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception('No cameras available on this device');
      }

      debugPrint('Found ${_cameras.length} cameras');
      for (var camera in _cameras) {
        debugPrint('Camera: ${camera.name} - ${camera.lensDirection}');
      }
    } catch (e) {
      debugPrint('Error initializing camera service: $e');
      rethrow;
    }
  }

  /// Start camera with specified configuration
  Future<void> startCamera({
    CameraLensDirection lensDirection = CameraLensDirection.back,
    ResolutionPreset resolution = ResolutionPreset.high,
    bool enableAudio = false,
  }) async {
    try {
      // Stop current camera if running
      await stopCamera();

      // Find camera with specified lens direction
      final camera = _cameras.firstWhere(
        (cam) => cam.lensDirection == lensDirection,
        orElse: () => _cameras.first,
      );

      // Initialize controller
      _controller = CameraController(
        camera,
        resolution,
        enableAudio: enableAudio,
        imageFormatGroup:
            Platform.isAndroid
                ? ImageFormatGroup
                    .nv21 // for Android ML Kit
                : ImageFormatGroup.bgra8888, // for iOS ML Kit
      );

      await _controller!.initialize();
      _isInitialized = true;

      debugPrint('Camera started: ${camera.name}');
    } catch (e) {
      debugPrint('Error starting camera: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Stop camera and dispose controller
  Future<void> stopCamera() async {
    try {
      await stopImageStream();

      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }

      _isInitialized = false;
      debugPrint('Camera stopped');
    } catch (e) {
      debugPrint('Error stopping camera: $e');
    }
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }

    try {
      final currentLensDirection = _controller!.description.lensDirection;
      final newLensDirection =
          currentLensDirection == CameraLensDirection.back
              ? CameraLensDirection.front
              : CameraLensDirection.back;

      // Check if the target camera is available
      final targetCamera =
          _cameras
              .where((cam) => cam.lensDirection == newLensDirection)
              .firstOrNull;

      if (targetCamera == null) {
        throw Exception(
          newLensDirection == CameraLensDirection.front
              ? 'Front camera not available on this device'
              : 'Back camera not available on this device',
        );
      }

      final wasStreamingActive = _imageStreamController != null;
      final currentResolution = _controller!.resolutionPreset;

      // Stop current camera
      await stopCamera();

      // Add a small delay to ensure cleanup is complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Start with new lens direction
      await startCamera(
        lensDirection: newLensDirection,
        resolution: currentResolution,
      );

      // Restart image stream if it was active
      if (wasStreamingActive) {
        startImageStream();
      }
    } catch (e) {
      debugPrint('Error switching camera: $e');
      rethrow;
    }
  }

  /// Start image stream for real-time processing
  /// Returns stream of CameraImage for ML processing
  Stream<CameraImage> startImageStream() {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }

    if (_imageStreamController != null) {
      return _imageStreamController!.stream;
    }

    _imageStreamController = StreamController<CameraImage>.broadcast();

    _controller!.startImageStream((CameraImage image) {
      if (!_imageStreamController!.isClosed) {
        _imageStreamController!.add(image);
      }
    });

    debugPrint('Image stream started');
    return _imageStreamController!.stream;
  }

  /// Stop image stream
  Future<void> stopImageStream() async {
    try {
      if (_controller != null && _controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }

      if (_imageStreamController != null) {
        await _imageStreamController!.close();
        _imageStreamController = null;
      }

      debugPrint('Image stream stopped');
    } catch (e) {
      debugPrint('Error stopping image stream: $e');
    }
  }

  /// Take a picture
  Future<XFile> takePicture() async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }

    try {
      final image = await _controller!.takePicture();
      debugPrint('Picture taken: ${image.path}');
      return image;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      rethrow;
    }
  }

  /// Set flash mode
  Future<void> setFlashMode(FlashMode flashMode) async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }

    try {
      await _controller!.setFlashMode(flashMode);
      debugPrint('Flash mode set to: $flashMode');
    } catch (e) {
      debugPrint('Error setting flash mode: $e');
      rethrow;
    }
  }

  /// Set exposure mode
  Future<void> setExposureMode(ExposureMode exposureMode) async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }

    try {
      await _controller!.setExposureMode(exposureMode);
      debugPrint('Exposure mode set to: $exposureMode');
    } catch (e) {
      debugPrint('Error setting exposure mode: $e');
      rethrow;
    }
  }

  /// Set focus mode
  Future<void> setFocusMode(FocusMode focusMode) async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }

    try {
      await _controller!.setFocusMode(focusMode);
      debugPrint('Focus mode set to: $focusMode');
    } catch (e) {
      debugPrint('Error setting focus mode: $e');
      rethrow;
    }
  }

  /// Set focus point
  Future<void> setFocusPoint(Offset point) async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }

    try {
      await _controller!.setFocusPoint(point);
      debugPrint('Focus point set to: $point');
    } catch (e) {
      debugPrint('Error setting focus point: $e');
      rethrow;
    }
  }

  /// Check camera permission
  Future<bool> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    return result.isGranted;
  }

  /// Dispose service and cleanup resources
  Future<void> dispose() async {
    await stopCamera();
    debugPrint('Camera service disposed');
  }
}

/// Camera configuration for different use cases
class CameraConfig {
  final CameraLensDirection lensDirection;
  final ResolutionPreset resolution;
  final bool enableAudio;
  final FlashMode flashMode;
  final FocusMode focusMode;
  final ExposureMode exposureMode;

  const CameraConfig({
    this.lensDirection = CameraLensDirection.back,
    this.resolution = ResolutionPreset.high,
    this.enableAudio = false,
    this.flashMode = FlashMode.auto,
    this.focusMode = FocusMode.auto,
    this.exposureMode = ExposureMode.auto,
  });

  /// Configuration for ML object detection
  static const CameraConfig mlObjectDetection = CameraConfig(
    lensDirection: CameraLensDirection.back,
    resolution: ResolutionPreset.medium,
    enableAudio: false,
    flashMode: FlashMode.off,
    focusMode: FocusMode.auto,
    exposureMode: ExposureMode.auto,
  );

  /// Configuration for face detection
  static const CameraConfig mlFaceDetection = CameraConfig(
    lensDirection: CameraLensDirection.front,
    resolution: ResolutionPreset.medium,
    enableAudio: false,
    flashMode: FlashMode.off,
    focusMode: FocusMode.auto,
    exposureMode: ExposureMode.auto,
  );

  /// Configuration for high quality capture
  static const CameraConfig highQuality = CameraConfig(
    lensDirection: CameraLensDirection.back,
    resolution: ResolutionPreset.veryHigh,
    enableAudio: false,
    flashMode: FlashMode.auto,
    focusMode: FocusMode.auto,
    exposureMode: ExposureMode.auto,
  );
}
