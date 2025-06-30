import 'package:equatable/equatable.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// Model representing a scanned barcode result
class BarcodeResult extends Equatable {
  const BarcodeResult({
    required this.displayValue,
    required this.rawValue,
    required this.type,
    required this.format,
  });

  /// The display value of the barcode
  final String displayValue;

  /// The raw value of the barcode
  final String rawValue;

  /// The type of barcode (URL, EMAIL, PHONE, etc.)
  final BarcodeType type;

  /// The format of barcode (QR_CODE, CODE_128, etc.)
  final BarcodeFormat format;

  /// Create BarcodeResult from ML Kit Barcode
  factory BarcodeResult.fromBarcode(Barcode barcode) {
    return BarcodeResult(
      displayValue: barcode.displayValue ?? '',
      rawValue: barcode.rawValue ?? '',
      type: barcode.type,
      format: barcode.format,
    );
  }

  /// Get a human-readable description of the barcode type
  String get typeDescription {
    switch (type) {
      case BarcodeType.url:
        return 'Website';
      case BarcodeType.email:
        return 'Email';
      case BarcodeType.phone:
        return 'Phone';
      case BarcodeType.sms:
        return 'SMS';
      case BarcodeType.wifi:
        return 'WiFi';
      case BarcodeType.geoCoordinates:
        return 'Location';
      case BarcodeType.contactInfo:
        return 'Contact';
      case BarcodeType.calendarEvent:
        return 'Calendar';
      case BarcodeType.driverLicense:
        return 'License';
      case BarcodeType.text:
        return 'Text';
      case BarcodeType.product:
        return 'Product';
      case BarcodeType.isbn:
        return 'ISBN';
      case BarcodeType.unknown:
        return 'Unknown';
    }
  }

  /// Get a human-readable description of the barcode format
  String get formatDescription {
    switch (format) {
      case BarcodeFormat.qrCode:
        return 'QR Code';
      case BarcodeFormat.code128:
        return 'Code 128';
      case BarcodeFormat.code39:
        return 'Code 39';
      case BarcodeFormat.code93:
        return 'Code 93';
      case BarcodeFormat.codabar:
        return 'Codabar';
      case BarcodeFormat.dataMatrix:
        return 'Data Matrix';
      case BarcodeFormat.ean13:
        return 'EAN-13';
      case BarcodeFormat.ean8:
        return 'EAN-8';
      case BarcodeFormat.itf:
        return 'ITF';
      case BarcodeFormat.pdf417:
        return 'PDF417';
      case BarcodeFormat.upca:
        return 'UPC-A';
      case BarcodeFormat.upce:
        return 'UPC-E';
      case BarcodeFormat.aztec:
        return 'Aztec';
      case BarcodeFormat.all:
        return 'All';
      case BarcodeFormat.unknown:
        return 'Unknown';
    }
  }

  /// Get formatted display text based on barcode type
  String get formattedDisplayValue {
    if (displayValue.isNotEmpty) {
      return displayValue;
    }
    return rawValue;
  }

  /// Check if this barcode has actionable content
  bool get isActionable {
    return type == BarcodeType.url ||
        type == BarcodeType.email ||
        type == BarcodeType.phone ||
        type == BarcodeType.sms ||
        type == BarcodeType.wifi ||
        type == BarcodeType.geoCoordinates;
  }

  /// Get action description for actionable barcodes
  String? get actionDescription {
    switch (type) {
      case BarcodeType.url:
        return 'Open in browser';
      case BarcodeType.email:
        return 'Send email';
      case BarcodeType.phone:
        return 'Call number';
      case BarcodeType.sms:
        return 'Send SMS';
      case BarcodeType.wifi:
        return 'Connect to WiFi';
      case BarcodeType.geoCoordinates:
        return 'Open in maps';
      default:
        return null;
    }
  }

  /// Get an icon for the barcode type
  String get iconName {
    switch (type) {
      case BarcodeType.url:
        return 'link';
      case BarcodeType.email:
        return 'email';
      case BarcodeType.phone:
        return 'phone';
      case BarcodeType.sms:
        return 'message';
      case BarcodeType.wifi:
        return 'wifi';
      case BarcodeType.geoCoordinates:
        return 'location_on';
      case BarcodeType.contactInfo:
        return 'contact_page';
      case BarcodeType.calendarEvent:
        return 'event';
      case BarcodeType.product:
        return 'shopping_cart';
      case BarcodeType.isbn:
        return 'book';
      default:
        return 'qr_code';
    }
  }

  @override
  List<Object?> get props => [displayValue, rawValue, type, format];
}
