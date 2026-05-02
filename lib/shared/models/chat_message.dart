enum ChatSender {
  ai,
  user,
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.sender,
  });

  final String text;
  final ChatSender sender;
}
