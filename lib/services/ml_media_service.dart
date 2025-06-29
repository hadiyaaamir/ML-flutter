import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'image_picker_service.dart';
import 'camera_service.dart';

/// Unified service for ML media operations
/// Combines image picking and camera services for ML workflows
class MLMediaService {
  static final MLMediaService _instance = MLMediaService._internal();
  factory MLMediaService() => _instance;
  MLMediaService._internal();

  final ImagePickerService _imagePickerService = ImagePickerService();
  final CameraService _cameraService = CameraService();

  /// Initialize all ML media services
  Future<void> initialize() async {
    await _cameraService.initialize();
  }

  // Image Picker Service Methods

  /// Pick single image from gallery for ML processing
  Future<File?> pickImageFromGallery({
    ImageQuality quality = ImageQuality.high,
    int? maxWidth,
    int? maxHeight,
  }) async {
    return await _imagePickerService.pickFromGallery(
      quality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  /// Pick multiple images from gallery for batch ML processing
  Future<List<File>> pickMultipleImagesFromGallery({
    ImageQuality quality = ImageQuality.high,
    int? maxWidth,
    int? maxHeight,
  }) async {
    return await _imagePickerService.pickMultipleFromGallery(
      quality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  /// Capture image from camera for ML processing
  Future<File?> captureImageFromCamera({
    ImageQuality quality = ImageQuality.high,
    int? maxWidth,
    int? maxHeight,
    CameraDevice preferredCamera = CameraDevice.rear,
  }) async {
    return await _imagePickerService.captureFromCamera(
      quality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      preferredCamera: preferredCamera,
    );
  }

  /// Show image source selection dialog
  Future<File?> showImageSourceDialog(
    BuildContext context, {
    ImageQuality quality = ImageQuality.high,
    int? maxWidth,
    int? maxHeight,
  }) async {
    return await _imagePickerService.showImageSourceActionSheet(
      context,
      quality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  // Camera Service Methods

  /// Start live camera for real-time ML processing
  Future<void> startLiveCamera({
    CameraLensDirection lensDirection = CameraLensDirection.back,
    ResolutionPreset resolution = ResolutionPreset.high,
  }) async {
    await _cameraService.startCamera(
      lensDirection: lensDirection,
      resolution: resolution,
      enableAudio: false, // ML doesn't need audio
    );
  }

  /// Stop live camera
  Future<void> stopLiveCamera() async {
    await _cameraService.stopCamera();
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    await _cameraService.switchCamera();
  }

  /// Get live camera stream for real-time ML processing
  Stream<CameraImage> getCameraStream() {
    return _cameraService.startImageStream();
  }

  /// Stop camera stream
  Future<void> stopCameraStream() async {
    await _cameraService.stopImageStream();
  }

  /// Take picture from live camera
  Future<XFile> takePictureFromLiveCamera() async {
    return await _cameraService.takePicture();
  }

  /// Get camera controller for custom UI
  CameraController? get cameraController => _cameraService.controller;

  /// Check if camera is initialized
  bool get isCameraInitialized => _cameraService.isInitialized;

  /// Get available cameras
  List<CameraDescription> get availableCameras => _cameraService.cameras;

  // ML-Specific Utility Methods

  /// Start camera with ML-optimized settings for object detection
  Future<void> startMLObjectDetection() async {
    await _cameraService.startCamera(
      lensDirection: CameraLensDirection.back,
      resolution: ResolutionPreset.medium, // Balanced for performance
      enableAudio: false,
    );

    // Set optimal settings for object detection
    await _cameraService.setFlashMode(FlashMode.off);
    await _cameraService.setFocusMode(FocusMode.auto);
    await _cameraService.setExposureMode(ExposureMode.auto);
  }

  /// Start camera with ML-optimized settings for face detection
  Future<void> startMLFaceDetection() async {
    await _cameraService.startCamera(
      lensDirection: CameraLensDirection.front,
      resolution: ResolutionPreset.medium,
      enableAudio: false,
    );

    // Set optimal settings for face detection
    await _cameraService.setFlashMode(FlashMode.off);
    await _cameraService.setFocusMode(FocusMode.auto);
    await _cameraService.setExposureMode(ExposureMode.auto);
  }

  /// Start camera with high quality settings for detailed ML analysis
  Future<void> startMLHighQualityAnalysis() async {
    await _cameraService.startCamera(
      lensDirection: CameraLensDirection.back,
      resolution: ResolutionPreset.veryHigh,
      enableAudio: false,
    );
  }

  /// Process image batch for ML
  /// Returns processed file paths
  Future<List<String>> processBatchImages(
    List<File> images, {
    required Future<String> Function(File image) processor,
  }) async {
    final List<String> processedPaths = [];

    for (final image in images) {
      try {
        final processedPath = await processor(image);
        processedPaths.add(processedPath);
      } catch (e) {
        debugPrint('Error processing image ${image.path}: $e');
      }
    }

    return processedPaths;
  }

  /// Create ML-optimized image picker configuration
  static const MLImageConfig mlImageConfig = MLImageConfig(
    quality: ImageQuality.high,
    maxWidth: 1024,
    maxHeight: 1024,
  );

  /// Create ML-optimized batch processing configuration
  static const MLImageConfig mlBatchConfig = MLImageConfig(
    quality: ImageQuality.medium,
    maxWidth: 512,
    maxHeight: 512,
  );

  /// Dispose all services
  Future<void> dispose() async {
    await _cameraService.dispose();
  }
}

/// Configuration class for ML image processing
class MLImageConfig {
  final ImageQuality quality;
  final int? maxWidth;
  final int? maxHeight;

  const MLImageConfig({required this.quality, this.maxWidth, this.maxHeight});
}

/// ML-specific camera presets
enum MLCameraPreset {
  objectDetection,
  faceDetection,
  textRecognition,
  highQualityAnalysis,
  realTimeProcessing,
}

/// Extension to convert ML presets to camera configurations
extension MLCameraPresetExtension on MLCameraPreset {
  CameraConfig get config {
    switch (this) {
      case MLCameraPreset.objectDetection:
        return CameraConfig.mlObjectDetection;
      case MLCameraPreset.faceDetection:
        return CameraConfig.mlFaceDetection;
      case MLCameraPreset.textRecognition:
        return const CameraConfig(
          lensDirection: CameraLensDirection.back,
          resolution: ResolutionPreset.high,
          enableAudio: false,
          flashMode: FlashMode.auto,
          focusMode: FocusMode.auto,
        );
      case MLCameraPreset.highQualityAnalysis:
        return CameraConfig.highQuality;
      case MLCameraPreset.realTimeProcessing:
        return const CameraConfig(
          lensDirection: CameraLensDirection.back,
          resolution: ResolutionPreset.low,
          enableAudio: false,
          flashMode: FlashMode.off,
          focusMode: FocusMode.locked,
        );
    }
  }
}
