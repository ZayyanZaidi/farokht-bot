import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'farokht_bot.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id TEXT PRIMARY KEY,
        brand TEXT,
        name TEXT,
        sku TEXT,
        price REAL,
        color TEXT,
        category TEXT,
        image_url TEXT
      )
    ''');
  }

  // --- Product Operations ---

  Future<void> saveProduct(Product product) async {
    final db = await database;
    await db.insert(
      'products',
      product.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveProducts(List<Product> products) async {
    final db = await database;
    Batch batch = db.batch();
    for (var product in products) {
      batch.insert(
        'products',
        product.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromJson(maps[i]));
  }

  Future<int> getProductCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM products'));
    return count ?? 0;
  }

  Future<List<Map<String, dynamic>>> getCategoryCounts() async {
    final db = await database;
    // Categories are comma-separated strings in some items, but here we'll simplify 
    // or just return unique category strings found.
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT category as name, COUNT(*) as count FROM products GROUP BY category'
    );
    return results;
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('products');
  }
}
