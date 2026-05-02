import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Initial greeting based on current language
    _messages.add(
      ChatMessage(
        text: LocalizationService.tr('greeting_init'),
        isUser: false,
        timestamp: _currentTime(),
      ),
    );
  }

  String _currentTime() {
    return intl.DateFormat('hh:mm a').format(DateTime.now());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void clearMessages() {
    setState(() {
      _messages.clear();
      _messages.add(
        ChatMessage(
          text: "Chat cleared. How can I help you now?",
          isUser: false,
          timestamp: _currentTime(),
        ),
      );
    });
  }

  Future<void> sendInitialQuery(String query) async {
    _textController.text = query;
    await _sendMessage();
  }

  Future<void> _handleImageSelection() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) _sendMessage(imagePath: image.path);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) _sendMessage(imagePath: image.path);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendMessage({String? imagePath}) async {
    final text = _textController.text.trim();
    if (text.isEmpty && imagePath == null) return;

    _textController.clear();
    
    File? imageFile = imagePath != null ? File(imagePath) : null;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: _currentTime(),
        imageAttachment: imageFile,
      ));
      _isTyping = true;
    });
    
    _scrollToBottom();

    // Show searching indicator message
    final searchingMsgIndex = _messages.length;
    setState(() {
      _messages.add(ChatMessage(
        text: "",
        isUser: false,
        timestamp: _currentTime(),
        isSearching: true,
      ));
    });
    
    _scrollToBottom();

    try {
      final lang = LocalizationService.getLangCode();
      final response = await ApiService.sendMessage(text, imageFile, lang: lang);
      
      setState(() {
        // Remove searching message
        _messages.removeAt(searchingMsgIndex);
        
        // Add actual response
        _messages.add(ChatMessage(
          text: response['reply'],
          isUser: false,
          timestamp: _currentTime(),
          suggestedProducts: response['products'],
        ));
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.removeAt(searchingMsgIndex);
        _messages.add(ChatMessage(
          text: "Error connecting to server.",
          isUser: false,
          timestamp: _currentTime(),
        ));
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = LocalizationService.isRtl();
    
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white.withOpacity(0.1),
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Hero(
                tag: 'bot-avatar',
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF5CE1E6), Color(0xFFFF8C00)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Farokht AI",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 16
                    ),
                  ),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(
                        "Always here to help",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), 
                          fontSize: 10
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFFF8C00)),
              onPressed: clearMessages,
            ),
          ],
        ),
        body: Stack(
          children: [
            // 1. Base Gradient (Adaptive)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.light
                      ? [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)]
                      : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                ),
              ),
            ),
            // 2. Decorative Floating Orbs
            _buildOrb(top: -100, right: -100, size: 300, color: const Color(0xFF5CE1E6).withOpacity(0.1)),
            _buildOrb(bottom: 200, left: -100, size: 350, color: const Color(0xFFFF8C00).withOpacity(0.08)),
            
            // 3. The Actual Content
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return ChatBubble(message: _messages[index]);
                      },
                    ),
                  ),
                  _buildQuickReplies(),
                  _buildMessageInput(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrb({double? top, double? bottom, double? left, double? right, required double size, required Color color}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF5CE1E6)),
                  onPressed: _handleImageSelection,
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: LocalizationService.tr('chat_hint'),
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                GestureDetector(
                  onTap: () => _sendMessage(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFFF8C00).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReplies() {
    final suggestions = [
      LocalizationService.tr('suggest_clothes'),
      LocalizationService.tr('suggest_kurtas'),
      LocalizationService.tr('suggest_trending'),
    ];

    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(suggestions[index], style: const TextStyle(fontSize: 12, color: Colors.white)),
              backgroundColor: const Color(0xFFFF8C00).withOpacity(0.8),
              onPressed: () => sendInitialQuery(suggestions[index]),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }
}
