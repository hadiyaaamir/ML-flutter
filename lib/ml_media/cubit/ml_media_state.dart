import 'dart:io';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:ml_flutter/common/common.dart';

/// Enumeration for different ML media operation modes
enum MLMediaMode {
  /// Static image processing mode
  static,

  /// Live camera processing mode
  live,
}

/// State class for ML Media operations
class MLMediaState extends Equatable {
  const MLMediaState({
    this.mode = MLMediaMode.static,
    this.image,
    this.isLiveCameraActive = false,
    this.mlMediaDataState = const DataState.initial(),
    this.timestamp,
  });

  /// Current operation mode (static or live)
  final MLMediaMode mode;

  /// Currently selected/captured image (for static mode)
  final File? image;

  /// Whether live camera is currently active
  final bool isLiveCameraActive;

  /// Data state for ML media operations
  final DataState mlMediaDataState;

  /// Timestamp of last operation
  final DateTime? timestamp;

  /// Create a copy of this state with updated values
  MLMediaState copyWith({
    MLMediaMode? mode,
    File? image,
    bool? isLiveCameraActive,
    DataState? mlMediaDataState,
    DateTime? timestamp,
  }) {
    return MLMediaState(
      mode: mode ?? this.mode,
      image: image,
      isLiveCameraActive: isLiveCameraActive ?? this.isLiveCameraActive,
      mlMediaDataState: mlMediaDataState ?? this.mlMediaDataState,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
    mode,
    image,
    isLiveCameraActive,
    mlMediaDataState,
    timestamp,
  ];
}
