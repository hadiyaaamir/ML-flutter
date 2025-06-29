import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling image picking from gallery and camera
/// Provides clean, reusable methods for ML image processing
class ImagePickerService {
  static final ImagePickerService _instance = ImagePickerService._internal();
  factory ImagePickerService() => _instance;
  ImagePickerService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  /// Returns File if successful, null if cancelled or error
  Future<File?> pickFromGallery({
    ImageQuality quality = ImageQuality.high,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      // Check permission
      if (!await _checkGalleryPermission()) {
        throw Exception('Gallery permission denied');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: _getQualityValue(quality),
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
      );

      return image != null ? File(image.path) : null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      rethrow;
    }
  }

  /// Pick multiple images from gallery
  /// Returns list of Files, empty list if cancelled or error
  Future<List<File>> pickMultipleFromGallery({
    ImageQuality quality = ImageQuality.high,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      // Check permission
      if (!await _checkGalleryPermission()) {
        throw Exception('Gallery permission denied');
      }

      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: _getQualityValue(quality),
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
      );

      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      debugPrint('Error picking multiple images from gallery: $e');
      return [];
    }
  }

  /// Capture image using camera
  /// Returns File if successful, null if cancelled or error
  Future<File?> captureFromCamera({
    ImageQuality quality = ImageQuality.high,
    int? maxWidth,
    int? maxHeight,
    CameraDevice preferredCamera = CameraDevice.rear,
  }) async {
    try {
      // Check permission
      if (!await _checkCameraPermission()) {
        throw Exception('Camera permission denied');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: _getQualityValue(quality),
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        preferredCameraDevice: preferredCamera,
      );

      return image != null ? File(image.path) : null;
    } catch (e) {
      debugPrint('Error capturing image from camera: $e');
      rethrow;
    }
  }

  /// Show action sheet to choose between gallery and camera
  /// Returns File if successful, null if cancelled
  Future<File?> showImageSourceActionSheet(
    BuildContext context, {
    ImageQuality quality = ImageQuality.high,
    int? maxWidth,
    int? maxHeight,
  }) async {
    return showModalBottomSheet<File?>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final file = await pickFromGallery(
                    quality: quality,
                    maxWidth: maxWidth,
                    maxHeight: maxHeight,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop(file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final file = await captureFromCamera(
                    quality: quality,
                    maxWidth: maxWidth,
                    maxHeight: maxHeight,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop(file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Check camera permission
  Future<bool> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    return result.isGranted;
  }

  /// Check gallery permission
  Future<bool> _checkGalleryPermission() async {
    try {
      if (Platform.isAndroid) {
        // Try different permission strategies for Android

        // First, try the photos permission (for Android 13+)
        var photosStatus = await Permission.photos.status;
        debugPrint('Photos permission status: $photosStatus');

        if (photosStatus.isGranted) {
          return true;
        }

        if (photosStatus.isDenied) {
          final photosResult = await Permission.photos.request();
          debugPrint('Photos permission request result: $photosResult');
          if (photosResult.isGranted) {
            return true;
          }
        }

        // If photos permission doesn't work, try storage permission (for older Android)
        var storageStatus = await Permission.storage.status;
        debugPrint('Storage permission status: $storageStatus');

        if (storageStatus.isGranted) {
          return true;
        }

        if (storageStatus.isDenied) {
          final storageResult = await Permission.storage.request();
          debugPrint('Storage permission request result: $storageResult');
          return storageResult.isGranted;
        }

        // If permanently denied, guide user to settings
        if (photosStatus.isPermanentlyDenied ||
            storageStatus.isPermanentlyDenied) {
          debugPrint('Permission permanently denied, opening app settings');
          await openAppSettings();
          return false;
        }

        return false;
      } else {
        // iOS
        final status = await Permission.photos.status;
        debugPrint('iOS Photos permission status: $status');

        if (status.isGranted) return true;

        if (status.isDenied) {
          final result = await Permission.photos.request();
          debugPrint('iOS Photos permission request result: $result');
          return result.isGranted;
        }

        if (status.isPermanentlyDenied) {
          debugPrint('iOS permission permanently denied, opening app settings');
          await openAppSettings();
          return false;
        }

        return false;
      }
    } catch (e) {
      debugPrint('Error checking gallery permission: $e');
      return false;
    }
  }

  /// Convert quality enum to integer value
  int _getQualityValue(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.low:
        return 25;
      case ImageQuality.medium:
        return 50;
      case ImageQuality.high:
        return 85;
      case ImageQuality.maximum:
        return 100;
    }
  }
}

/// Image quality options for ML processing
enum ImageQuality {
  low, // 25% - Good for quick processing
  medium, // 50% - Balanced quality/performance
  high, // 85% - High quality for detailed ML
  maximum, // 100% - Maximum quality
}
