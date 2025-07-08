part of 'smart_reply_cubit.dart';

class SmartReplyState extends Equatable {
  const SmartReplyState({
    this.conversation = const [],
    this.suggestions = const [],
    this.isLoading = false,
    this.error,
  });

  final List<ConversationMessage> conversation;
  final List<String> suggestions;
  final bool isLoading;
  final String? error;

  @override
  List<Object?> get props => [conversation, suggestions, isLoading, error];

  SmartReplyState copyWith({
    List<ConversationMessage>? conversation,
    List<String>? suggestions,
    bool? isLoading,
    String? error,
  }) {
    return SmartReplyState(
      conversation: conversation ?? this.conversation,
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
