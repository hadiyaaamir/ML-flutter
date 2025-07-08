import 'package:equatable/equatable.dart';

class ExtractedEntity extends Equatable {
  const ExtractedEntity({
    required this.text,
    required this.type,
    required this.startIndex,
    required this.endIndex,
  });

  final String text;
  final String type;
  final int startIndex;
  final int endIndex;

  @override
  List<Object?> get props => [text, type, startIndex, endIndex];

  @override
  String toString() {
    return 'ExtractedEntity(text: $text, type: $type, startIndex: $startIndex, endIndex: $endIndex)';
  }
}
