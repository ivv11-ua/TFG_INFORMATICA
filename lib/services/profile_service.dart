import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tfg_informatica/screens/login_screen.dart';

class ProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// UID actual
  static String _userId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuario no autenticado");
    return user.uid;
  }

  /// Guardar datos de perfil en Firestore
  static Future<void> saveProfile(EditProfileResult result) async {
    try {
      String? base64Image;
      if (result.imagen != null) {
        final bytes = await result.imagen!.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      await _firestore.collection("users").doc(_userId()).set({
        "name": result.nombre.isNotEmpty ? result.nombre : null,
        "email": FirebaseAuth.instance.currentUser?.email ?? "",
        "phone": result.telefono.isNotEmpty ? result.telefono : null,
        "address": result.direccion.isNotEmpty ? result.direccion : null,
        "imageBase64": base64Image,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error guardando perfil: $e");
    }
  }

  /// Cargar datos de perfil desde Firestore
  static Future<Map<String, dynamic>?> loadProfile() async {
    try {
      final snapshot = await _firestore.collection("users").doc(_userId()).get();
      return snapshot.data();
    } catch (e) {
      print("Error cargando perfil: $e");
      return null;
    }
  }

  /// Cerrar sesión
  static Future<void> logout(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        for (final info in user.providerData) {
          if (info.providerId == 'google.com') {
            await GoogleSignIn().signOut();
          }
        }
      }
      await FirebaseAuth.instance.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);

      Navigator.of(context).pop();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cerrar sesión')),
      );
    }
  }

  /// Seleccionar foto desde galería
  static Future<File?> seleccionarFoto() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      return File(picked.path);
    }
    return null;
  }
}

/// Clase auxiliar para devolver resultado de edición
class EditProfileResult {
  final String nombre;
  final String telefono;
  final String direccion;
  final File? imagen;
  EditProfileResult(this.nombre, this.telefono, this.direccion, this.imagen);
}
