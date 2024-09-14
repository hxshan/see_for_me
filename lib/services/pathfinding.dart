import 'dart:math';

import 'package:flutter/material.dart';
import 'package:see_for_me/data/node.dart';
import 'package:see_for_me/data/tile.dart';
import 'package:collection/collection.dart';

List<List<Node>> _convertTileGrid(List<List<Tile?>> grid) {
  if (grid == null) {
    return [[]];
  }

  return List.generate(grid.length, (y) {
    return List.generate(grid[y].length, (x) {
      return Node(grid[y][x]);
    });
  });
}

List<Node> findPathWithAStar(
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

  while (openList.isNotEmpty) {
    // Sort open list by the f-cost (lowest f-cost)
    openList.sort((a, b) => a.f.compareTo(b.f));
    Node current = openList.removeAt(0);
    closedList.add(current);

    // If we reached the goal
    if (current == goal) {
      return _retracePath(current);
    }

    for (var neighbor in _getNeighbors(grid, current)) {
      if (neighbor?.tile?.type == "Wall" || closedList.contains(neighbor)) {
        continue;
      }

      double newGCost = current.g + _distance(current, neighbor);
      if (newGCost < neighbor.g || !openList.contains(neighbor)) {
        neighbor.g = newGCost;
        neighbor.h = _distance(neighbor, goal);
        neighbor.parent = current;

        if (!openList.contains(neighbor)) {
          openList.add(neighbor);
        }
      }
    }
  }

  return []; // No path found
}

List<Node> _getNeighbors(List<List<Node>> grid, Node node) {
  List<Node> neighbors = [];
  int width = grid.length;
  int height = grid[0].length;

  int x = node.tile!.x;
  int y = node.tile!.y;

  // Only check up, down, left, and right (no diagonals)
  if (y > 0) {
    neighbors.add(grid[y - 1][x]); // Left
  }
  if (y < width - 1) {
    neighbors.add(grid[y + 1][x]); // Right
  }
  if (x > 0) {
    neighbors.add(grid[y][x - 1]); // Up
  }
  if (x < height - 1) {
    neighbors.add(grid[y][x + 1]); // Down
  }

  return neighbors;
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

double _distance(Node a, Node b) {
  int dx = (a.tile!.x - b.tile!.x).abs();
  int dy = (a.tile!.y - b.tile!.y).abs();

  // Manhattan distance (no diagonal movement)
  return (dx + dy).toDouble();
}
