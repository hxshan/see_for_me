import 'package:see_for_me/data/tile.dart';

class Node {
  final Tile tile;
  double g = 0, h = 0;
  Node? parent;

  Node(this.tile);

  double get f => g + h;

  @override
  String toString() => '(${tile?.x}, ${tile?.y})';
}
