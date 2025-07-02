import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math' as math;
import '../models/face_filter.dart';
import '../../common/assets.dart';

/// Widget that overlays PNG images for face filters
class FaceImageFilterOverlay extends StatelessWidget {
  const FaceImageFilterOverlay({
    super.key,
    required this.faces,
    required this.imageSize,
    required this.containerSize,
    required this.selectedFilter,
  });

  final List<Face> faces;
  final Size imageSize;
  final Size containerSize;
  final FaceFilterType selectedFilter;

  @override
  Widget build(BuildContext context) {
    if (faces.isEmpty || selectedFilter == FaceFilterType.none) {
      return const SizedBox.shrink();
    }

    // Calculate scaling and offset using BoxFit.contain logic (same as FacePainter)
    final imageAspectRatio = imageSize.width / imageSize.height;
    final containerAspectRatio = containerSize.width / containerSize.height;

    double drawWidth, drawHeight, offsetX, offsetY;
    double scaleX, scaleY;

    if (imageAspectRatio > containerAspectRatio) {
      // Image is wider than container - fit to width
      drawWidth = containerSize.width;
      drawHeight = containerSize.width / imageAspectRatio;
      offsetX = 0;
      offsetY = (containerSize.height - drawHeight) / 2;
    } else {
      // Image is taller than container - fit to height
      drawHeight = containerSize.height;
      drawWidth = containerSize.height * imageAspectRatio;
      offsetX = (containerSize.width - drawWidth) / 2;
      offsetY = 0;
    }

    // Calculate scale factors based on the actual drawn image size
    scaleX = drawWidth / imageSize.width;
    scaleY = drawHeight / imageSize.height;

    return SizedBox(
      width: containerSize.width,
      height: containerSize.height,
      child: Stack(
        children:
            faces.map((face) {
              return _buildFilterForFace(
                face,
                scaleX,
                scaleY,
                offsetX,
                offsetY,
              );
            }).toList(),
      ),
    );
  }

  Widget _buildFilterForFace(
    Face face,
    double scaleX,
    double scaleY,
    double offsetX,
    double offsetY,
  ) {
    final filterElements = FilterPositionHelper.getFilterElements(
      selectedFilter,
      face,
    );

    return Stack(
      children:
          filterElements.map((element) {
            return _buildFilterElement(
              element,
              scaleX,
              scaleY,
              offsetX,
              offsetY,
            );
          }).toList(),
    );
  }

  Widget _buildFilterElement(
    FilterElement element,
    double scaleX,
    double scaleY,
    double offsetX,
    double offsetY,
  ) {
    // Apply scaling and offset (same as FacePainter)
    final scaledPosition = Offset(
      element.position.dx * scaleX + offsetX,
      element.position.dy * scaleY + offsetY,
    );
    final scaledSize = Size(
      element.size.width * scaleX,
      element.size.height * scaleY,
    );

    return Positioned(
      left: scaledPosition.dx - scaledSize.width / 2,
      top: scaledPosition.dy - scaledSize.height / 2,
      child: Transform.rotate(
        angle: element.rotation * (math.pi / 180), // Convert degrees to radians
        child: SizedBox(
          width: scaledSize.width,
          height: scaledSize.height,
          child: _getFilterImage(element.type, element.isLeft),
        ),
      ),
    );
  }

  Widget _getFilterImage(FilterElementType type, bool isLeft) {
    String assetPath;

    switch (type) {
      case FilterElementType.googlyEye:
        assetPath =
            isLeft ? AssetImages.googlyEyeLeft : AssetImages.googlyEyeRight;
        break;
      case FilterElementType.mustache:
        assetPath = AssetImages.mustache;
        break;
      case FilterElementType.sunglasses:
        assetPath = AssetImages.sunglasses;
        break;
      case FilterElementType.hat:
        assetPath = AssetImages.hat;
        break;
      case FilterElementType.clownNose:
        assetPath = AssetImages.clownNose;
        break;
      case FilterElementType.beard:
        assetPath = AssetImages.beard;
        break;
      case FilterElementType.eyepatch:
        assetPath = AssetImages.eyepatch;
        break;
      case FilterElementType.crown:
        assetPath = AssetImages.crown;
        break;
      case FilterElementType.bunnyEar:
        assetPath =
            isLeft ? AssetImages.bunnyEarLeft : AssetImages.bunnyEarRight;
        break;
    }

    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.error, color: Colors.red, size: 16),
        );
      },
    );
  }
}

/// Widget that overlays filters for live camera
class LiveCameraFilterOverlay extends StatelessWidget {
  const LiveCameraFilterOverlay({
    super.key,
    required this.faces,
    required this.cameraPreviewSize,
    required this.containerSize,
    required this.selectedFilter,
  });

  final List<Face> faces;
  final Size cameraPreviewSize;
  final Size containerSize;
  final FaceFilterType selectedFilter;

  @override
  Widget build(BuildContext context) {
    if (faces.isEmpty || selectedFilter == FaceFilterType.none) {
      return const SizedBox.shrink();
    }

    // Match the coordinate transformation logic from LiveCameraFacePainter
    // The camera preview is displayed with AspectRatio and BoxFit.cover

    final previewAspectRatio =
        cameraPreviewSize.width / cameraPreviewSize.height;

    // Calculate the actual displayed camera preview size within the container
    double actualPreviewWidth, actualPreviewHeight;

    if (containerSize.width / containerSize.height > previewAspectRatio) {
      // Container is wider than preview aspect ratio
      actualPreviewHeight = containerSize.height;
      actualPreviewWidth = containerSize.height * previewAspectRatio;
    } else {
      // Container is taller than preview aspect ratio
      actualPreviewWidth = containerSize.width;
      actualPreviewHeight = containerSize.width / previewAspectRatio;
    }

    // Center the preview within the container
    final previewOffsetX = (containerSize.width - actualPreviewWidth) / 2;
    final previewOffsetY = (containerSize.height - actualPreviewHeight) / 2;

    // Calculate scaling within the actual preview area (BoxFit.cover)
    final cameraAspectRatio =
        cameraPreviewSize.width / cameraPreviewSize.height;
    final previewDisplayRatio = actualPreviewWidth / actualPreviewHeight;

    double scaleX, scaleY, cropOffsetX, cropOffsetY;

    if (cameraAspectRatio > previewDisplayRatio) {
      // Camera is wider - fit to height, crop sides
      scaleY = actualPreviewHeight / cameraPreviewSize.height;
      scaleX = scaleY;

      final scaledWidth = cameraPreviewSize.width * scaleX;
      cropOffsetX = (actualPreviewWidth - scaledWidth) / 2;
      cropOffsetY = 0;
    } else {
      // Camera is taller - fit to width, crop top/bottom
      scaleX = actualPreviewWidth / cameraPreviewSize.width;
      scaleY = scaleX;

      final scaledHeight = cameraPreviewSize.height * scaleY;
      cropOffsetX = 0;
      cropOffsetY = (actualPreviewHeight - scaledHeight) / 2;
    }

    // Final transformation: preview offset + crop offset
    final finalOffsetX = previewOffsetX + cropOffsetX;
    final finalOffsetY = previewOffsetY + cropOffsetY;

    return SizedBox(
      width: containerSize.width,
      height: containerSize.height,
      child: Stack(
        children:
            faces.map((face) {
              return _buildFilterForFace(
                face,
                scaleX,
                scaleY,
                finalOffsetX,
                finalOffsetY,
              );
            }).toList(),
      ),
    );
  }

  Widget _buildFilterForFace(
    Face face,
    double scaleX,
    double scaleY,
    double offsetX,
    double offsetY,
  ) {
    // Use face coordinates directly (no additional adjustments needed)
    final filterElements = FilterPositionHelper.getFilterElements(
      selectedFilter,
      face,
    );

    return Stack(
      children:
          filterElements.map((element) {
            return _buildFilterElement(
              element,
              scaleX,
              scaleY,
              offsetX,
              offsetY,
            );
          }).toList(),
    );
  }

  Widget _buildFilterElement(
    FilterElement element,
    double scaleX,
    double scaleY,
    double offsetX,
    double offsetY,
  ) {
    // Apply scaling and offset (same as FacePainter)
    final scaledPosition = Offset(
      element.position.dx * scaleX + offsetX,
      element.position.dy * scaleY + offsetY,
    );
    final scaledSize = Size(
      element.size.width * scaleX,
      element.size.height * scaleY,
    );

    return Positioned(
      left: scaledPosition.dx - scaledSize.width / 2,
      top: scaledPosition.dy - scaledSize.height / 2,
      child: Transform.rotate(
        angle: element.rotation * (math.pi / 180), // Convert degrees to radians
        child: SizedBox(
          width: scaledSize.width,
          height: scaledSize.height,
          child: _getFilterImage(element.type, element.isLeft),
        ),
      ),
    );
  }

  Widget _getFilterImage(FilterElementType type, bool isLeft) {
    // Use actual PNG images for live camera (same as static image version)
    String assetPath;

    switch (type) {
      case FilterElementType.googlyEye:
        assetPath =
            isLeft ? AssetImages.googlyEyeLeft : AssetImages.googlyEyeRight;
        break;
      case FilterElementType.mustache:
        assetPath = AssetImages.mustache;
        break;
      case FilterElementType.sunglasses:
        assetPath = AssetImages.sunglasses;
        break;
      case FilterElementType.hat:
        assetPath = AssetImages.hat;
        break;
      case FilterElementType.clownNose:
        assetPath = AssetImages.clownNose;
        break;
      case FilterElementType.beard:
        assetPath = AssetImages.beard;
        break;
      case FilterElementType.eyepatch:
        assetPath = AssetImages.eyepatch;
        break;
      case FilterElementType.crown:
        assetPath = AssetImages.crown;
        break;
      case FilterElementType.bunnyEar:
        assetPath =
            isLeft ? AssetImages.bunnyEarLeft : AssetImages.bunnyEarRight;
        break;
    }

    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.error, color: Colors.red, size: 16),
        );
      },
    );
  }
}
