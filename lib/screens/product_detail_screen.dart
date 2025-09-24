import 'package:flutter/material.dart';
import '../models/product.dart';
import '../data/favorites.dart';
import '../data/compare.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  ProductDetailScreen({required this.product});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isFavorite = favoriteProducts.contains(product);
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            product.imageUrl,
                            fit: BoxFit.cover,
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
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
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
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                              label: Text(isFavorite ? "Quitar Favorito" : "Añadir Favorito"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isFavorite) {
                                    favoriteProducts.remove(product);
                                  } else {
                                    favoriteProducts.add(product);
                                  }
                                });
                                Navigator.pop(context, true); // <-- AVISA a HomeScreen
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(isCompared ? Icons.check_box : Icons.check_box_outline_blank),
                              label: Text(isCompared ? "En Comparador" : "Añadir Comparador"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isCompared) {
                                    compareProducts.remove(product);
                                  } else if (compareProducts.length < 3) {
                                    compareProducts.add(product);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Máximo 3 productos para comparar'),
                                      ),
                                    );
                                  }
                                });
                                Navigator.pop(context, true); // <-- AVISA a HomeScreen
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
