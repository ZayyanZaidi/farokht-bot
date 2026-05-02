import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../models/product.dart';
import '../widgets/animated_background.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onStartChat;
  final Function(String)? onCategoryTap;

  const HomeScreen({super.key, required this.onStartChat, this.onCategoryTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _productCount = 0;
  List<Map<String, dynamic>> _categories = [];
  bool _isOnline = false;
  Timer? _refreshTimer;
  late AnimationController _pulseController;

  // State for products
  List<Product> _allProducts = [];

  @override
  void initState() {
    super.initState();
    // Delay initial load to let network stabilize
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _loadStats();
        _startAutoRefresh();
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadStats(isAuto: true);
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStats({bool isAuto = false}) async {
    if (!isAuto && mounted) setState(() {});
    
    try {
      bool healthy = false;
      try { healthy = await ApiService.isServerHealthy(); } catch (_) {}

      Map<String, dynamic> stats = {'product_count': 0, 'categories': []};
      try { stats = await ApiService.getStats(); } catch (_) {}

      List<Product> products = [];
      try { products = await ApiService.getProducts(limit: 20); } catch (_) {}

      List<Map<String, dynamic>> logs = [];
      try { logs = await ApiService.getLiveActivity(); } catch (_) {}
      
      // Extract categories from products for variety
      final Map<String, int> catMap = {};
      for (var p in products) {
        final catsList = p.category.split(', ');
        for (var c in catsList) {
          final trimmed = c.trim();
          if (trimmed.isNotEmpty) catMap[trimmed] = (catMap[trimmed] ?? 0) + 1;
        }
      }
      
      List<Map<String, dynamic>> cats = catMap.entries.map((e) => {
        'name': e.key, 
        'count': e.value
      }).toList();
      
      // If no products were found, use categories from stats
      if (cats.isEmpty && stats['categories'] != null) {
        final List<dynamic> statCats = stats['categories'] as List;
        cats = statCats.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
      
      if (mounted) {
        setState(() {
          _isOnline = healthy || products.isNotEmpty || stats['status'] == 'healthy';
          _productCount = stats['product_count'] ?? 0;
          _allProducts = products;
          _categories = cats;
        });
      }
    } catch (e) {
      print('HomeScreen: Unexpected error in _loadStats: $e');
      if (mounted) setState(() {
        _isOnline = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = LocalizationService.isRtl();
    
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedBackground(
          child: RefreshIndicator(
            color: const Color(0xFFFF8C00),
            onRefresh: _loadStats,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                _buildLanguageBarSliver(),
                _buildStatsSliver(),
                _buildHeroSliderSliver(),
                _buildCategoriesSliver(),
                _buildProductGridSliver(),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF5CE1E6).withValues(alpha: 0.2), 
                const Color(0xFF5CE1E6).withOpacity(0)
              ],
            ),
          ),
        ),
      ),
      title: Container(
        height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF5CE1E6).withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search products on Farokht...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF5CE1E6)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageBarSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _buildLanguageBar(),
      ),
    );
  }

  Widget _buildStatsSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            _buildOnlineStatus(),
            const Spacer(),
            Text(
              '$_productCount items available',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light ? Colors.black54 : Colors.white70, 
                fontSize: 12, 
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSliderSliver() {
    return SliverToBoxAdapter(
      child: Container(
        height: 220,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: PageView(
          children: [
            _buildPromoCard(
              "Summer Collection 2024",
              "Up to 50% Off on Kurtas",
              "https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&q=80&w=1000",
            ),
            _buildPromoCard(
              "New Arrivals: Tech",
              "Premium Gadgets for You",
              "https://images.unsplash.com/photo-1491933382434-500287f9b54b?auto=format&fit=crop&q=80&w=1000",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard(String title, String subtitle, String imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.8), BlendMode.darken),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 24,
            left: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
              ],
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Hero(
              tag: 'bot-avatar',
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSliver() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              LocalizationService.tr('categories'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return _categoryChip(cat['name'], cat['count']);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGridSliver() {
    if (_allProducts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 60),
              const SizedBox(height: 16),
              Text('Searching for products...', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final p = _allProducts[index];
            return TweenAnimationBuilder(
              duration: Duration(milliseconds: 400 + (index % 5) * 100),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: child,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(Theme.of(context).brightness == Brightness.light ? 0.9 : 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                  boxShadow: Theme.of(context).brightness == Brightness.light 
                    ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                    : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(
                          p.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.brand, style: TextStyle(color: const Color(0xFF5CE1E6), fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            p.name, 
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 13, 
                              color: Theme.of(context).colorScheme.onSurface
                            ), 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.price > 0 ? 'Rs. ${p.price.toStringAsFixed(0)}' : 'Price on Request', 
                            style: const TextStyle(color: Color(0xFFFF8C00), fontWeight: FontWeight.bold, fontSize: 12)
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: _allProducts.length,
        ),
      ),
    );
  }

  Widget _categoryChip(String name, int count) {
    final Map<String, IconData> categoryIcons = {
      'kurta': Icons.checkroom,
      'bag': Icons.shopping_bag_outlined,
      'dessert': Icons.cake_outlined,
      'snack': Icons.fastfood_outlined,
      'shoes': Icons.directions_walk,
      'jewelry': Icons.diamond_outlined,
      'cosmetics': Icons.brush_outlined,
    };

    final Map<String, Color> categoryColors = {
      'kurta': const Color(0xFFE91E63),
      'bag': const Color(0xFF9C27B0),
      'dessert': const Color(0xFFFF5722),
      'snack': const Color(0xFF4CAF50),
      'shoes': const Color(0xFF2196F3),
      'jewelry': const Color(0xFFFFD700),
      'cosmetics': const Color(0xFFE91E63),
    };

    final color = categoryColors[name.toLowerCase()] ?? const Color(0xFF5CE1E6);
    final icon = categoryIcons[name.toLowerCase()] ?? Icons.label_outline;

    return GestureDetector(
      onTap: () {
        if (widget.onCategoryTap != null) {
          widget.onCategoryTap!(name);
        }
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light 
            ? Colors.white 
            : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: Theme.of(context).brightness == Brightness.light 
            ? [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$count items',
              style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.white.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _isOnline ? Colors.white.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isOnline ? const Color(0xFF4CAF50) : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isOnline ? 'Online' : (_productCount > 0 ? 'Offline (Local)' : 'Offline'),
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageBar() {
    final langs = [
      {'label': 'EN', 'code': AppLanguage.en},
      {'label': 'اردو', 'code': AppLanguage.ur},
      {'label': 'Roman', 'code': AppLanguage.urRoman},
      {'label': 'سنڌي', 'code': AppLanguage.sd},
      {'label': 'پښتو', 'code': AppLanguage.ps},
      {'label': 'پنجابی', 'code': AppLanguage.pa},
      {'label': 'بلوچی', 'code': AppLanguage.bal},
    ];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: langs.length,
        itemBuilder: (context, index) {
          final isSelected = LocalizationService.currentLanguage == langs[index]['code'];
          return GestureDetector(
            onTap: () {
              setState(() {
                LocalizationService.currentLanguage = langs[index]['code'] as AppLanguage;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  langs[index]['label'] as String,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF5CE1E6) : Colors.white,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}

extension WidgetEntryExtension on Widget {
  Widget animateEntry(int delayIndex) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (delayIndex * 150)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: this,
    );
  }
}
