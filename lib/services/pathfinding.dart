import 'package:see_for_me/data/node.dart';
import 'package:see_for_me/data/tile.dart';
import 'package:collection/collection.dart';

List<Tile> findPath(List<List<Tile>> grid, Tile start, Tile end) {
  // Check if start and end are valid and walkable
  if (start.type.toLowerCase() != "start" || end.type.toLowerCase() != "end") {
    return [];
  }

  PriorityQueue<Node> openSet =
      PriorityQueue<Node>((a, b) => a.f.compareTo(b.f));

  Set<Node> closedSet = {};

  openSet.add(Node(start));

  while (openSet.isNotEmpty) {
    Node current = openSet.removeFirst();

    if (current.tile == end) {
      // Reconstruct the path
      List<Tile> path = [];
      Node? node = current;
      while (node != null) {
        path.insert(0, node.tile);
        node = node.parent;
      }
      return path;
    }

    closedSet.add(current);
    //print('Exploring node at (${current.tile.x}, ${current.tile.y})');
    for (int dx in [-1, 0, 1]) {
      for (int dy in [-1, 0, 1]) {
        if (dx == 0 && dy == 0) continue;
        int x = current.tile.x + dx;
        int y = current.tile.y + dy;

        if (x >= 0 && x < grid.length && y >= 0 && y < grid[0].length) {
          Tile neighbor = grid[x][y];
          if (neighbor.type.toLowerCase() == "empty" &&
              !closedSet.any((node) => node.tile == neighbor)) {
            Node neighborNode = Node(
              neighbor,
              g: current.g + 1,
              h: (neighbor.x - end.x).abs() + (neighbor.y - end.y).abs(),
              parent: current,
            );
            if (!closedSet.contains(neighborNode) &&
                !openSet.contains(neighborNode)) {
              openSet.add(neighborNode);
            }
          }
        }
      }
    }
  }

  return [];
}
