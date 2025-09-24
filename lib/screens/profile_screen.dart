// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:tfg_informatica/services/profile_service.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String nombre = "Juan Pérez";
  String email = "juan.perez@email.com";
  String telefono = "+34 123 456 789";
  String direccion = "Calle Falsa 123, Ciudad, País";
  File? imagenPerfil;

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
              expandedHeight: 350, //ESTO TIRA LA FOTO PARA ABAJO
              pinned: true,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              title: const Text(
                "Mi Perfil",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => ProfileService.logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text("Cerrar sesión"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 5,
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), // mucho más pequeño

                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
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
                            GestureDetector(
                              onTap: () async {
                                final nuevaFoto =
                                    await ProfileService.seleccionarFoto();
                                if (nuevaFoto != null) {
                                  setState(() {
                                    imagenPerfil = nuevaFoto;
                                  });
                                }
                              },
                              child: CircleAvatar(
                                radius: 80,
                                backgroundColor: Colors.white,
                                backgroundImage: imagenPerfil != null
                                    ? FileImage(imagenPerfil!)
                                    : null,
                                child: imagenPerfil == null
                                    ? Text(
                                        nombre.substring(0, 1),
                                        style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              nombre,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              email,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              telefono,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              direccion,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final resultado = await ProfileService.editarPerfilCompleto(
                          context, nombre, telefono, direccion, imagenPerfil);
                      if (resultado != null) {
                        setState(() {
                          nombre = resultado.nombre;
                          telefono = resultado.telefono;
                          direccion = resultado.direccion;
                          if (resultado.imagen != null) {
                            imagenPerfil = resultado.imagen;
                          }
                        });
                      }
                    },
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

// Clase auxiliar para devolver resultado de edición
class EditProfileResult {
  final String nombre;
  final String telefono;
  final String direccion;
  final File? imagen;
  EditProfileResult(this.nombre, this.telefono, this.direccion, this.imagen);
}
