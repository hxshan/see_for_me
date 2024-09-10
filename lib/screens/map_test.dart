import 'dart:math';
import 'package:flutter/material.dart';
import 'package:see_for_me/data/tile.dart';
import 'package:see_for_me/services/pathfinding.dart';

class MapTest extends StatefulWidget {
  const MapTest({super.key});

  @override
  State<MapTest> createState() => _MapTestState();
}

class _MapTestState extends State<MapTest> {
  late List<List<Tile>> grid;
  Tile? startTile;
  Tile? endTile;
  List<Tile> path = [];
  final int gridSize = 10;
  final double obstacleProbability = 0.1;

  @override
  void initState() {
    super.initState();
    initializeGrid();
  }

  void initializeGrid() {
    final random = Random();
    grid = List.generate(
      gridSize,
      (x) => List.generate(
        gridSize,
        (y) => Tile(
            x: x,
            y: y,
            type: random.nextDouble() < obstacleProbability ? "Wall" : "Empty"),
      ),
    );

    // Set start and end tiles
    do {
      startTile = grid[random.nextInt(gridSize)][random.nextInt(gridSize)];
    } while (startTile?.type == "Wall");
    startTile?.type = "Start";

    do {
      endTile = grid[random.nextInt(gridSize)][random.nextInt(gridSize)];
    } while (endTile?.type == "Wall" || endTile == startTile);
    endTile?.type = "End";

    setState(() {});
  }

  void toggleTile(Tile tile) {
    setState(() {
      if (tile.type == "Empty") {
        if (startTile == null) {
          tile.type = "Start";
          startTile = tile;
        } else if (endTile == null) {
          tile.type = "End";
          endTile = tile;
        } else {
          tile.type = "wall";
        }
      } else if (tile.type == "Shelf") {
        tile.type = "Empty";
      } else if (tile.type == "Wall") {
        tile.type = "Empty";
        startTile = null;
      }
    });
  }

  void _findPath() {
    if (startTile == null || endTile == null) return;

    setState(() {
      path = findPath(grid, startTile!, endTile!);
      print(path);
      for (var tile in path) {
        if (tile != startTile && tile != endTile) {
          tile.type = "Path";
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('A* Pathfinding Visualization'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
              ),
              itemCount: 100,
              itemBuilder: (context, index) {
                int x = index ~/ 10;
                int y = index % 10;
                Tile tile = grid[x][y];
                return GestureDetector(
                  onTap: () => toggleTile(tile),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      color: _getTileColor(tile.type),
                    ),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _findPath,
            child: Text('Find Path'),
          ),
          ElevatedButton(
            onPressed: initializeGrid,
            child: Text('Reset Grid'),
          ),
        ],
      ),
    );
  }

  Color _getTileColor(String type) {
    //print(type);
    switch (type) {
      case "Empty":
        return Colors.white;
      case "Wall":
        return Colors.black;
      case "Start":
        return Colors.greenAccent;
      case "End":
        return Colors.red;
      case "shelf":
        return Colors.blue;
      case "Path":
        return Colors.green;
    }
    return Colors.white;
  }
}
