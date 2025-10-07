import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tfg_informatica/services/profile_service.dart';
import 'package:tfg_informatica/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String nombre = "Bienvenido usuario!";
  String email = "";
  String telefono = "";
  String direccion = "";
  File? imagenPerfil;
  Uint8List? _imagenBytes;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoggedIn = false;
        nombre = "Bienvenido usuario!";
        email = "";
        telefono = "";
        direccion = "";
        _imagenBytes = null;
        imagenPerfil = null;
      });
      return;
    }

    final doc =
        await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      Uint8List? imagenBytes;
      if (data["imageBase64"] != null) {
        imagenBytes = base64Decode(data["imageBase64"]);
      }

      setState(() {
        _isLoggedIn = true;
        nombre = data["name"] != null && data["name"].toString().isNotEmpty
            ? "Bienvenido ${data["name"]}!"
            : "Bienvenido usuario!";
        email = data["email"] ?? user.email ?? "";
        telefono = data["phone"] ?? "";
        direccion = data["address"] ?? "";
        _imagenBytes = imagenBytes;
      });
    } else {
      setState(() {
        _isLoggedIn = true;
        nombre = "Bienvenido usuario!";
        email = user.email ?? "";
      });
    }
  }

  Future<void> _editarPerfil() async {
    if (!_isLoggedIn) return; // si no está logueado, no edita
    final nameController = TextEditingController(
        text: nombre.replaceFirst("Bienvenido ", ""));
    final phoneController = TextEditingController(text: telefono);
    final addressController = TextEditingController(text: direccion);
    File? newImage = imagenPerfil;

    final resultado = await showModalBottomSheet<EditProfileResult>(
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
                  const Text("Editar Perfil",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picked = await ProfileService.seleccionarFoto();
                      if (picked != null) {
                        setModalState(() {
                          newImage = picked;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          newImage != null ? FileImage(newImage!) : null,
                      child: newImage == null
                          ? const Icon(Icons.camera_alt, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                        labelText: "Nombre", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                        labelText: "Teléfono", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                        labelText: "Dirección", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(EditProfileResult(
                        nameController.text,
                        phoneController.text,
                        addressController.text,
                        newImage,
                      ));
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

    if (resultado != null) {
      await ProfileService.saveProfile(resultado);
      setState(() {
        nombre = "Bienvenido ${resultado.nombre}!";
        telefono = resultado.telefono;
        direccion = resultado.direccion;
        if (resultado.imagen != null) {
          imagenPerfil = resultado.imagen;
          _imagenBytes = null;
        }
      });
    }
  }

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
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 350,
              pinned: true,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              title: const Text("Mi Perfil",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _isLoggedIn
                      ? ElevatedButton.icon(
                          onPressed: () => ProfileService.logout(context),
                          icon: const Icon(Icons.logout),
                          label: const Text("Cerrar sesión"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 5,
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            );
                          },
                          icon: const Icon(Icons.login),
                          label: const Text("Iniciar sesión"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 5,
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xff74ebd5), Color(0xffACB6E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Container(color: Colors.black.withOpacity(0.4)),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 80,
                              backgroundColor: Colors.white,
                              backgroundImage: _imagenBytes != null
                                  ? MemoryImage(_imagenBytes!)
                                  : (imagenPerfil != null
                                      ? FileImage(imagenPerfil!)
                                      : null),
                              child: (_imagenBytes == null &&
                                      imagenPerfil == null)
                                  ? Text(
                                      nombre.isNotEmpty
                                          ? nombre.substring(10, 11)
                                          : "?",
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Text(nombre,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            if (_isLoggedIn) ...[
                              Text(email,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 5),
                              Text(telefono,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                              Text(direccion,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoggedIn)
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _editarPerfil,
                      icon: const Icon(Icons.edit),
                      label: const Text("Editar Perfil"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
