import 'package:see_for_me/data/tile.dart';

class StoreMap {
  final List<Tile> tiles;
  final int width;
  final int height;

  StoreMap({required this.tiles, required this.width, required this.height});

  factory StoreMap.fromJson(Map<String, dynamic> json) {
    var tilesList = json['tiles'] as List;
    List<Tile> tiles = tilesList.map((tile) => Tile.fromJson(tile)).toList();

    return StoreMap(
      tiles: tiles,
      width: json['width'],
      height: json['height'],
    );
  }
}
