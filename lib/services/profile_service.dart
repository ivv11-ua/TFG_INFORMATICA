// profile_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tfg_informatica/screens/login_screen.dart';
import 'dart:io';
import '../screens/profile_screen.dart';

class ProfileService {
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
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cerrar sesión')));
    }
  }

  // Abrir editor de perfil completo
  static Future<EditProfileResult?> editarPerfilCompleto(
      BuildContext context,
      String currentName,
      String currentPhone,
      String currentAddress,
      File? currentImage) async {
    final TextEditingController nameController =
        TextEditingController(text: currentName);
    final TextEditingController phoneController =
        TextEditingController(text: currentPhone);
    final TextEditingController addressController =
        TextEditingController(text: currentAddress);
    File? newImage = currentImage;

    EditProfileResult? resultado;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Editar Perfil",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setModalState(() {
                          newImage = File(picked.path);
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: newImage != null ? FileImage(newImage!) : null,
                      child: newImage == null
                          ? const Icon(Icons.camera_alt, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Nombre",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: "Teléfono",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: "Dirección",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      resultado = EditProfileResult(
                        nameController.text,
                        phoneController.text,
                        addressController.text,
                        newImage,
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text("Guardar cambios"),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );

    return resultado;
  }

  // Seleccionar foto desde galería
  static Future<File?> seleccionarFoto() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      return File(picked.path);
    }
    return null;
  }
}
