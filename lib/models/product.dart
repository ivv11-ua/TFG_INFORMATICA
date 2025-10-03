class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  final String description;
  final String? productUrl; // URL opcional para productos externos
  final Map<String, dynamic>? raw; // datos originales para referencia

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.description,
    this.productUrl,
    this.raw,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      productUrl: map['productUrl'],
      raw: map['raw'] != null ? Map<String, dynamic>.from(map['raw']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'productUrl': productUrl,
      'raw': raw,
    };
  }

  /// Aqui convierto cada JSON de nike en un Product
  factory Product.fromNike(Map<String, dynamic> np) {
    final priceStr = np['price']?.toString() ?? '0';
    final price = double.tryParse(priceStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;

    return Product(
      id: np['SK'] ?? '',
      name: np['title'] ?? '',
      category: '', // opcional: mapear según keywords
      price: price,
      imageUrl: np['image_url'] ?? '',
      description: np['subtitle'] ?? '',
      productUrl: np['product_url'] ?? '',
      raw: np,
    );
  }
}
