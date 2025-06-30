import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/cubit.dart';

/// Configuration for custom status messages
class MLStatusConfig {
  const MLStatusConfig({
    this.staticReadyMessage = 'Ready to capture or select an image',
    this.staticProcessingMessage = 'Processing...',
    this.staticResultsMessage,
    this.liveStartingMessage = 'Starting live camera...',
    this.liveActiveMessage = 'Live camera active - Looking for objects...',
    this.liveDetectingMessage,
    this.liveReadyMessage = 'Ready to start live detection',
  });

  final String staticReadyMessage;
  final String staticProcessingMessage;
  final String? staticResultsMessage;
  final String liveStartingMessage;
  final String liveActiveMessage;
  final String? liveDetectingMessage;
  final String liveReadyMessage;
}

/// Reusable status card widget for ML media operations
class MLStatusCard extends StatelessWidget {
  const MLStatusCard({
    super.key,
    this.config = const MLStatusConfig(),
    this.hasResults = false,
    this.resultCount,
  });

  /// Configuration for custom status messages
  final MLStatusConfig config;

  /// Whether there are ML processing results available
  final bool hasResults;

  /// Number of results found (optional)
  final int? resultCount;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MLMediaCubit, MLMediaState>(
      builder: (context, state) {
        String statusText;
        Color statusColor;
        IconData statusIcon;
        bool showLoading = false;

        if (state.mode == MLMediaMode.live) {
          // Live camera mode status
          if (state.mlMediaDataState.isLoading) {
            statusText = config.liveStartingMessage;
            statusColor = Colors.orange;
            statusIcon = Icons.videocam;
            showLoading = true;
          } else if (state.isLiveCameraActive) {
            if (hasResults && resultCount != null && resultCount! > 0) {
              statusText =
                  config.liveDetectingMessage ??
                  'Live detection: $resultCount objects found';
              statusColor = Colors.green;
              statusIcon = Icons.visibility;
            } else {
              statusText = config.liveActiveMessage;
              statusColor = Colors.blue;
              statusIcon = Icons.videocam;
            }
          } else if (state.mlMediaDataState.isFailure) {
            statusText = state.mlMediaDataState.errorMessage ?? 'Camera error';
            statusColor = Colors.red;
            statusIcon = Icons.error;
          } else {
            statusText = config.liveReadyMessage;
            statusColor = Colors.blue;
            statusIcon = Icons.videocam;
          }
        } else {
          // Static image mode status
          if (state.mlMediaDataState.isInitial) {
            statusText = config.staticReadyMessage;
            statusColor = Colors.blue;
            statusIcon = Icons.camera_alt;
          } else if (state.mlMediaDataState.isLoading) {
            statusText = config.staticProcessingMessage;
            statusColor = Colors.orange;
            statusIcon = Icons.hourglass_empty;
            showLoading = true;
          } else if (state.mlMediaDataState.isFailure) {
            statusText =
                state.mlMediaDataState.errorMessage ?? 'Error occurred';
            statusColor = Colors.red;
            statusIcon = Icons.error;
          } else if (hasResults && resultCount != null && resultCount! > 0) {
            statusText =
                config.staticResultsMessage ?? 'Found $resultCount results';
            statusColor = Colors.purple;
            statusIcon = Icons.label;
          } else if (state.image != null) {
            statusText = 'Image captured! Processing...';
            statusColor = Colors.green;
            statusIcon = Icons.analytics;
            showLoading = true;
          } else {
            statusText = 'Ready to start';
            statusColor = Colors.blue;
            statusIcon = Icons.camera_alt;
          }
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (showLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
