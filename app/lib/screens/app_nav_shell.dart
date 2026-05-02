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
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        onStartChat: () => _switchToChat(),
        onCategoryTap: (cat) => _switchToChat(initialQuery: cat),
      ),
      ChatScreen(key: _chatKey),
      SettingsScreen(onClearChat: _clearChatHistory),
    ];
  }

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

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 85,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5CE1E6).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.transparent,
            selectedItemColor: const Color(0xFFFF8C00),
            unselectedItemColor: Colors.grey[400],
            selectedFontSize: 12,
            unselectedFontSize: 11,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _currentIndex == 0 ? const Color(0xFFFF8C00).withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _currentIndex == 1 ? const Color(0xFFFF8C00).withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_currentIndex == 1 ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline),
                ),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _currentIndex == 2 ? const Color(0xFFFF8C00).withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_currentIndex == 2 ? Icons.settings_rounded : Icons.settings_outlined),
                ),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
