import 'dart:collection';
import 'dart:math';

import 'package:see_for_me/data/node.dart';
import 'package:see_for_me/data/tile.dart';

List<List<Node>> _convertTileGrid(List<List<Tile?>> grid) {
  return List.generate(grid.length, (y) {
    return List.generate(grid[y].length, (x) {
      return Node(grid[y][x]!);
    });
  });
}

List<Node> jumpPointSearch(
    List<List<Tile?>> gridArray, Tile? startTile, Tile? goalTile) {
  List<List<Node>> grid = _convertTileGrid(gridArray);

  if (startTile == null || goalTile == null) {
    return [];
  }

  Node start = grid[startTile.y][startTile.x];
  Node goal = grid[goalTile.y][goalTile.x];

  List<Node> openList = [];
  List<Node> closedList = [];
  openList.add(start);

  start.g = 0;
  start.h = _manhattanDistance(start, goal);

  while (openList.isNotEmpty) {
    openList.sort((a, b) => a.f.compareTo(b.f));
    Node current = openList.removeAt(0);
    print(current);
    closedList.add(current);

    if (current == goal) {
      return _retracePath(current);
    }
    _identifySuccessors(current, start, goal, grid, openList, closedList);
  }

  return [];
}

void _identifySuccessors(Node current, Node start, Node goal,
    List<List<Node>> grid, List<Node> openList, List<Node> closedList) {
  for (var neighborDirection in _getNeighbors(current)) {
    Node? jumpPoint = _jump(
        neighborDirection[0], neighborDirection[1], current, start, goal, grid);

    if (jumpPoint == null || closedList.contains(jumpPoint)) continue;
    double newGCost = current.g + _manhattanDistance(current, jumpPoint);

    if (newGCost < jumpPoint.g || !openList.contains(jumpPoint)) {
      jumpPoint.g = newGCost;
      jumpPoint.h = _manhattanDistance(jumpPoint, goal);
      jumpPoint.parent = current;

      if (!openList.contains(jumpPoint)) {
        openList.add(jumpPoint);
      }
    }
  }
}

Node? _jump(int dx, int dy, Node current, Node start, Node goal,
    List<List<Node>> grid) {
  int x = current.tile!.x + dx;
  int y = current.tile!.y + dy;

  if (!_inBounds(x, y, grid) || grid[y][x].tile!.type == 'Wall') {
    // Adjusted to y first
    return null;
  }

  Node nextNode = grid[y][x];

  // Check if the goal is reached
  if (nextNode == goal) {
    return nextNode;
  }

  // Check forced neighbors
  if ((dx != 0 && _forcedNeighbors(dx, dy, grid, current))) {
    return nextNode;
  }

  // Horizontal or vertical movement only
  if (dx != 0) {
    return _jump(dx, 0, nextNode, start, goal, grid) ??
        _jump(0, dy, nextNode, start, goal, grid);
  } else if (dy != 0) {
    return _jump(0, dy, nextNode, start, goal, grid);
  }

  return nextNode; // Keep progressing in the same direction
}

bool _forcedNeighbors(int dx, int dy, List<List<Node>> grid, Node current) {
  int x = current.tile!.x;
  int y = current.tile!.y;

  if (dx != 0) {
    return _inBounds(x, y - 1, grid) &&
            grid[x][y - 1].tile!.type != 'Wall' &&
            grid[x + dx][y - 1].tile!.type == 'Wall' ||
        _inBounds(x, y + 1, grid) &&
            grid[x][y + 1].tile!.type != 'Wall' &&
            grid[x + dx][y + 1].tile!.type == 'Wall';
  } else if (dy != 0) {
    return _inBounds(x - 1, y, grid) &&
            grid[x - 1][y].tile!.type != 'Wall' &&
            grid[x - 1][y + dy].tile!.type == 'Wall' ||
        _inBounds(x + 1, y, grid) &&
            grid[x + 1][y].tile!.type != 'Wall' &&
            grid[x + 1][y + dy].tile!.type == 'Wall';
  }

  return false;
}

bool _inBounds(int x, int y, List<List<Node>> grid) {
  return x >= 0 && x < grid.length && y >= 0 && y < grid[0].length;
}

List<Node> _retracePath(Node node) {
  List<Node> path = [];
  Node? current = node;

  while (current != null) {
    path.add(current);
    current = current.parent;
  }

  return path.reversed.toList();
}

List<List<int>> _getNeighbors(Node node) {
  return [
    [-1, 0], // Left
    [1, 0], // Right
    [0, -1], // Up
    [0, 1], // Down
  ];
}

double _manhattanDistance(Node a, Node b) {
  return (a.tile!.x - b.tile!.x).abs() +
      (a.tile!.y - b.tile!.y).abs().toDouble();
}
