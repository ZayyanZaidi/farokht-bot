import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import 'database_service.dart';

class ApiService {
  // Default URL — updated after cloud deployment
  static const String _defaultUrl = 'https://farokht-bot-backend-784756226072.us-central1.run.app';
  static String _baseUrl = _defaultUrl;

  static String get baseUrl => _baseUrl;

  /// Load saved server URL from SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('server_url') ?? _defaultUrl;
  }

  /// Update and persist the server URL
  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _baseUrl);
  }

  /// Send a chat message (with optional image) to the backend
  static Future<Map<String, dynamic>> sendMessage(String message, File? imageFile, {String lang = 'auto'}) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/chat'));
      request.fields['message'] = message;
      request.fields['lang'] = lang;

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List<Product> products = [];
        if (data['products'] != null) {
          products = (data['products'] as List)
              .map((item) => Product.fromJson(item))
              .toList();
        }
        return {
          'reply': data['reply'],
          'products': products,
        };
      } else {
        return {
          'reply': 'Sorry, I encountered a server error.',
          'products': <Product>[],
        };
      }
    } catch (e) {
      return {
        'reply': 'Could not connect to the server. Is it running?',
        'products': <Product>[],
      };
    }
  }

  /// Fetch stats (product count + categories) for the home screen
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/stats'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    
    // Fallback to local DB
    final count = await DatabaseService().getProductCount();
    final categories = await DatabaseService().getCategoryCounts();
    return {'product_count': count, 'categories': categories, 'status': 'offline'};
  }

  /// Fetch product catalog
  static Future<List<Product>> getProducts({int limit = 10}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/products?limit=$limit'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = (data['products'] as List)
            .map((item) => Product.fromJson(item))
            .toList();
            
        // Save to local DB for persistence
        if (products.isNotEmpty) {
          await DatabaseService().saveProducts(products);
        }
        
        return products;
      }
    } catch (_) {}
    
    // Fallback to local DB
    return await DatabaseService().getAllProducts();
  }

  /// Trigger a background product sync on the backend
  static Future<bool> triggerSync() async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/sync_trigger'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Get current sync status from backend
  static Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/sync_status'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {'status': 'error', 'items_synced': 0, 'progress': 0, 'total_pages': 0};
  }

  /// Health check
  static Future<bool> isServerHealthy() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetch live activity logs
  static Future<List<Map<String, dynamic>>> getLiveActivity() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/live_activity'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['logs'] ?? []);
      }
    } catch (_) {}
    return [];
  }
}
