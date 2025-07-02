part of 'view.dart';

class BarcodeScanningView extends StatelessWidget {
  const BarcodeScanningView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barcode Scanner'), centerTitle: true),
      body: BlocBuilder<BarcodeScanningCubit, BarcodeScanningState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MLModeToggle(title: 'Barcode Scanner Mode'),
                const SizedBox(height: 16),
                _BarcodeScanningStatusCard(),
                const SizedBox(height: 16),
                _CameraOrActionSection(),
                const SizedBox(height: 16),
                _BarcodeScanningImageDisplay(),
                _DetectedBarcodes(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CameraOrActionSection extends StatelessWidget {
  const _CameraOrActionSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BarcodeScanningCubit, BarcodeScanningState>(
      builder: (context, state) {
        if (state.mode == BarcodeScanningMode.live) {
          return _BarcodeScanningCameraPreview();
        } else {
          return _BarcodeScanningActionButtons();
        }
      },
    );
  }
}

/// Custom status card for barcode scanning
class _BarcodeScanningStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BarcodeScanningCubit, BarcodeScanningState>(
      builder: (context, state) {
        String statusText;
        Color statusColor;
        IconData statusIcon;
        bool showLoading = false;

        if (state.mode == BarcodeScanningMode.live) {
          // Live camera mode status
          if (state.isLiveCameraActive) {
            if (state.liveCameraBarcodes.isNotEmpty) {
              statusText =
                  'Barcodes detected: ${state.liveCameraBarcodes.length}';
              statusColor = Colors.green;
              statusIcon = Icons.qr_code_scanner;
            } else {
              statusText = 'Live barcode detection active';
              statusColor = Colors.blue;
              statusIcon = Icons.videocam;
            }
          } else {
            statusText = 'Ready to start live detection';
            statusColor = Colors.blue;
            statusIcon = Icons.videocam;
          }
        } else {
          // Static image mode status
          if (state.barcodeScanningDataState.isInitial) {
            statusText = 'Ready to scan barcodes';
            statusColor = Colors.blue;
            statusIcon = Icons.camera_alt;
          } else if (state.barcodeScanningDataState.isLoading) {
            statusText = 'Scanning for barcodes...';
            statusColor = Colors.orange;
            statusIcon = Icons.hourglass_empty;
            showLoading = true;
          } else if (state.barcodeScanningDataState.isFailure) {
            statusText =
                state.barcodeScanningDataState.errorMessage ?? 'Error occurred';
            statusColor = Colors.red;
            statusIcon = Icons.error;
          } else if (state.currentBarcodes.isNotEmpty) {
            statusText = 'Found ${state.currentBarcodes.length} barcode(s)';
            statusColor = Colors.purple;
            statusIcon = Icons.qr_code;
          } else if (state.image != null) {
            statusText = 'No barcodes detected';
            statusColor = Colors.grey;
            statusIcon = Icons.search_off;
          } else {
            statusText = 'Ready to scan barcodes';
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

/// Custom camera preview for barcode scanning with overlay
class _BarcodeScanningCameraPreview extends StatelessWidget {
  const _BarcodeScanningCameraPreview();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BarcodeScanningCubit, BarcodeScanningState>(
      builder: (context, state) {
        if (!state.isLiveCameraActive) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            // Camera preview
            MLCameraPreview(
              title: 'Live Barcode Scanner',
              showSwitchButton: true,
            ),
            const SizedBox(height: 8),
            // Live detection status indicator
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      state.liveCameraBarcodes.isNotEmpty
                          ? Icons.qr_code_scanner
                          : Icons.search,
                      color:
                          state.liveCameraBarcodes.isNotEmpty
                              ? Colors.green
                              : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.liveCameraBarcodes.isNotEmpty
                          ? 'Barcodes detected: ${state.liveCameraBarcodes.length}'
                          : 'Scanning for barcodes...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom image display for barcode scanning
class _BarcodeScanningImageDisplay extends StatelessWidget {
  const _BarcodeScanningImageDisplay();

  @override
  Widget build(BuildContext context) {
    return MLImageDisplay(title: 'Scanned Image', maxHeight: 300);
  }
}

/// Custom action buttons for barcode scanning
class _BarcodeScanningActionButtons extends StatelessWidget {
  const _BarcodeScanningActionButtons();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BarcodeScanningCubit, BarcodeScanningState>(
      builder: (context, state) {
        return MLActionButtons(
          captureButtonText: 'Scan Barcode',
          galleryButtonText: 'Select Image',
          retryButtonText: 'Try Another Image',
          hasResults: state.currentBarcodes.isNotEmpty,
          showRetryButton: true,
        );
      },
    );
  }
}

/// Widget to display detected barcodes
class _DetectedBarcodes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BarcodeScanningCubit, BarcodeScanningState>(
      builder: (context, state) {
        final barcodes = state.currentBarcodes;

        if (barcodes.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Detected Barcodes (${barcodes.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: barcodes.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final barcode = barcodes[index];
                    return _BarcodeCard(barcode: barcode);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Card widget for displaying individual barcode information
class _BarcodeCard extends StatelessWidget {
  final BarcodeResult barcode;

  const _BarcodeCard({required this.barcode});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconData(barcode.iconName),
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    barcode.typeDescription,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  barcode.formatDescription,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              barcode.formattedDisplayValue,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (barcode.isActionable) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _handleBarcodeAction(context, barcode),
                icon: Icon(_getActionIconData(barcode.type), size: 16),
                label: Text(barcode.actionDescription ?? 'Open'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'link':
        return Icons.link;
      case 'email':
        return Icons.email;
      case 'phone':
        return Icons.phone;
      case 'message':
        return Icons.message;
      case 'wifi':
        return Icons.wifi;
      case 'location_on':
        return Icons.location_on;
      case 'contact_page':
        return Icons.contact_page;
      case 'event':
        return Icons.event;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'book':
        return Icons.book;
      default:
        return Icons.qr_code;
    }
  }

  IconData _getActionIconData(BarcodeType type) {
    switch (type) {
      case BarcodeType.url:
        return Icons.open_in_browser;
      case BarcodeType.email:
        return Icons.email;
      case BarcodeType.phone:
        return Icons.call;
      case BarcodeType.sms:
        return Icons.sms;
      case BarcodeType.wifi:
        return Icons.wifi;
      case BarcodeType.geoCoordinates:
        return Icons.map;
      default:
        return Icons.open_in_new;
    }
  }

  Future<void> _handleBarcodeAction(
    BuildContext context,
    BarcodeResult barcode,
  ) async {
    try {
      String url;
      switch (barcode.type) {
        case BarcodeType.url:
          url = barcode.formattedDisplayValue;
          break;
        case BarcodeType.email:
          url = 'mailto:${barcode.formattedDisplayValue}';
          break;
        case BarcodeType.phone:
          url = 'tel:${barcode.formattedDisplayValue}';
          break;
        case BarcodeType.sms:
          url = 'sms:${barcode.formattedDisplayValue}';
          break;
        case BarcodeType.geoCoordinates:
          url =
              'https://maps.google.com/maps?q=${barcode.formattedDisplayValue}';
          break;
        default:
          return;
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot open: ${barcode.formattedDisplayValue}'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening: $e')));
      }
    }
  }
}
