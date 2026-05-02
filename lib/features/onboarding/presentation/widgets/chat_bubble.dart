import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isAi = message.sender == ChatSender.ai;

    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isAi ? AppColors.primaryLight : AppColors.primaryDark,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          message.text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isAi ? AppColors.textPrimary : Colors.white,
              ),
        ),
      ),
    );
  }
}
