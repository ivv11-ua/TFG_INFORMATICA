import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tfg_informatica/screens/live_products_screen.dart';
import 'package:tfg_informatica/screens/login_rquired_screen.dart';
import '../data/sample_products.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';
import '../services/favorites_service.dart';
import '../services/compare_service.dart';
import '../screens/login_rquired_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String query = '';
  String selectedCategory = 'Todos';
  final List<String> categories = ['Todos', 'Fútbol', 'Tenis', 'Running'];

  final FavoriteService favoriteService = FavoriteService();
  final CompareService compareService = CompareService();

  List<Product> favoriteProducts = [];
  List<Product> comparedProducts = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadCompared();
  }

  Future<void> _loadFavorites() async {
    final list = await favoriteService.loadFavorites();
    setState(() => favoriteProducts = list);

    favoriteService.favoritesStream().listen((list) {
      setState(() => favoriteProducts = list);
    });
  }

  Future<void> _loadCompared() async {
    final list = await compareService.loadCompared();
    setState(() => comparedProducts = list);

    compareService.comparedStream().listen((list) {
      setState(() => comparedProducts = list);
    });
  }

  Future<void> _refreshProducts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {});
  }

  void _toggleFavorite(Product product) async {
    if (FirebaseAuth.instance.currentUser == null) {
      _redirectToLoginRequired();
      return;
    }

    final isFavorite = favoriteProducts.any((p) => p.id == product.id);
    await favoriteService.toggleFavorite(product, isFavorite);
  }

  void _toggleCompare(Product product) async {
    if (FirebaseAuth.instance.currentUser == null) {
      _redirectToLoginRequired();
      return;
    }

    final isComparing = comparedProducts.any((p) => p.id == product.id);
    if (isComparing) {
      await compareService.toggleCompared(product, true);
    } else if (comparedProducts.length < 3) {
      await compareService.toggleCompared(product, false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('¡Ups! Solo puedes comparar hasta 3 productos 😅')),
            ],
          ),
          backgroundColor: Colors.deepPurpleAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _redirectToLoginRequired() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) =>  LoginRequiredScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = sampleProducts.where((product) {
      final matchesQuery =
          product.name.toLowerCase().contains(query.toLowerCase());
      final matchesCategory =
          selectedCategory == 'Todos' || product.category == selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff74ebd5), Color(0xffACB6E5)], // gradiente azul/lila
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshProducts,
            child: Column(
              children: [
                // Título arriba en blanco
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      "Sportly",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Botón productos en tiempo real
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LiveProductsScreen()),
                    );
                  },
                  child: const Text("Ver productos en tiempo real"),
                ),

                // Buscador
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
                      decoration: const InputDecoration(
                        hintText: "Buscar producto...",
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      ),
                      onChanged: (value) {
                        setState(() {
                          query = value;
                        });
                      },
                    ),
                  ),
                ),

                // Chips de categorías
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category == selectedCategory;
                      return ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        selectedColor: Colors.deepPurpleAccent,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        elevation: 4,
                        shadowColor: Colors.black45,
                        onSelected: (_) {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Grid de productos
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final isFavorite =
                          favoriteProducts.any((p) => p.id == product.id);
                      final isComparing =
                          comparedProducts.any((p) => p.id == product.id);
                      final compareIndex = isComparing
                          ? comparedProducts.indexWhere((p) => p.id == product.id) + 1
                          : null;

                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: product),
                            ),
                          );
                          if (result == true) setState(() {});
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                  child: Image.asset(
                                    product.imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("${product.price} €",
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600)),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                isFavorite
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: isFavorite ? Colors.red : null,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                _toggleFavorite(product);
                                              },
                                            ),
                                            Stack(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    isComparing
                                                        ? Icons.check_box
                                                        : Icons
                                                            .check_box_outline_blank,
                                                    color: isComparing
                                                        ? Colors.blue
                                                        : null,
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    _toggleCompare(product);
                                                  },
                                                ),
                                                if (isComparing &&
                                                    compareIndex != null)
                                                  Positioned(
                                                    right: 6,
                                                    top: 6,
                                                    child: CircleAvatar(
                                                      radius: 8,
                                                      backgroundColor: Colors.red,
                                                      child: Text(
                                                        '$compareIndex',
                                                        style: const TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold),
                                                      ),
                                                    ),
                                                  ),
                                              ],
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
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
