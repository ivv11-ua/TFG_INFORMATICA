import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class NikeProduct {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String price;
  final String productUrl;
  final String groupKey;
  final String sk;
  final Map<String, dynamic> raw;

  NikeProduct({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.price,
    required this.productUrl,
    required this.groupKey,
    required this.sk,
    required this.raw,
  });

  factory NikeProduct.fromJson(Map<String, dynamic> j) {
    return NikeProduct(
      title: j['title'] ?? '',
      subtitle: j['subtitle'] ?? '',
      imageUrl: j['image_url'] ?? '',
      price: j['price'] ?? '',
      productUrl: j['product_url'] ?? '',
      groupKey: j['group_key']?.toString() ?? '',
      sk: j['SK'] ?? '',
      raw: j,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

class NikeResponse {
  final List<NikeProduct> items;
  final String? nextToken;

  NikeResponse({required this.items, this.nextToken});
}

class NikeApi {
  static const _base = 'https://nike-api.p.rapidapi.com/get-mens-shoes';
  static const _host = 'nike-api.p.rapidapi.com';
  // Sustituye por tu clave o leer de entorno
  static const _apiKey = '9a09ea810amsha514bcfd757ec5ap122ed7jsndb7cc0219ab3';

  // Ruta absoluta donde se guardarán los .json (cámbiala si hace falta)
  static const String projectFolder = r'c:\Users\ivanv\Desktop\tfg_informatica';

  /// Fetch products. Puedes filtrar por categorías (['running','football']) y guardar JSON crudo en projectFolder.
  static Future<NikeResponse> fetchProducts({
    String? nextToken,
    List<String>? categoriesFilter,
    bool saveRawToProject = false,
    bool saveFiltered = false,
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
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.reasonPhrase}');
    }

    final bodyString = resp.body;

    // Guardar JSON crudo
    if (saveRawToProject) {
      try {
        final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
        final file = File('${projectFolder}\\nike_raw_$ts.json');
        await file.writeAsString(bodyString);
      } catch (e) {
        // no bloquear fallo de guardado
        print('Error saving raw json: $e');
      }
    }

    final Map<String, dynamic> body = json.decode(bodyString);
    final itemsJson = body['items'] as List<dynamic>? ?? [];
    var items = itemsJson.map((e) => NikeProduct.fromJson(e as Map<String, dynamic>)).toList();

    // Filtrado por categorías simples (busca keywords en title/subtitle/target/messaging)
    if (categoriesFilter != null && categoriesFilter.isNotEmpty) {
      items = items.where((p) => _matchesCategories(p, categoriesFilter)).toList();
      if (saveFiltered) {
        try {
          final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
          final file = File('${projectFolder}\\nike_filtered_${categoriesFilter.join('_')}_$ts.json');
          final filteredJson = json.encode({'items': items.map((i) => i.toJson()).toList(), 'next_token': body['next_token']});
          await file.writeAsString(filteredJson);
        } catch (e) {
          print('Error saving filtered json: $e');
        }
      }
    }

    final next = body['next_token']?.toString();
    return NikeResponse(items: items, nextToken: next);
  }

  static bool _matchesCategories(NikeProduct p, List<String> cats) {
    final hay = '${p.title} ${p.subtitle} ${p.raw['target'] ?? ''} ${p.raw['messaging'] ?? ''} ${p.groupKey}'.toLowerCase();
    final Map<String, List<String>> keywords = {
      'running': ['run', 'running', 'pegasus', 'trail', 'road', 'running shoes', 'trail'],
      'football': ['football', 'soccer', 'cleat', 'fg', 'mg', 'turf', 'futbol', 'football shoes'],
      // puedes añadir más categorías y keywords aquí
    };

    for (final cat in cats) {
      final c = cat.toLowerCase();
      final kws = keywords[c] ?? [c]; // si no hay mapping usa la propia palabra
      if (kws.any((k) => hay.contains(k))) return true;
    }
    return false;
  }
}