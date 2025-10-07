import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class GoogleShoppingApi {
  static const String _baseUrl = 'https://serpapi.com/search';
  static const String _apiKey = '85f4f5976755bc353dc497e1496b1ef597c6e51b51c8d5d1e04fa12c2cd8353a';
  static const String projectFolder = r'c:\Users\ivanv\Desktop\tfg_informatica';

  /// Busca productos en Google Shopping
  /// 
  /// [query] - Término de búsqueda (ej: "camiseta Real Madrid")
  /// [numResults] - Número de resultados a obtener (default: 20)
  /// [country] - Código del país (default: "es")
  /// [language] - Código del idioma (default: "es")
  /// [saveJson] - Guardar resultados en JSON (default: true)
  static Future<List<Product>> fetchProducts({
    required String query,
    int numResults = 20,
    String country = 'es',
    String language = 'es',
    bool saveJson = true,
    bool saveRaw = false,
  }) async {
    try {
      print('🔍 Buscando en Google Shopping: "$query"');
      
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'engine': 'google_shopping',
          'q': query,
          'api_key': _apiKey,
          'hl': language,
          'gl': country,
          'num': numResults.toString(),
        },
      );

      final headers = {
        'Accept': 'application/json',
      };

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

      final bodyString = response.body;

      if (saveRaw) {
        await _saveRawJson(bodyString, query);
      }

      final Map<String, dynamic> body = json.decode(bodyString);
      
      final shoppingResults = body['shopping_results'] as List<dynamic>?;
      
      if (shoppingResults == null || shoppingResults.isEmpty) {
        print('⚠️ No se encontraron resultados para: "$query"');
        return [];
      }

      final products = shoppingResults
          .map((item) => Product.fromGoogleShopping(item as Map<String, dynamic>))
          .toList();

      print('✅ Encontrados ${products.length} productos');

      if (saveJson) {
        await _saveProductsJson(products, query);
      }

      return products;

    } catch (e) {
      print('❌ Error en fetchProducts: $e');
      rethrow;
    }
  }

  /// Busca camisetas de fútbol
  static Future<List<Product>> fetchFootballShirts({
    required String team,
    String? season,
    String? size,
    int numResults = 20,
  }) async {
    String query = 'camiseta $team oficial';
    if (season != null) query += ' $season';
    if (size != null) query += ' talla $size';

    return fetchProducts(
      query: query,
      numResults: numResults,
    );
  }

  /// Busca zapatillas deportivas
  static Future<List<Product>> fetchSneakers({
    required String brand,
    String? model,
    String? size,
    int numResults = 20,
  }) async {
    String query = 'zapatillas $brand';
    if (model != null) query += ' $model';
    if (size != null) query += ' talla $size';

    return fetchProducts(
      query: query,
      numResults: numResults,
    );
  }

  /// Guarda el JSON crudo
  static Future<void> _saveRawJson(String jsonString, String query) async {
    try {
      final dir = Directory(projectFolder);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final cleanQuery = query.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\s-]'), '');
      final file = File('$projectFolder\\google_shopping_raw_${cleanQuery}_$timestamp.json');
      
      await file.writeAsString(jsonString);
      print('💾 JSON crudo guardado en: ${file.path}');
    } catch (e) {
      print('⚠️ Error guardando JSON crudo: $e');
    }
  }

  /// Guarda los productos en JSON
  static Future<void> _saveProductsJson(List<Product> products, String query) async {
    try {
      final dir = Directory(projectFolder);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final cleanQuery = query.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\s-]'), '');
      final file = File('$projectFolder\\google_shopping_products_${cleanQuery}_$timestamp.json');
      
      final jsonString = json.encode(
        products.map((p) => p.toMap()).toList(),
      );
      
      await file.writeAsString(jsonString);
      print('💾 Productos guardados en: ${file.path}');
    } catch (e) {
      print('⚠️ Error guardando productos: $e');
    }
  }

  /// 👇 CORREGIDO: Obtener enlace de stores
  static Future<String?> getDirectLink(Product product) async {
    try {
      final immersiveToken = product.raw?['immersive_product_page_token'] as String?;
      
      if (immersiveToken == null) {
        print('⚠️ No hay immersive_product_page_token disponible');
        final productLink = product.raw?['product_link'] as String?;
        if (productLink != null) {
          print('⚠️ Usando product_link como fallback');
          return productLink;
        }
        return null;
      }

      print('🔗 Obteniendo enlace directo con immersive token...');
      
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'engine': 'google_immersive_product',
          'page_token': immersiveToken,
          'api_key': _apiKey,
          'hl': 'es',
          'gl': 'es',
        },
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        print('⚠️ Error HTTP ${response.statusCode}');
        
        final productLink = product.raw?['product_link'] as String?;
        if (productLink != null) {
          print('⚠️ Usando product_link como fallback');
          return productLink;
        }
        return null;
      }

      final body = json.decode(response.body);
      
      // 👇 BUSCAR EN stores[0].link
      final productResults = body['product_results'] as Map<String, dynamic>?;
      if (productResults != null) {
        final stores = productResults['stores'] as List<dynamic>?;
        if (stores != null && stores.isNotEmpty) {
          final firstStore = stores[0] as Map<String, dynamic>;
          final link = firstStore['link'] as String?;
          if (link != null) {
            print('✅ Enlace encontrado: $link');
            return link;
          }
        }
      }

      // Fallback: product_link
      final productLink = product.raw?['product_link'] as String?;
      if (productLink != null) {
        print('⚠️ Usando product_link como fallback');
        return productLink;
      }

      print('⚠️ No se encontró enlace directo');
      return null;

    } catch (e) {
      print('❌ Error en getDirectLink: $e');
      
      try {
        final productLink = product.raw?['product_link'] as String?;
        if (productLink != null) {
          print('⚠️ Usando product_link como último recurso');
          return productLink;
        }
      } catch (_) {}
      
      return null;
    }
  }

  static double _parsePrice(dynamic priceData) {
    if (priceData == null) return 0.0;
    if (priceData is num) return priceData.toDouble();
    if (priceData is String) {
      final cleanPrice = priceData
          .replaceAll('€', '')
          .replaceAll('\$', '')
          .replaceAll(',', '.')
          .replaceAll(' ', '')
          .trim();
      return double.tryParse(cleanPrice) ?? 0.0;
    }
    return 0.0;
  }
}
