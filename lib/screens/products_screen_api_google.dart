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

  // Filtros y ordenamiento
  String _sortOrder = 'none'; // 'none', 'price_asc', 'price_desc'
  String _priceRange = 'all'; // 'all', '0-50', '50-100', '100-200', '200+'

  final Map<String, bool> _favorites = {};
  final Map<String, bool> _comparing = {};

  final FavoriteService _favoriteService = FavoriteService();
  final CompareService _compareService = CompareService();

  @override
  void initState() {
    super.initState();
    _loadFavoritesAndComparing();
  }

  // Función para obtener productos filtrados y ordenados
  List<Product> get _filteredProducts {
    List<Product> filtered = List.from(_products);

    // Aplicar filtro de rango de precio
    if (_priceRange != 'all') {
      filtered = filtered.where((product) {
        switch (_priceRange) {
          case '0-50':
            return product.price >= 0 && product.price <= 50;
          case '50-100':
            return product.price > 50 && product.price <= 100;
          case '100-200':
            return product.price > 100 && product.price <= 200;
          case '200+':
            return product.price > 200;
          default:
            return true;
        }
      }).toList();
    }

    // Aplicar ordenamiento
    if (_sortOrder == 'price_asc') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortOrder == 'price_desc') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    }

    return filtered;
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

  Future<void> _searchRunning() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await GoogleShoppingApi.fetchProducts(
        query: 'zapatillas running nike adidas asics',
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
            content: Text('✅ ${products.length} productos de running encontrados'),
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

  Future<void> _searchTraining() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await GoogleShoppingApi.fetchProducts(
        query: 'ropa entrenamiento gym fitness',
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
            content: Text('✅ ${products.length} productos de entrenamiento encontrados'),
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

  Future<void> _searchFootball() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await GoogleShoppingApi.fetchProducts(
        query: 'botas futbol nike adidas puma',
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
            content: Text('✅ ${products.length} productos de fútbol encontrados'),
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

  Future<void> _searchBasketball() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await GoogleShoppingApi.fetchProducts(
        query: 'zapatillas baloncesto nike jordan',
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
            content: Text('✅ ${products.length} productos de baloncesto encontrados'),
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

  Future<void> _searchPadel() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await GoogleShoppingApi.fetchProducts(
        query: 'pala padel bullpadel adidas',
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
            content: Text('✅ ${products.length} productos de pádel encontrados'),
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

  Future<void> _searchTennis() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await GoogleShoppingApi.fetchProducts(
        query: 'raqueta tenis wilson head',
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
            content: Text('✅ ${products.length} productos de tenis encontrados'),
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

  void _showFiltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Ordenar por
            const Text(
              'Ordenar por',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            RadioListTile<String>(
              title: const Text('Relevancia: Mejor resultado'),
              value: 'none',
              groupValue: _sortOrder,
              activeColor: Colors.deepPurpleAccent,
              onChanged: (value) {
                setState(() => _sortOrder = value!);
              },
            ),
            RadioListTile<String>(
              title: const Text('Precio: Menor a mayor'),
              value: 'price_asc',
              groupValue: _sortOrder,
              activeColor: Colors.deepPurpleAccent,
              onChanged: (value) {
                setState(() => _sortOrder = value!);
              },
            ),
            RadioListTile<String>(
              title: const Text('Precio: Mayor a menor'),
              value: 'price_desc',
              groupValue: _sortOrder,
              activeColor: Colors.deepPurpleAccent,
              onChanged: (value) {
                setState(() => _sortOrder = value!);
              },
            ),
            
            const Divider(height: 32),
            
            // Filtrar por precio
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtrar por precio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Switch(
                  value: _priceRange != 'all',
                  activeColor: Colors.deepPurpleAccent,
                  onChanged: (value) {
                    setState(() {
                      _priceRange = value ? '0-50' : 'all';
                    });
                  },
                ),
              ],
            ),
            
            if (_priceRange != 'all') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _priceRange,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurpleAccent),
                  items: const [
                    DropdownMenuItem(value: '0-50', child: Text('0€ - 50€')),
                    DropdownMenuItem(value: '50-100', child: Text('50€ - 100€')),
                    DropdownMenuItem(value: '100-200', child: Text('100€ - 200€')),
                    DropdownMenuItem(value: '200+', child: Text('200€ +')),
                  ],
                  onChanged: (value) {
                    setState(() => _priceRange = value!);
                  },
                ),
              ),
            ],
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
                padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Productos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Barra de búsqueda con icono de filtros
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                        icon: const Icon(Icons.tune, color: Colors.deepPurpleAccent),
                        onPressed: _showFiltersModal,
                      ),
                    ),
                    onSubmitted: (_) => _searchGoogleShopping(),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Botones de acción - 6 categorías en horizontal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _searchRunning,
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
                        onPressed: _searchTraining,
                        icon: const Icon(Icons.fitness_center, size: 18),
                        label: const Text('Entrenamiento'),
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
                        onPressed: _searchFootball,
                        icon: const Icon(Icons.sports_soccer, size: 18),
                        label: const Text('Fútbol'),
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
                        onPressed: _searchBasketball,
                        icon: const Icon(Icons.sports_basketball, size: 18),
                        label: const Text('Baloncesto'),
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
                        onPressed: _searchPadel,
                        icon: const Icon(Icons.sports_tennis, size: 18),
                        label: const Text('Pádel'),
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
                        onPressed: _searchTennis,
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

              const SizedBox(height: 12),

              // Contador de productos filtrados
              if (_products.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${_filteredProducts.length} de ${_products.length} productos',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              if (_products.isNotEmpty) const SizedBox(height: 8),

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
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
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