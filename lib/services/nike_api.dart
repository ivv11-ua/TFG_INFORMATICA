import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/product.dart'; // Importa tu modelo unificado

class NikeApi {
  static const _base = 'https://nike-api.p.rapidapi.com/get-mens-shoes';
  static const _host = 'nike-api.p.rapidapi.com';
  static const _apiKey = 'kaka';
  static const String projectFolder = r'c:\Users\ivanv\Desktop\tfg_informatica';

  /// Devuelve directamente una lista de Product
  static Future<List<Product>> fetchProducts({
    String? nextToken,
    List<String>? categoriesFilter,
    bool saveRawToProject = false,
    bool saveFiltered = false,
    bool saveProductsJson = true, // <-- NUEVO: guardar productos en JSON
  }) async {
    final uri = Uri.parse(_base).replace(
      queryParameters: nextToken != null ? {'next_token': nextToken} : null,
    );

    final headers = {
      'x-rapidapi-host': _host,
      'x-rapidapi-key': _apiKey,
      'Accept': 'application/json',
    };

    final resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}: ${resp.reasonPhrase}');

    final bodyString = resp.body;

    // Guardar JSON crudo
    if (saveRawToProject) {
      try {
        final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
        final file = File('${projectFolder}\\nike_raw_$ts.json');
        await file.writeAsString(bodyString);
      } catch (e) {
        print('Error saving raw json: $e');
      }
    }

    final Map<String, dynamic> body = json.decode(bodyString);
    final itemsJson = body['items'] as List<dynamic>? ?? [];

    // Convertimos a Product
    var products = itemsJson.map((e) => Product.fromNike(e as Map<String, dynamic>)).toList();

    // Filtrado opcional por categorías
    if (categoriesFilter != null && categoriesFilter.isNotEmpty) {
      products = products.where((p) => _matchesCategories(p, categoriesFilter)).toList();

      if (saveFiltered) {
        try {
          final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
          final file = File('${projectFolder}\\nike_filtered_${categoriesFilter.join('_')}_$ts.json');
          final filteredJson = json.encode({'items': products.map((p) => p.toMap()).toList()});
          await file.writeAsString(filteredJson);
        } catch (e) {
          print('Error saving filtered json: $e');
        }
      }
    }

    // GUARDAR TODOS LOS PRODUCTOS EN JSON
    if (saveProductsJson) {
      try {
        final dir = Directory(projectFolder);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
        final file = File('${projectFolder}\\nike_products_$ts.json');
        final jsonString = json.encode(products.map((p) => p.toMap()).toList());
        await file.writeAsString(jsonString);
        print('Productos guardados en: ${file.path}');
      } catch (e) {
        print('Error guardando JSON de productos: $e');
      }
    }

    return products;
  }

  static bool _matchesCategories(Product p, List<String> cats) {
    final hay = '${p.name} ${p.description} ${p.raw?['target'] ?? ''} ${p.raw?['messaging'] ?? ''}'.toLowerCase();
    final Map<String, List<String>> keywords = {
      'running': ['run', 'running', 'pegasus', 'trail', 'road', 'running shoes'],
      'football': ['football', 'soccer', 'cleat', 'fg', 'mg', 'turf', 'futbol'],
    };

    for (final cat in cats) {
      final kws = keywords[cat.toLowerCase()] ?? [cat.toLowerCase()];
      if (kws.any((k) => hay.contains(k))) return true;
    }
    return false;
  }
}
