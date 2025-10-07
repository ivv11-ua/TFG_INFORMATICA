import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 Para comprobar login
import '../screens/login_rquired_screen.dart'; // 👈 Pantalla intermedia
import '../models/product.dart';
import '../services/favorites_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  ProductDetailScreen({required this.product});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final FavoriteService favoriteService = FavoriteService();
  List<Product> favoriteProducts = [];
  List<Product> compareProducts = [];
  
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() async {
    final list = await favoriteService.loadFavorites();
    setState(() => favoriteProducts = list);

    favoriteService.favoritesStream().listen((list) {
      setState(() => favoriteProducts = list);
    });
  }

  void _toggleFavorite(Product product) async {
    final isFavorite = favoriteProducts.any((p) => p.id == product.id);
    await favoriteService.toggleFavorite(product, isFavorite);
  }

  /// 🔐 Verifica si el usuario está autenticado
  bool _isLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  void _requireLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginRequiredScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isFavorite = favoriteProducts.any((p) => p.id == product.id);
    final isCompared = compareProducts.contains(product);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff74ebd5), Color(0xffACB6E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                expandedHeight: 250,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Hero(
                          tag: product.id,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: product.imageUrl.isNotEmpty
                                ? Image.network(
                                    product.imageUrl,
                                    height: 300,
                                    width: double.infinity,
                                    fit: BoxFit.contain,  // 👈 CAMBIO AQUÍ (antes era cover)
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 300,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          size: 80,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 300,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    height: 300,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Categoría: ${product.category}",
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Precio: ${product.price} €",
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        product.description,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border),
                              label: Text(
                                  isFavorite ? "Quitar Favorito" : "Añadir Favorito"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                if (!_isLoggedIn()) {
                                  _requireLogin();
                                  return;
                                }
                                _toggleFavorite(product);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(isCompared
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank),
                              label: Text(isCompared
                                  ? "En Comparador"
                                  : "Añadir Comparador"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                if (!_isLoggedIn()) {
                                  _requireLogin();
                                  return;
                                }
                                setState(() {
                                  if (isCompared) {
                                    compareProducts.remove(product);
                                  } else if (compareProducts.length < 3) {
                                    compareProducts.add(product);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Máximo 3 productos para comparar')),
                                    );
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
