import 'package:flutter/material.dart';
import '../data/sample_products.dart';
import '../models/product.dart';
import '../data/favorites.dart';
import '../data/compare.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String query = '';
  String selectedCategory = 'Todos';
  final List<String> categories = ['Todos', 'Fútbol', 'Tenis', 'Running'];

  Future<void> _refreshProducts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {}); // Refresca la UI
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
            colors: [Color(0xff74ebd5), Color(0xffACB6E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshProducts,
            child: Column(
              children: [
                // 🔝 Barra de app
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: const [
                      Text(
                        "Sport Compare",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // 🔍 Buscador
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                // 📂 Chips de categorías
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

                // 📋 Lista de productos
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final isFavorite = favoriteProducts.contains(product);
                      final isComparing = compareProducts.contains(product);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 5,
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(product.imageUrl,
                                width: 60, height: 60, fit: BoxFit.cover),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("${product.price} €"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ❤️ Favorito con animación
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: IconButton(
                                  key: ValueKey(isFavorite),
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : null,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (isFavorite) {
                                        favoriteProducts.remove(product);
                                      } else {
                                        favoriteProducts.add(product);
                                      }
                                    });
                                  },
                                ),
                              ),
                              // 🔄 Comparar con badge
                              Stack(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isComparing
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      color: isComparing ? Colors.blue : null,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (isComparing) {
                                          compareProducts.remove(product);
                                        } else if (compareProducts.length < 3) {
                                          compareProducts.add(product);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Máximo 3 productos para comparar'),
                                            ),
                                          );
                                        }
                                      });
                                    },
                                  ),
                                  if (isComparing)
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: CircleAvatar(
                                        radius: 8,
                                        backgroundColor: Colors.red,
                                        child: Text(
                                          '${compareProducts.indexOf(product) + 1}',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(product: product),
                              ),
                            );

                            if (result == true) {
                              setState(() {}); // Refresca la UI si cambió
                            }
                          },
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
