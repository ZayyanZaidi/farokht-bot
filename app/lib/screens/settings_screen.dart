import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../main.dart';


class SettingsScreen extends StatefulWidget {
  final VoidCallback? onClearChat;

  const SettingsScreen({super.key, this.onClearChat});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  String _selectedLang = 'auto';
  bool _notifications = true;
  bool _isDarkMode = false;
  bool _isSyncing = false;
  bool _isServerHealthy = false;
  bool _isCheckingHealth = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlController.text = ApiService.baseUrl;
      _selectedLang = prefs.getString('lang_preference') ?? 'auto';
      _notifications = prefs.getBool('notifications') ?? true;
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    });
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    setState(() => _isCheckingHealth = true);
    final healthy = await ApiService.isServerHealthy();
    if (mounted) {
      setState(() {
        _isServerHealthy = healthy;
        _isCheckingHealth = false;
      });
    }
  }

  Future<void> _saveUrl() async {
    await ApiService.setBaseUrl(_urlController.text.trim());
    _checkHealth();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Server URL updated'),
          backgroundColor: const Color(0xFF5CE1E6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _saveLang(String langCode, AppLanguage lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang_preference', langCode);
    setState(() {
      _selectedLang = langCode;
      LocalizationService.currentLanguage = lang;
    });
  }

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);
    final success = await ApiService.triggerSync();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Product sync started!' : 'Sync failed — is the server running?'),
          backgroundColor: success ? const Color(0xFF4CAF50) : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildServerSection(),
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
          BoxShadow(color: const Color(0xFF5CE1E6).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
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
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
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

  Widget _buildServerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Server Connection', Icons.cloud_outlined),
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
              // Status row
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _isCheckingHealth
                          ? Colors.amber
                          : (_isServerHealthy ? const Color(0xFF4CAF50) : Colors.red),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isCheckingHealth
                        ? 'Checking...'
                        : (_isServerHealthy ? 'Connected' : 'Disconnected'),
                    style: TextStyle(
                      color: _isCheckingHealth
                          ? Colors.amber[800]
                          : (_isServerHealthy ? const Color(0xFF4CAF50) : Colors.red),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _checkHealth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5CE1E6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Test',
                        style: TextStyle(
                          color: Color(0xFF5CE1E6),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // URL input
              TextField(
                controller: _urlController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Server URL',
                  labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                  hintText: 'http://10.0.2.2:8000',
                  hintStyle: TextStyle(color: Colors.grey[300]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF5CE1E6), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save_rounded, color: Color(0xFFFF8C00)),
                    onPressed: _saveUrl,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
            color: isSelected ? null : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            boxShadow: isSelected ? [
              BoxShadow(color: const Color(0xFF5CE1E6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
            ] : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                    color: const Color(0xFF5CE1E6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5CE1E6)),
                        )
                      : const Icon(Icons.sync_rounded, color: Color(0xFF5CE1E6), size: 20),
                ),
                title: const Text('Sync Products', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text('Fetch latest from Farokht API', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: _isSyncing ? null : _triggerSync,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
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
    _urlController.dispose();
    super.dispose();
  }
}
