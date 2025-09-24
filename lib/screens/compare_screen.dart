import 'package:flutter/material.dart';
import '../data/compare.dart';
import '../models/product.dart';

class CompareScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
          child: compareProducts.isEmpty
              ? const Center(
                  child: Text(
                    "No hay productos seleccionados para comparar",
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Row(
                    children: compareProducts.map((product) {
                      return Container(
                        width: 250,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Colors.white70],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: AssetImage(product.imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                product.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Categoría: ${product.category}",
                                style: const TextStyle(
                                    color: Colors.black54, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Precio: ${product.price} €",
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                product.description,
                                style: const TextStyle(
                                    color: Colors.black54, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ),
    );
  }
}
