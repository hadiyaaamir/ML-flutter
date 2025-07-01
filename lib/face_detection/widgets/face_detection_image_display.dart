import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:ml_flutter/face_detection/models/models.dart';
import '../models/face_filter.dart';
import 'face_image_filter_overlay.dart';

/// Widget to display image with face detection overlay
class FaceDetectionImageDisplay extends StatelessWidget {
  final File? image;
  final List<Face> faces;
  final String title;
  final double? maxHeight;
  final bool showContours;
  final bool showLabels;
  final FaceFilterType selectedFilter;

  const FaceDetectionImageDisplay({
    super.key,
    required this.image,
    required this.faces,
    this.title = 'Face Detection Result',
    this.maxHeight,
    this.showContours = true,
    this.showLabels = true,
    this.selectedFilter = FaceFilterType.none,
  });

  @override
  Widget build(BuildContext context) {
    if (image == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          width: double.infinity,
          height: 300, // Fixed square height
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return FutureBuilder<ui.Image>(
                  future: _loadImage(image!),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final imageSize = Size(
                        snapshot.data!.width.toDouble(),
                        snapshot.data!.height.toDouble(),
                      );

                      return Stack(
                        children: [
                          // Base image with face detection overlay
                          CustomPaint(
                            painter: FacePainter(
                              faces: faces,
                              imageSize: imageSize,
                              image: snapshot.data,
                              showContours: showContours,
                              showLabels: showLabels,
                            ),
                            child: Container(), // Fill the entire container
                          ),
                          // Face filters overlay using PNG images
                          if (selectedFilter != FaceFilterType.none)
                            FaceImageFilterOverlay(
                              faces: faces,
                              imageSize: imageSize,
                              containerSize: Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              ),
                              selectedFilter: selectedFilter,
                            ),
                        ],
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 48),
                            SizedBox(height: 8),
                            Text('Failed to load image'),
                          ],
                        ),
                      );
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<ui.Image> _loadImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
