class Tile {
  final int x;
  final int y;
  String type;

  Tile({required this.x, required this.y, required this.type});

  factory Tile.fromJson(Map<String, dynamic> json) {
    return Tile(
      x: json['x'],
      y: json['y'],
      type: json['type'],
    );
  }
}
