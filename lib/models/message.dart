enum MessageStatus { sending, sent, read, failed }

class Message {
  const Message({
    required this.id,
    required this.chatId,
    required this.text,
    required this.senderName,
    required this.isOutgoing,
    required this.time,
    this.status = MessageStatus.sent,
  });

  final String id;
  final String chatId;
  final String text;
  final String senderName;
  final bool isOutgoing;
  final DateTime time;
  final MessageStatus status;
}
