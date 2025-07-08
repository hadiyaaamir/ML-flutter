import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_mlkit_smart_reply/google_mlkit_smart_reply.dart';
import '../models/conversation_message.dart';

part 'smart_reply_state.dart';

class SmartReplyCubit extends Cubit<SmartReplyState> {
  SmartReplyCubit() : super(const SmartReplyState());

  final SmartReply _smartReply = SmartReply();
  final List<ConversationMessage> _conversation = [];
  bool _isInitialized = false;

  // This method adds a message from a remote user and generates smart replies
  void addMessage(String text, {bool isLocalUser = false, String? userId}) {
    final message = ConversationMessage(
      text: text,
      timestamp: DateTime.now(),
      isLocalUser: isLocalUser,
      userId: isLocalUser ? 'local' : (userId ?? 'remote_user'),
    );

    _conversation.add(message);

    // Add message to Smart Reply conversation
    if (isLocalUser) {
      _smartReply.addMessageToConversationFromLocalUser(
        text,
        message.timestamp.millisecondsSinceEpoch,
      );
    } else {
      _smartReply.addMessageToConversationFromRemoteUser(
        text,
        message.timestamp.millisecondsSinceEpoch,
        message.userId!,
      );
    }

    // Sort messages chronologically
    _conversation.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    emit(
      state.copyWith(
        conversation: List.from(_conversation),
        suggestions:
            isLocalUser
                ? []
                : state
                    .suggestions, // Clear suggestions only for remote messages
        isLoading: false,
        error: null,
      ),
    );

    // Generate smart replies only if the last message is from a remote user
    if (!isLocalUser) {
      _generateSmartReplies();
    }
  }

  // Method to add a new message to the conversation
  void addNewMessage(String message) {
    // Initialize conversation if this is the first message
    if (!_isInitialized) {
      _initializeConversation();
      _isInitialized = true;
    }

    // Add the new message as a remote user message
    addMessage(message, isLocalUser: false);
  }

  void _initializeConversation() {
    // Add an initial context message to help Smart Reply understand this is a conversation
    final initialMessage = ConversationMessage(
      text: "Hello!",
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      isLocalUser: true,
      userId: 'local',
    );

    _conversation.add(initialMessage);

    _smartReply.addMessageToConversationFromLocalUser(
      initialMessage.text,
      initialMessage.timestamp.millisecondsSinceEpoch,
    );
  }

  void clearConversation() {
    _conversation.clear();
    _smartReply.close();
    _isInitialized = false;
    emit(
      state.copyWith(
        conversation: [],
        suggestions: [],
        isLoading: false,
        error: null,
      ),
    );
  }

  Future<void> _generateSmartReplies() async {
    if (_conversation.isEmpty) return;

    emit(state.copyWith(isLoading: true, error: null));

    try {
      final suggestions = <String>[];

      // Only generate replies if the last message (chronologically) is from a remote user
      final sortedConversation = List<ConversationMessage>.from(_conversation)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (sortedConversation.isNotEmpty &&
          !sortedConversation.last.isLocalUser) {
        final smartText = await _smartReply.suggestReplies();

        if (smartText.status == SmartReplySuggestionResultStatus.success) {
          suggestions.addAll(smartText.suggestions);
        } else if (smartText.status ==
            SmartReplySuggestionResultStatus.noReply) {
          emit(
            state.copyWith(
              suggestions: [],
              isLoading: false,
              error: 'No suitable replies found for this message',
            ),
          );
          return;
        } else if (smartText.status ==
            SmartReplySuggestionResultStatus.notSupportedLanguage) {
          emit(
            state.copyWith(
              suggestions: [],
              isLoading: false,
              error: 'Language not supported (only English is supported)',
            ),
          );
          return;
        }
      }

      emit(
        state.copyWith(
          suggestions: suggestions,
          isLoading: false,
          error: suggestions.isEmpty ? 'No smart replies generated' : null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          suggestions: [],
          isLoading: false,
          error: 'Error generating smart replies: ${e.toString()}',
        ),
      );
    }
  }

  void sendReply(String reply) {
    addMessage(reply, isLocalUser: true);
  }

  @override
  Future<void> close() {
    _smartReply.close();
    return super.close();
  }
}
