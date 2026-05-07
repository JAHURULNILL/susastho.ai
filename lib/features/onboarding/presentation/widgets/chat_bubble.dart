import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/chat_message.dart';

class ChatBubble extends StatefulWidget {
  const ChatBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAi = widget.message.sender == ChatSender.ai;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Align(
          alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.82,
            ),
            decoration: BoxDecoration(
              gradient: isAi
                  ? null
                  : const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF144D2F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: isAi ? Colors.white : null,
              borderRadius: isAi
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                      bottomLeft: Radius.circular(4),
                    )
                  : const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(4),
                    ),
              border: isAi
                  ? Border.all(color: AppColors.border.withValues(alpha: 0.7), width: 1)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: isAi
                      ? AppColors.primaryDark.withValues(alpha: 0.04)
                      : AppColors.primary.withValues(alpha: 0.14),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              widget.message.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isAi ? AppColors.textPrimary : Colors.white,
                    height: 1.35,
                    fontWeight: isAi ? FontWeight.w500 : FontWeight.w600,
                    fontSize: 15,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
