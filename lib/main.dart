import 'package:flutter/material.dart';
import 'package:ml_flutter/face_detection/view/view.dart';
import 'package:ml_flutter/object_labelling/object_labelling.dart';
import 'package:ml_flutter/barcode_scanning/barcode_scanning.dart';
import 'package:ml_flutter/object_detection/object_detection.dart';
import 'package:ml_flutter/text_recognition/text_recognition.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter ML Hub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MLFoundationScreen(),
    );
  }
}

class MLFoundationScreen extends StatelessWidget {
  const MLFoundationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 16,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Column(
                children: [
                  Icon(Icons.psychology, size: 80, color: Colors.deepPurple),
                  SizedBox(height: 16),
                  Text(
                    'Flutter ML Hub',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Explore machine learning capabilities',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            _Apps(),
          ],
        ),
      ),
    );
  }
}

class _Apps extends StatelessWidget {
  const _Apps();

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        // Object Labelling
        AppTile(
          icon: Icons.label,
          title: 'Object Labelling',
          description: 'Detect and identify objects in images using AI',
          color: Colors.purple,
          onTap: () => Navigator.push(context, ObjectLabellingPage.route()),
        ),

        // Barcode Scanner
        AppTile(
          icon: Icons.qr_code_scanner,
          title: 'Barcode Scanner',
          description: 'Scan QR codes and barcodes with live detection',
          color: Colors.green,
          onTap: () => Navigator.push(context, BarcodeScanningPage.route()),
        ),

        // Face Detection
        AppTile(
          icon: Icons.face,
          title: 'Face Detection',
          description: 'Detect and identify faces in images using AI',
          color: Colors.blue,
          onTap: () => Navigator.push(context, FaceDetectionPage.route()),
        ),

        // Object Classification
        AppTile(
          icon: Icons.filter_center_focus_outlined,
          title: 'Object Classification',
          description: 'Identify and classify objects in images',
          color: Colors.orange,
          onTap: () => Navigator.push(context, ObjectDetectionPage.route()),
        ),

        // Text Recognition
        AppTile(
          icon: Icons.text_fields,
          title: 'Text Recognition',
          description: 'Extract and recognize text from images using OCR',
          color: Colors.teal,
          onTap: () => Navigator.push(context, TextRecognitionPage.route()),
        ),
      ],
    );
  }
}

class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
