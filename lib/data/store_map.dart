import 'package:see_for_me/data/tile.dart';

class StoreMap {
  final List<List<Tile>> tiles;
  final int width;
  final int height;

  StoreMap({
    required this.tiles,
    required this.width,
    required this.height,
  });
  factory StoreMap.fromJson(Map<String, dynamic> json) {
    var tileList = (json['tiles'] as List)
        .map((tileJson) => Tile.fromJson(tileJson))
        .toList();

    // Convert the flat list of tiles into a 2D list
    List<List<Tile>> tileMap = List.generate(
      json['height'],
      (y) => List.generate(
        json['width'],
        (x) => tileList.firstWhere((tile) => tile.x == x && tile.y == y),
      ),
    );

    return StoreMap(
      width: json['width'],
      height: json['height'],
      tiles: tileMap,
    );
  }

  // Override toString for better debugging
  @override
  String toString() {
    return 'StoreMap(tiles: $tiles, width: $width, height: $height)';
  }
}
