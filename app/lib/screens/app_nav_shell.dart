import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class AppNavShell extends StatefulWidget {
  const AppNavShell({super.key});

  @override
  State<AppNavShell> createState() => _AppNavShellState();
}

class _AppNavShellState extends State<AppNavShell> {
  int _currentIndex = 0;
  final GlobalKey<ChatScreenState> _chatKey = GlobalKey<ChatScreenState>();

  void _switchToChat({String? initialQuery}) {
    setState(() => _currentIndex = 1);
    if (initialQuery != null && initialQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _chatKey.currentState?.sendInitialQuery(initialQuery);
      });
    }
  }

  void _clearChatHistory() {
    _chatKey.currentState?.clearMessages();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onStartChat: () => _switchToChat(),
        onCategoryTap: (cat) => _switchToChat(initialQuery: cat),
      ),
      ChatScreen(key: _chatKey),
      SettingsScreen(onClearChat: _clearChatHistory),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4)),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFFFF8C00),
            unselectedItemColor: Colors.grey[400],
            selectedFontSize: 12,
            unselectedFontSize: 11,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Icon(_currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(_currentIndex == 1 ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(_currentIndex == 2 ? Icons.settings_rounded : Icons.settings_outlined),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
