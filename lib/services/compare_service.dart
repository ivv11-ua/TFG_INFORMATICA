import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class CompareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Devuelve el UID del usuario actual
  String _userId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    return user.uid;
  }

  /// Referencia a la colección de comparados del usuario
  CollectionReference<Map<String, dynamic>> get _compared {
    return _firestore.collection('users').doc(_userId()).collection('compared');
  }

  /// Cargar productos comparados
  Future<List<Product>> loadCompared() async {
    try {
      final snapshot = await _compared.get();
      return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error cargando productos comparados: $e');
      return [];
    }
  }

  /// Stream para escuchar cambios en tiempo real
  Stream<List<Product>> comparedStream() {
    return _compared.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList(),
    );
  }

  /// Añadir o eliminar producto comparado
  Future<void> toggleCompared(Product product, bool isCompared) async {
    try {
      final docRef = _compared.doc(product.id);
      if (isCompared) {
        await docRef.delete();
      } else {
        await docRef.set(product.toMap());
      }
    } catch (e) {
      print('Error toggling compared: $e');
    }
  }
}
