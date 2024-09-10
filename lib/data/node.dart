import 'package:see_for_me/data/tile.dart';

class Node {
  final Tile tile;
  int g, h, f;
  Node? parent;

  Node(this.tile, {this.g = 0, this.h = 0, this.f = 0, this.parent});
}
