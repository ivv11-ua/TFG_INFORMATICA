class Product {
  final String id;
  final String name;
  final String category;
  final String description;
  final double price;
  final String imageUrl;
  final String? productUrl;
  final Map<String, dynamic>? raw;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.productUrl,
    this.raw,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      productUrl: map['productUrl'],
      raw: map['raw'] != null ? Map<String, dynamic>.from(map['raw']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
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
      description: np['subtitle'] ?? '',
      price: price,
      imageUrl: np['image_url'] ?? '',
      productUrl: np['product_url'] ?? '',
      raw: np,
    );
  }

  /// 👇 CORREGIDO: Usar 'link' para el enlace directo a la tienda
  factory Product.fromGoogleShopping(Map<String, dynamic> gs) {
    // Extraer precio
    double price = 0.0;
    try {
      final extractedPrice = gs['extracted_price'];
      if (extractedPrice != null) {
        price = (extractedPrice is int) 
            ? extractedPrice.toDouble() 
            : double.tryParse(extractedPrice.toString()) ?? 0.0;
      }
    } catch (e) {
      final priceStr = gs['price']?.toString() ?? '0';
      price = double.tryParse(priceStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    }

    // Extraer categoría basada en el título
    String category = _detectCategory(gs['title'] ?? '');

    // 👇 CORREGIDO: Priorizar 'link' (enlace directo) sobre 'product_link' (búsqueda Google)
    String? productUrl;
    if (gs['link'] != null && gs['link'].toString().isNotEmpty) {
      productUrl = gs['link'].toString();
    } else if (gs['product_link'] != null && gs['product_link'].toString().isNotEmpty) {
      productUrl = gs['product_link'].toString();
    }

    // 👇 EXTRAER SOURCE (nombre de la tienda)
    String source = 'Tienda';
    if (gs['source'] != null) {
      source = gs['source'].toString();
    } else if (gs['link'] != null) {
      // Extraer de la URL si no hay source
      try {
        final uri = Uri.parse(gs['link']);
        final domain = uri.host.replaceAll('www.', '');
        
        if (domain.contains('amazon')) source = 'Amazon';
        else if (domain.contains('nike')) source = 'Nike';
        else if (domain.contains('adidas')) source = 'Adidas';
        else if (domain.contains('decathlon')) source = 'Decathlon';
        else if (domain.contains('sprinter')) source = 'Sprinter';
        else if (domain.contains('elcorteingles')) source = 'El Corte Inglés';
        else if (domain.contains('jdsports')) source = 'JD Sports';
        else if (domain.contains('futbolemotion')) source = 'Futbolemotion';
        else source = domain.split('.').first.toUpperCase();
      } catch (e) {
        source = 'Tienda';
      }
    }

    return Product(
      id: gs['position']?.toString() ?? 
          gs['product_id']?.toString() ?? 
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: gs['title'] ?? 'Sin título',
      category: category,
      description: gs['source'] ?? gs['snippet'] ?? '', // Nombre de la tienda
      price: price,
      imageUrl: gs['thumbnail'] ?? '',
      productUrl: productUrl, // 👈 AHORA USA 'link' primero
      raw: {
        ...gs,
        'source': source,  // 👈 GUARDAR EL SOURCE AQUÍ
      },
    );
  }

  /// Detecta la categoría basándose en keywords del título
  static String _detectCategory(String title) {
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('camiseta') || 
        lowerTitle.contains('jersey') || 
        lowerTitle.contains('shirt')) {
      return 'Camisetas';
    }
    
    if (lowerTitle.contains('zapatilla') || 
        lowerTitle.contains('sneaker') || 
        lowerTitle.contains('shoe')) {
      return 'Zapatillas';
    }
    
    if (lowerTitle.contains('pantalon') || 
        lowerTitle.contains('pant') || 
        lowerTitle.contains('short')) {
      return 'Pantalones';
    }
    
    if (lowerTitle.contains('running') || lowerTitle.contains('correr')) {
      return 'Running';
    }
    
    if (lowerTitle.contains('futbol') || 
        lowerTitle.contains('football') || 
        lowerTitle.contains('soccer')) {
      return 'Fútbol';
    }
    
    return 'General';
  }
}
