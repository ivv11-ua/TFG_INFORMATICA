import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class CompareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Devuelve el UID del usuario actual
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  /// 👇 AGREGAR: Stream de productos en comparación
  Stream<List<Product>> comparedStream() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('compare')
        .orderBy('timestamp', descending: false)
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

  /// Agregar/Quitar de comparación (toggle)
  Future<void> toggleCompared(Product product, bool isComparing) async {
    if (_userId == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('compare')
        .doc(product.id);

    if (isComparing) {
      // Eliminar de comparación
      await docRef.delete();
    } else {
      // Agregar a comparación
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

  /// Cargar productos en comparación
  Future<List<Product>> loadCompared() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('compare')
          .orderBy('timestamp', descending: false)
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
      print('Error cargando productos en comparación: $e');
      return [];
    }
  }

  /// Agregar a comparación directamente
  Future<void> addCompare(String userId, Product product) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('compare')
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

  /// Eliminar de comparación directamente
  Future<void> removeCompare(String userId, String productId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('compare')
        .doc(productId)
        .delete();
  }
}
