part of 'barcode_scanning_cubit.dart';

typedef BarcodeScanningDataState = DataState<List<BarcodeResult>>;

enum BarcodeScanningMode {
  static, // Single image processing
  live, // Live camera streaming
}

class BarcodeScanningState extends Equatable {
  const BarcodeScanningState({
    this.image,
    this.barcodes,
    this.timestamp,
    this.barcodeScanningDataState = const DataState.initial(),
    this.previousState,
    this.mode = BarcodeScanningMode.static,
    this.isLiveCameraActive = false,
    this.liveCameraBarcodes = const [],
  });

  final File? image;
  final List<BarcodeResult>? barcodes;
  final DateTime? timestamp;
  final BarcodeScanningDataState barcodeScanningDataState;
  final BarcodeScanningState? previousState;
  final BarcodeScanningMode mode;
  final bool isLiveCameraActive;
  final List<BarcodeResult> liveCameraBarcodes;

  BarcodeScanningState copyWith({
    File? image,
    List<BarcodeResult>? Function()? barcodes,
    DateTime? Function()? timestamp,
    BarcodeScanningDataState? barcodeScanningDataState,
    BarcodeScanningState? previousState,
    BarcodeScanningMode? mode,
    bool? isLiveCameraActive,
    List<BarcodeResult>? liveCameraBarcodes,
  }) {
    return BarcodeScanningState(
      image: image ?? this.image,
      barcodes: barcodes != null ? barcodes() : this.barcodes,
      timestamp: timestamp != null ? timestamp() : this.timestamp,
      barcodeScanningDataState:
          barcodeScanningDataState ?? this.barcodeScanningDataState,
      previousState: previousState ?? this.previousState,
      mode: mode ?? this.mode,
      isLiveCameraActive: isLiveCameraActive ?? this.isLiveCameraActive,
      liveCameraBarcodes: liveCameraBarcodes ?? this.liveCameraBarcodes,
    );
  }

  @override
  List<Object?> get props => [
    image,
    barcodes,
    timestamp,
    barcodeScanningDataState,
    previousState,
    mode,
    isLiveCameraActive,
    liveCameraBarcodes,
  ];
}

extension StateValues on BarcodeScanningState {
  /// Returns actionable barcodes (URLs, emails, phones, etc.)
  List<BarcodeResult> getActionableBarcodes() {
    final barcodesToCheck =
        mode == BarcodeScanningMode.live
            ? liveCameraBarcodes
            : (barcodes ?? []);
    return barcodesToCheck.where((barcode) => barcode.isActionable).toList();
  }

  /// Returns barcodes of a specific type
  List<BarcodeResult> getBarcodesByType(BarcodeType type) {
    final barcodesToCheck =
        mode == BarcodeScanningMode.live
            ? liveCameraBarcodes
            : (barcodes ?? []);
    return barcodesToCheck.where((barcode) => barcode.type == type).toList();
  }

  /// Get current barcodes based on mode
  List<BarcodeResult> get currentBarcodes {
    return mode == BarcodeScanningMode.live
        ? liveCameraBarcodes
        : (barcodes ?? []);
  }
}
