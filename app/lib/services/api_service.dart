import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import 'database_service.dart';

class ApiService {
  // Default URL — updated after cloud deployment
  static const String _defaultUrl = String.fromEnvironment('BACKEND_URL', defaultValue: 'https://farokht-bot-backend-784756226072.us-central1.run.app');
  static String _baseUrl = _defaultUrl;

  static String get baseUrl => _baseUrl;

  /// Load saved server URL from SharedPreferences
  static Future<void> init() async {
    // We now enforce the cloud backend URL to ensure direct data loading
    _baseUrl = _defaultUrl;
    debugPrint('ApiService: Initialized with backend URL: $_baseUrl');
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
      debugPrint('ApiService: Fetching stats from $_baseUrl/stats');
      final response = await http.get(Uri.parse('$_baseUrl/stats'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Only return if it actually contains data, otherwise fallback
        if ((data['product_count'] ?? 0) > 0) {
          return data;
        }
      }
    } catch (e) {
      debugPrint('ApiService: Stats error: $e');
    }
    
    // Fallback to local DB
    final count = await DatabaseService().getProductCount();
    final categories = await DatabaseService().getCategoryCounts();
    return {'product_count': count, 'categories': categories, 'status': 'offline'};
  }

  /// Fetch product catalog
  static Future<List<Product>> getProducts({int limit = 10}) async {
    try {
      debugPrint('ApiService: Fetching products from $_baseUrl/products?limit=$limit');
      final response = await http.get(Uri.parse('$_baseUrl/products?limit=$limit'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> prodList = data['products'] ?? [];
        final products = prodList
            .map((item) => Product.fromJson(item))
            .toList();
            
        if (products.isNotEmpty) {
          debugPrint('ApiService: Loaded ${products.length} products');
          // Save to local DB for persistence
          DatabaseService().saveProducts(products).catchError((e) {
            debugPrint('ApiService: Background save failed: $e');
          });
          return products;
        }
      }
    } catch (e) {
      debugPrint('ApiService: Products fetch error: $e');
    }
    
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
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetch live activity logs
  static Future<List<Map<String, dynamic>>> getLiveActivity() async {
    try {
      debugPrint('ApiService: Fetching activity from $_baseUrl/live_activity');
      final response = await http.get(Uri.parse('$_baseUrl/live_activity'))
          .timeout(const Duration(seconds: 15));
      debugPrint('ApiService: Activity response code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['logs'] ?? []);
      }
    } catch (e) {
      debugPrint('ApiService: Activity error: $e');
    }
    return [];
  }
}
