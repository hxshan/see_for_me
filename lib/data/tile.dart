import 'package:see_for_me/data/product.dart';

class Tile {
  final int id;
  final int x;
  final int y;
  String type;
  List<Product> products;

  Tile({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    required this.products,
  });

  factory Tile.fromJson(Map<String, dynamic> json) {
    return Tile(
      id: json['id'],
      x: json['x'],
      y: json['y'],
      type: json['type'],
      products: (json['products'] as List<dynamic>?)?.map((productJson) {
            return Product.fromJson(
                productJson); // Assuming Product has a fromJson
          }).toList() ??
          [],
    );
  }
}
