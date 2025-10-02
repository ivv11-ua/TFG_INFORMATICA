import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Devuelve el UID del usuario actual
  String _userId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    return user.uid;
  }

  /// Referencia a la colección de favoritos del usuario
  CollectionReference<Map<String, dynamic>> get _favorites {
    return _firestore.collection('users').doc(_userId()).collection('favorites');
  }

  /// Cargar favoritos actuales
  Future<List<Product>> loadFavorites() async {
    try {
      final snapshot = await _favorites.get();
      return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error cargando favoritos: $e');
      return [];
    }
  }

  /// Stream para escuchar cambios en tiempo real
  Stream<List<Product>> favoritesStream() {
    return _favorites.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList(),
    );
  }

  /// Añadir o eliminar favorito
  Future<void> toggleFavorite(Product product, bool isFavorite) async {
    try {
      final docRef = _favorites.doc(product.id);
      if (isFavorite) {
        await docRef.delete();
      } else {
        await docRef.set(product.toMap());
      }
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }
}
