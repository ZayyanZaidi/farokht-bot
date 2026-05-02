import 'dart:io';
import 'product.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String timestamp;
  final File? imageAttachment;
  final List<Product>? suggestedProducts;
  final bool isSearching;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageAttachment,
    this.suggestedProducts,
    this.isSearching = false,
  });
}
