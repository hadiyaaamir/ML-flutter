import 'package:equatable/equatable.dart';

class SmartReplyResult extends Equatable {
  const SmartReplyResult({required this.suggestions, this.error});

  final List<String> suggestions;
  final String? error;

  @override
  List<Object?> get props => [suggestions, error];

  SmartReplyResult copyWith({List<String>? suggestions, String? error}) {
    return SmartReplyResult(
      suggestions: suggestions ?? this.suggestions,
      error: error ?? this.error,
    );
  }
}
