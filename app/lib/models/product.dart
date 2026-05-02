class Product {
  final String id;
  final String brand;
  final String name;
  final String sku;
  final double price;
  final String? color;
  final String category;
  final String imageUrl;

  Product({
    required this.id,
    required this.brand,
    required this.name,
    required this.sku,
    required this.price,
    this.color,
    required this.category,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      brand: json['brand'],
      name: json['name'],
      sku: json['sku'],
      price: json['price'].toDouble(),
      color: json['color'],
      category: json['category'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'name': name,
      'sku': sku,
      'price': price,
      'color': color,
      'category': category,
      'image_url': imageUrl,
    };
  }
}
