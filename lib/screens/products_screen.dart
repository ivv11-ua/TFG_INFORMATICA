import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/nike_api.dart';
import '../services/google_api.dart';
import '../models/product.dart';
import '../services/favorites_service.dart';
import '../services/compare_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _products = [];
  bool _isLoading = false;
  String _selectedSource = 'Ninguna';
  final TextEditingController _searchController = TextEditingController();

  final Map<String, bool> _favorites = {};
  final Map<String, bool> _comparing = {};

  final FavoriteService _favoriteService = FavoriteService();
  final CompareService _compareService = CompareService();

  @override
  void initState() {
    super.initState();
    _loadFavoritesAndComparing();
  }

  Future<void> _loadFavoritesAndComparing() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final favorites = await _favoriteService.loadFavorites();
      for (var product in favorites) {
        _favorites[product.id] = true;
      }

      final comparing = await _compareService.loadCompared();
      for (var product in comparing) {
        _comparing[product.id] = true;
      }

      if (mounted) setState(() {});
    } catch (e) {
      print('Error cargando favoritos/comparaciones: $e');
    }
  }

  Future<void> _toggleFavorite(Product product) async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Debes iniciar sesión para usar favoritos'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final isFavorite = _favorites[product.id] ?? false;
      await _favoriteService.toggleFavorite(product, isFavorite);
      
      setState(() {
        _favorites[product.id] = !isFavorite;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFavorite ? '💔 Eliminado de favoritos' : '❤️ Agregado a favoritos'),
            backgroundColor: isFavorite ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleCompare(Product product) async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Debes iniciar sesión para comparar productos'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final isComparing = _comparing[product.id] ?? false;

      if (!isComparing) {
        final compareList = await _compareService.loadCompared();
        
        if (compareList.length >= 4) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Máximo 4 productos para comparar'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      await _compareService.toggleCompared(product, isComparing);
      
      setState(() {
        _comparing[product.id] = !isComparing;
      });
      
      if (mounted) {
        final compareList = await _compareService.loadCompared();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isComparing 
                ? '➖ Eliminado del comparador' 
                : '✅ Agregado al comparador (${compareList.length}/4)'
            ),
            backgroundColor: isComparing ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openProductUrl(Product product) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      final directLink = await GoogleShoppingApi.getDirectLink(product);
      
      if (mounted) Navigator.pop(context);

      if (directLink == null || directLink.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ No se encontró enlace directo a la tienda'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final uri = Uri.parse(directLink);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('✅ Enlace abierto correctamente');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No se pudo abrir el enlace'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      print('💥 Error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _searchGoogleShopping() async {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Introduce un término de búsqueda'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedSource = 'Google Shopping';
    });

    try {
      final products = await GoogleShoppingApi.fetchProducts(
        query: query,
        numResults: 20,
        saveJson: true,
      );
      
      setState(() {
        _products = products;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${products.length} productos encontrados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _searchFootballShirts() async {
    setState(() {
      _isLoading = true;
      _selectedSource = 'Google Shopping';
    });

    try {
      final products = await GoogleShoppingApi.fetchFootballShirts(
        team: 'Real Madrid',
        season: '2024/25',
        numResults: 20,
      );
      
      setState(() {
        _products = products;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${products.length} camisetas encontradas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _searchRunningShoes() async {
    setState(() {
      _isLoading = true;
      _selectedSource = 'Google Shopping';
    });

    try {
      final allProducts = await GoogleShoppingApi.fetchProducts(
        query: 'zapatillas running deporte',
        numResults: 40,
        saveJson: true,
      );
      
      final sportKeywords = [
        'running', 'correr', 'deportiv', 'nike', 'adidas', 'asics',
        'zapatillas', 'running shoes', 'trail'
      ];
      
      final filteredProducts = allProducts.where((product) {
        final nameAndDesc = '${product.name} ${product.description}'.toLowerCase();
        return sportKeywords.any((keyword) => nameAndDesc.contains(keyword));
      }).toList();
      
      final finalProducts = filteredProducts.take(20).toList();
      
      setState(() {
        _products = finalProducts;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${finalProducts.length} zapatillas de running encontradas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _searchFootballShoes() async {
    setState(() {
      _isLoading = true;
      _selectedSource = 'Google Shopping';
    });

    try {
      final allProducts = await GoogleShoppingApi.fetchProducts(
        query: 'botas futbol deporte',
        numResults: 40,
        saveJson: true,
      );
      
      final sportKeywords = [
        'futbol', 'fútbol', 'botas', 'tacos', 'deportiv', 'nike', 'adidas',
        'mercurial', 'predator', 'phantom', 'copa'
      ];
      
      final filteredProducts = allProducts.where((product) {
        final nameAndDesc = '${product.name} ${product.description}'.toLowerCase();
        return sportKeywords.any((keyword) => nameAndDesc.contains(keyword));
      }).toList();
      
      final finalProducts = filteredProducts.take(20).toList();
      
      setState(() {
        _products = finalProducts;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${finalProducts.length} botas de fútbol encontradas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _searchTennisShoes() async {
    setState(() {
      _isLoading = true;
      _selectedSource = 'Google Shopping';
    });

    try {
      final allProducts = await GoogleShoppingApi.fetchProducts(
        query: 'zapatillas tenis deporte',
        numResults: 40,
        saveJson: true,
      );
      
      final sportKeywords = [
        'tenis', 'tennis', 'deportiv', 'wilson', 'nike', 'adidas',
        'zapatillas', 'court', 'clay', 'pista'
      ];
      
      final filteredProducts = allProducts.where((product) {
        final nameAndDesc = '${product.name} ${product.description}'.toLowerCase();
        return sportKeywords.any((keyword) => nameAndDesc.contains(keyword));
      }).toList();
      
      final finalProducts = filteredProducts.take(20).toList();
      
      setState(() {
        _products = finalProducts;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${finalProducts.length} zapatillas de tenis encontradas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff74ebd5), Color(0xffACB6E5)], // 👈 MISMO QUE HOME
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header - Título en blanco
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Text(
                      '🛍️ Productos',
                      style: TextStyle(
                        fontSize: 24, // 👈 Tamaño como HOME
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // 👈 Blanco como HOME
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3), // 👈 Más visible
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _selectedSource,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Barra de búsqueda - estilo HOME
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // 👈 Fondo blanco como HOME
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar productos...',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send, color: Colors.deepPurpleAccent),
                        onPressed: _searchGoogleShopping,
                      ),
                    ),
                    onSubmitted: (_) => _searchGoogleShopping(),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Botones de acción - 4 categorías en horizontal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _searchFootballShirts,
                        icon: const Icon(Icons.sports_soccer, size: 18),
                        label: const Text('Camisetas'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: Colors.black45,
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      ElevatedButton.icon(
                        onPressed: _searchRunningShoes,
                        icon: const Icon(Icons.directions_run, size: 18),
                        label: const Text('Running'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: Colors.black45,
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      ElevatedButton.icon(
                        onPressed: _searchFootballShoes,
                        icon: const Icon(Icons.sports_soccer, size: 18),
                        label: const Text('Botas Fútbol'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: Colors.black45,
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      ElevatedButton.icon(
                        onPressed: _searchTennisShoes,
                        icon: const Icon(Icons.sports_tennis, size: 18),
                        label: const Text('Tenis'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Lista de productos
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white, // 👈 Blanco como HOME
                          strokeWidth: 3,
                        ),
                      )
                    : _products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 80,
                                  color: Colors.white.withOpacity(0.7), // 👈 Más visible
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'No hay productos',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Usa la búsqueda o los botones de arriba',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              final isFavorite = _favorites[product.id] ?? false;
                              final isComparing = _comparing[product.id] ?? false;
                              
                              return _buildProductCard(
                                product,
                                isFavorite,
                                isComparing,
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isFavorite, bool isComparing) {
    return GestureDetector(
      onTap: () => _openProductUrl(product),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen del producto
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            // Información del producto
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título del producto
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // 👇 NOMBRE DE LA TIENDA AQUÍ (entre título y precio)
                  if (product.raw?['source'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.deepPurpleAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        product.raw?['source'] ?? 'Tienda',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurpleAccent[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  
                  const SizedBox(height: 6),
                  
                  // Precio y botones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botón Favorito
                          IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : null,
                              size: 20,
                            ),
                            onPressed: () => _toggleFavorite(product),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28), // 👈 Más pequeño
                          ),
                          // 👇 SIN ESPACIO (antes era SizedBox)
                          // Botón Comparar
                          IconButton(
                            icon: Icon(
                              isComparing ? Icons.check_box : Icons.check_box_outline_blank,
                              color: isComparing ? Colors.blue : null,
                              size: 20,
                            ),
                            onPressed: () => _toggleCompare(product),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28), // 👈 Más pequeño
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}