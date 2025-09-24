import '../models/product.dart';

final List<Product> sampleProducts = [
  Product(
    id: '1',
    name: 'Balón de Fútbol Adidas',
    category: 'Fútbol',
    price: 29.99,
    imageUrl: 'assets/balon_adidas.png',
    description: 'Balón oficial tamaño 5 con alta durabilidad.',
  ),
  Product(
    id: '2',
    name: 'Raqueta de Tenis Wilson',
    category: 'Tenis',
    price: 89.99,
    imageUrl: 'assets/raqueta_wilson.png',
    description: 'Raqueta ligera de grafito para un mejor control.',
  ),
  Product(
    id: '3',
    name: 'Zapatillas Running Nike',
    category: 'Running',
    price: 120.00,
    imageUrl: 'assets/running_nike.png',
    description: 'Zapatillas cómodas y ligeras para entrenamientos.',
  ),
];
