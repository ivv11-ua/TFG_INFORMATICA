import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Devuelve el UID del usuario actual
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  /// 👇 AGREGAR: Stream de favoritos
  Stream<List<Product>> favoritesStream() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('favorites')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: data['id'] ?? doc.id,
          name: data['name'] ?? 'Sin nombre',
          category: data['category'] ?? 'General',
          description: data['description'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          imageUrl: data['imageUrl'] ?? '',
          productUrl: data['productUrl'],
          raw: data['raw'],
        );
      }).toList();
    });
  }

  /// Agregar/Quitar favorito (toggle)
  Future<void> toggleFavorite(Product product, bool isFavorite) async {
    if (_userId == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('favorites')
        .doc(product.id);

    if (isFavorite) {
      // Eliminar de favoritos
      await docRef.delete();
    } else {
      // Agregar a favoritos
      await docRef.set({
        'id': product.id,
        'name': product.name,
        'category': product.category,
        'description': product.description,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'productUrl': product.productUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'raw': product.raw,
      });
    }
  }

  /// Cargar todos los favoritos
  Future<List<Product>> loadFavorites() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: data['id'] ?? doc.id,
          name: data['name'] ?? 'Sin nombre',
          category: data['category'] ?? 'General',
          description: data['description'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          imageUrl: data['imageUrl'] ?? '',
          productUrl: data['productUrl'],
          raw: data['raw'],
        );
      }).toList();
    } catch (e) {
      print('Error cargando favoritos: $e');
      return [];
    }
  }

  /// Verificar si un producto es favorito
  Future<bool> isFavorite(String productId) async {
    if (_userId == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('favorites')
        .doc(productId)
        .get();

    return doc.exists;
  }

  /// Agregar favorito directamente
  Future<void> addFavorite(String userId, Product product) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(product.id)
        .set({
      'id': product.id,
      'name': product.name,
      'category': product.category,
      'description': product.description,
      'price': product.price,
      'imageUrl': product.imageUrl,
      'productUrl': product.productUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'raw': product.raw,
    });
  }

  /// Eliminar favorito directamente
  Future<void> removeFavorite(String userId, String productId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(productId)
        .delete();
  }
}
