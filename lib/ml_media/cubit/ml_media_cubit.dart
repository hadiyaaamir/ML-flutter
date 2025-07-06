import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ml_flutter/services/services.dart';
import 'package:ml_flutter/common/common.dart';
import 'ml_media_state.dart';

/// Cubit for managing ML media operations (image selection, camera, etc.)
/// This is a reusable component for any ML feature that needs media input
class MLMediaCubit extends Cubit<MLMediaState> {
  final MLMediaService _mlMediaService;
  StreamSubscription<CameraImage>? _cameraStreamSubscription;
  bool _isInitialized = false;

  MLMediaCubit({required MLMediaService mlMediaService})
    : _mlMediaService = mlMediaService,
      super(const MLMediaState()) {
    _initializeServices();
  }

  /// Initialize ML media services
  Future<void> _initializeServices() async {
    try {
      emit(state.copyWith(mlMediaDataState: DataState.loading()));
      await _mlMediaService.initialize();
      _isInitialized = true;
      emit(state.copyWith(mlMediaDataState: DataState.initial()));
    } catch (e) {
      emit(
        state.copyWith(
          mlMediaDataState: state.mlMediaDataState.toFailure(error: e),
        ),
      );
    }
  }

  /// Capture image from camera
  Future<void> captureImage() async {
    if (!_isInitialized) {
      emit(
        state.copyWith(
          mlMediaDataState: state.mlMediaDataState.toFailure(
            error: Exception('Services not initialized'),
          ),
        ),
      );
      return;
    }

    try {
      emit(state.copyWith(mlMediaDataState: DataState.loading()));

      final image = await _mlMediaService.captureImageFromCamera();

      if (image != null) {
        emit(
          state.copyWith(
            image: () => image,
            timestamp: () => DateTime.now(),
            mlMediaDataState: DataState.loaded(data: image),
          ),
        );
      } else {
        emit(
          state.copyWith(
            mlMediaDataState: state.mlMediaDataState.toFailure(
              error: Exception('Failed to capture image'),
            ),
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          mlMediaDataState: state.mlMediaDataState.toFailure(error: e),
        ),
      );
    }
  }

  /// Pick image from gallery
  Future<void> pickImageFromGallery() async {
    if (!_isInitialized) {
      emit(
        state.copyWith(
          mlMediaDataState: state.mlMediaDataState.toFailure(
            error: Exception('Services not initialized'),
          ),
        ),
      );
      return;
    }

    try {
      emit(state.copyWith(mlMediaDataState: DataState.loading()));

      final image = await _mlMediaService.pickImageFromGallery();

      if (image != null) {
        emit(
          state.copyWith(
            image: () => image,
            timestamp: () => DateTime.now(),
            mlMediaDataState: DataState.loaded(data: image),
          ),
        );
      } else {
        emit(
          state.copyWith(
            mlMediaDataState: state.mlMediaDataState.toFailure(
              error: Exception('No image selected'),
            ),
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          mlMediaDataState: state.mlMediaDataState.toFailure(error: e),
        ),
      );
    }
  }

  /// Switch between static and live camera modes
  Future<void> switchMode(MLMediaMode mode) async {
    if (state.mode == mode) return;

    try {
      if (mode == MLMediaMode.live) {
        await startLiveCamera();
      } else {
        await stopLiveCamera();
        emit(
          state.copyWith(
            mode: MLMediaMode.static,
            isLiveCameraActive: false,
            image: () => null, // Clear image when switching to static mode
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          mlMediaDataState: state.mlMediaDataState.toFailure(error: e),
        ),
      );
    }
  }

  /// Start live camera
  Future<void> startLiveCamera() async {
    if (!_isInitialized) {
      emit(
        state.copyWith(
          mlMediaDataState: state.mlMediaDataState.toFailure(
            error: Exception('Services not initialized'),
          ),
        ),
      );
      return;
    }

    try {
      emit(
        state.copyWith(
          mlMediaDataState: DataState.loading(),
          mode: MLMediaMode.live,
          image: () => null, // Clear image when switching to live mode
        ),
      );

      // Start ML-optimized camera
      await _mlMediaService.startMLObjectDetection();

      emit(
        state.copyWith(
          mode: MLMediaMode.live,
          isLiveCameraActive: true,
          mlMediaDataState: DataState.loaded(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          mlMediaDataState: state.mlMediaDataState.toFailure(error: e),
        ),
      );
    }
  }

  /// Stop live camera
  Future<void> stopLiveCamera() async {
    try {
      await _cameraStreamSubscription?.cancel();
      _cameraStreamSubscription = null;

      await _mlMediaService.stopLiveCamera();

      emit(state.copyWith(mode: MLMediaMode.static, isLiveCameraActive: false));
    } catch (e) {
      emit(
        state.copyWith(
          mlMediaDataState: state.mlMediaDataState.toFailure(error: e),
        ),
      );
    }
  }

  /// Switch camera (front/back) during live mode
  Future<void> switchCamera() async {
    if (!state.isLiveCameraActive) return;

    try {
      // Emit loading state to show camera is switching
      emit(state.copyWith(mlMediaDataState: DataState.loading()));

      await _cameraStreamSubscription?.cancel();
      _cameraStreamSubscription = null;

      await _mlMediaService.switchCamera();

      // Emit success state to trigger UI rebuild with new camera
      emit(
        state.copyWith(
          mlMediaDataState: DataState.loaded(),
          timestamp: () => DateTime.now(), // Update timestamp to force rebuild
        ),
      );

      // Camera stream handling will be done by the specific ML module
    } catch (e) {
      emit(
        state.copyWith(
          mlMediaDataState: state.mlMediaDataState.toFailure(
            error: Exception('Failed to switch camera: $e'),
          ),
        ),
      );
    }
  }

  /// Clear current results and go back to initial state
  void clearResults() {
    emit(const MLMediaState());
  }

  /// Get camera stream for ML processing (used by specific ML modules)
  Stream<CameraImage> getCameraStream() {
    return _mlMediaService.getCameraStream();
  }

  /// Get camera controller for preview
  CameraController? get cameraController {
    final controller = _mlMediaService.cameraController;
    if (controller == null) return null;

    try {
      if (controller.value.isInitialized) {
        return controller;
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  /// Check if services are initialized
  bool get isInitialized => _isInitialized;

  /// Get current image if available
  File? get currentImage => state.image;

  @override
  Future<void> close() async {
    await _cameraStreamSubscription?.cancel();
    await _mlMediaService.dispose();
    return super.close();
  }
}
