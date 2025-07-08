import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/smart_reply_cubit.dart';
import '../models/conversation_message.dart';

class SmartReplyView extends StatefulWidget {
  const SmartReplyView({super.key});

  @override
  State<SmartReplyView> createState() => _SmartReplyViewState();
}

class _SmartReplyViewState extends State<SmartReplyView> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Reply'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              context.read<SmartReplyCubit>().clearConversation();
            },
            tooltip: 'Clear',
          ),
        ],
      ),
      body: BlocBuilder<SmartReplyCubit, SmartReplyState>(
        builder: (context, state) {
          return Column(
            children: [
              // Status card at the top
              Container(
                padding: const EdgeInsets.all(16),
                child: _SmartReplyStatusCard(),
              ),

              // Chat history - takes up most of the space
              Expanded(child: _ConversationHistoryView()),

              // Smart reply suggestions as chips
              _SmartReplySuggestionsChips(),

              // Input field at the bottom
              _MessageInputCard(),
            ],
          );
        },
      ),
    );
  }
}

/// Status card showing smart reply state
class _SmartReplyStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SmartReplyCubit, SmartReplyState>(
      builder: (context, state) {
        String statusText;
        Color statusColor;
        IconData statusIcon;
        bool showLoading = false;

        if (state.isLoading) {
          statusText = 'Generating smart replies...';
          statusColor = Colors.orange;
          statusIcon = Icons.psychology;
          showLoading = true;
        } else if (state.error != null) {
          statusText = state.error!;
          statusColor = Colors.red;
          statusIcon = Icons.error;
        } else if (state.suggestions.isNotEmpty) {
          statusText = 'Smart replies generated (${state.suggestions.length})';
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
        } else if (state.conversation.isNotEmpty) {
          statusText = 'No smart replies available';
          statusColor = Colors.grey;
          statusIcon = Icons.chat_bubble_outline;
        } else {
          statusText = 'Ready to generate smart replies';
          statusColor = Colors.blue;
          statusIcon = Icons.psychology;
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

/// Message input card
class _MessageInputCard extends StatefulWidget {
  @override
  State<_MessageInputCard> createState() => _MessageInputCardState();
}

class _MessageInputCardState extends State<_MessageInputCard> {
  final TextEditingController _controller = TextEditingController();
  bool _isRemoteUser = true; // Default to remote user to generate replies

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      if (_isRemoteUser) {
        // Send as remote user to generate smart replies
        context.read<SmartReplyCubit>().addNewMessage(message);
      } else {
        // Send as local user (your reply)
        context.read<SmartReplyCubit>().addMessage(message, isLocalUser: true);
      }
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User type selector - more compact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Send as:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _isRemoteUser = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _isRemoteUser ? Colors.orange : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: _isRemoteUser ? Colors.white : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Remote',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isRemoteUser ? Colors.white : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _isRemoteUser = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: !_isRemoteUser ? Colors.blue : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: !_isRemoteUser ? Colors.white : Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'You',
                          style: TextStyle(
                            fontSize: 12,
                            color: !_isRemoteUser ? Colors.white : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Input field with send button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  maxLines: 3,
                  minLines: 1,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                onPressed: _sendMessage,
                mini: true,
                backgroundColor: _isRemoteUser ? Colors.orange : Colors.blue,
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Conversation history card
class _ConversationHistoryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SmartReplyCubit, SmartReplyState>(
      builder: (context, state) {
        if (state.conversation.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Start a conversation to see smart replies',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: state.conversation.length,
          itemBuilder: (context, index) {
            final message = state.conversation[index];
            return _MessageBubble(message: message);
          },
        );
      },
    );
  }
}

/// Individual message bubble
class _MessageBubble extends StatelessWidget {
  final ConversationMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isLocalUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
        children: [
          if (!message.isLocalUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.orange.withOpacity(0.2),
              child: const Icon(
                Icons.person_outline,
                size: 16,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isLocalUser ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isLocalUser ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (message.isLocalUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.withOpacity(0.2),
              child: const Icon(Icons.person, size: 16, color: Colors.blue),
            ),
          ],
        ],
      ),
    );
  }
}

/// Smart reply suggestions as chips
class _SmartReplySuggestionsChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SmartReplyCubit, SmartReplyState>(
      builder: (context, state) {
        if (state.suggestions.isEmpty && !state.isLoading) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.isLoading)
                const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Generating suggestions...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                )
              else if (state.suggestions.isNotEmpty) ...[
                const Text(
                  'Smart Replies:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      state.suggestions.map((suggestion) {
                        return ActionChip(
                          label: Text(suggestion),
                          onPressed: () {
                            // Add the suggestion as a local user message
                            context.read<SmartReplyCubit>().addMessage(
                              suggestion,
                              isLocalUser: true,
                            );
                          },
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          labelStyle: const TextStyle(color: Colors.blue),
                          side: const BorderSide(color: Colors.blue),
                        );
                      }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
