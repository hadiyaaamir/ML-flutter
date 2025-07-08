import 'package:equatable/equatable.dart';

class ConversationMessage extends Equatable {
  const ConversationMessage({
    required this.text,
    required this.timestamp,
    required this.isLocalUser,
    this.userId,
  });

  final String text;
  final DateTime timestamp;
  final bool isLocalUser;
  final String? userId;

  @override
  List<Object?> get props => [text, timestamp, isLocalUser, userId];

  ConversationMessage copyWith({
    String? text,
    DateTime? timestamp,
    bool? isLocalUser,
    String? userId,
  }) {
    return ConversationMessage(
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isLocalUser: isLocalUser ?? this.isLocalUser,
      userId: userId ?? this.userId,
    );
  }
}
