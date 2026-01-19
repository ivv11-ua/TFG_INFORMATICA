import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tfg_informatica/screens/main_screen.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/products_screen_api_google.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Verificar si el usuario está logueado
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sport Compare',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: isLoggedIn ? MainScreen() : LoginScreen(),
    );
  }
}
