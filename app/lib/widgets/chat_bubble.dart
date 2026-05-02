import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import 'product_carousel.dart';
import 'bot_avatar.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    bool isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.text.isNotEmpty || message.imageAttachment != null)
            Row(
              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isUser) ...[
                  // Bot Avatar (Cute Shopping Bag Mascot)
                  const BotAvatar(size: 40),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isUser 
                          ? Theme.of(context).cardColor 
                          : const Color(0xFFFF8C00), // User card color, Bot orange
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (message.imageAttachment != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                message.imageAttachment!,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        if (message.text.isNotEmpty)
                          Text(
                            message.text,
                            style: TextStyle(
                              color: isUser 
                                  ? Theme.of(context).colorScheme.onSurface 
                                  : Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          message.timestamp,
                          style: TextStyle(
                            color: isUser 
                                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6) 
                                : Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
          // If searching indicator is on
          if (message.isSearching)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 40.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12, 
                      height: 12, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF8C00))
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Searching...", 
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      )
                    ),
                  ],
                ),
              ),
            ),

            
          // Suggested products
          if (message.suggestedProducts != null && message.suggestedProducts!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: ProductCarousel(products: message.suggestedProducts!),
            ),
        ],
      ),
    );
  }
}
