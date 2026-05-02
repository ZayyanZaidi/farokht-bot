import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/localization_service.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onClearChat;

  const SettingsScreen({super.key, this.onClearChat});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLang = 'auto';
  bool _notifications = true;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLang = prefs.getString('lang_preference') ?? 'auto';
      _notifications = prefs.getBool('notifications') ?? true;
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    });
  }

  Future<void> _saveLang(String langCode, AppLanguage lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang_preference', langCode);
    setState(() {
      _selectedLang = langCode;
      LocalizationService.currentLanguage = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildLanguageSection(),
            _buildNotificationsSection(),
            _buildDataSection(),
            _buildAboutSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5CE1E6), Color(0xFF3DC8CD), Color(0xFFFF8C00)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF5CE1E6).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.settings_rounded, color: Colors.white, size: 44),
          const SizedBox(height: 16),
          const Text(
            'Settings & Sync',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            'Personalize your Farokht Assistant',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF8C00), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLanguageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Language', Icons.translate),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.light ? 0.04 : 0.2),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _langOption('English', 'en', AppLanguage.en),
                  _langOption('اردو', 'ur', AppLanguage.ur),
                  _langOption('Roman', 'ur_roman', AppLanguage.urRoman),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _langOption('سنڌي', 'sd', AppLanguage.sd),
                  _langOption('پښتو', 'ps', AppLanguage.ps),
                  _langOption('پنجابی', 'pa', AppLanguage.pa),
                  _langOption('بلوچی', 'bal', AppLanguage.bal),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _langOption(String label, String value, AppLanguage lang) {
    final isSelected = _selectedLang == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _saveLang(value, lang),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: [Color(0xFF5CE1E6), Color(0xFFFF8C00)])
                : null,
            color: isSelected ? null : Colors.grey.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(15),
            boxShadow: isSelected ? [
              BoxShadow(color: const Color(0xFF5CE1E6).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
            ] : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Preferences', Icons.tune_rounded),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.light ? 0.04 : 0.2),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text('Receive product alerts', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                value: _notifications,
                activeColor: const Color(0xFFFF8C00),
                onChanged: (val) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('notifications', val);
                  setState(() => _notifications = val);
                },
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                title: const Text('Dark Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text('Easy on the eyes', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                value: _isDarkMode,
                activeColor: const Color(0xFFFF8C00),
                onChanged: (val) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('is_dark_mode', val);
                  themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                  setState(() => _isDarkMode = val);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),

      ],
    );
  }

  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Data', Icons.storage_rounded),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.light ? 0.04 : 0.2),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5CE1E6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: Color(0xFF5CE1E6), size: 20),
                ),
                title: const Text('Auto-Sync Enabled', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: const Text(
                  'Products are automatically synced from the cloud backend.', 
                  style: TextStyle(fontSize: 12, color: Colors.grey)
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 20),
                ),
                title: const Text('Clear Chat History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text('Remove all chat messages', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Clear Chat?'),
                      content: const Text('This will remove all messages. This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            widget.onClearChat?.call();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Chat history cleared'),
                                backgroundColor: const Color(0xFFFF8C00),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          child: const Text('Clear', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('About', Icons.info_outline_rounded),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.light ? 0.04 : 0.2),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5CE1E6), Color(0xFFFF8C00)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Farokht Bot',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'AI-powered product recommendation chatbot with bilingual support (English & Roman Urdu). Built with Flutter & FastAPI.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
