/// Central class for managing asset image file paths
class AssetImages {
  AssetImages._();

  // Base paths
  static const String _basePath = 'assets/images';
  static const String _faceFiltersPath = '$_basePath/face_filters';

  // Face filter assets
  static const String googlyEyeLeft = '$_faceFiltersPath/googly_eye_left.png';
  static const String googlyEyeRight = '$_faceFiltersPath/googly_eye_right.png';
  static const String mustache = '$_faceFiltersPath/mustache.png';
  static const String sunglasses = '$_faceFiltersPath/sunglasses.png';
  static const String hat = '$_faceFiltersPath/hat.png';
  static const String clownNose = '$_faceFiltersPath/clown_nose.png';
  static const String beard = '$_faceFiltersPath/beard.png';
  static const String eyepatch = '$_faceFiltersPath/eyepatch.png';
  static const String crown = '$_faceFiltersPath/crown.png';
  static const String bunnyEarLeft = '$_faceFiltersPath/bunny_ear_left.png';
  static const String bunnyEarRight = '$_faceFiltersPath/bunny_ear_right.png';

  /// Get all face filter asset paths
  static List<String> get allFaceFilterAssets => [
    googlyEyeLeft,
    googlyEyeRight,
    mustache,
    sunglasses,
    hat,
    clownNose,
    beard,
    eyepatch,
    crown,
    bunnyEarLeft,
    bunnyEarRight,
  ];
}
