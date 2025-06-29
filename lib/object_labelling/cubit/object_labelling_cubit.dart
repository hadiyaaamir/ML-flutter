import 'dart:io';
import 'package:equatable/equatable.dart';
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

      final options = ImageLabelerOptions(confidenceThreshold: 0.3);
      _imageLabeler = ImageLabeler(options: options);

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
    emit(ObjectLabellingState());
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

  @override
  Future<void> close() {
    _imageLabeler.close();
    return super.close();
  }
}
