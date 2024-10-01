import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:see_for_me/data/node.dart';
import 'package:see_for_me/data/tile.dart';
import 'package:see_for_me/services/compass.dart';
import 'package:see_for_me/services/jump_point_search.dart';
import 'package:see_for_me/services/pathfinding.dart';
import 'package:see_for_me/services/pathnarration.dart';

import '../services/Direction.dart';

class MapTest extends StatefulWidget {
  const MapTest({super.key});

  @override
  State<MapTest> createState() => _MapTestState();
}

class _MapTestState extends State<MapTest> {
  late List<List<Tile>> grid;
  Tile? startTile;
  Tile? endTile;
  List<Node> path = [];
  final int gridSize = 10;
  final double obstacleProbability = 0.1;

  final Compass _compass = Compass();
  Direction _currentFacing = Direction.north;

  @override
  void initState() {
    super.initState();
    initializeGrid();

    _compass.startListening();

    Timer.periodic(Duration(seconds: 1), (timer) async {
      double heading = await _compass.getHeading();
      setState(() {
        _currentFacing = _compass.getCardinalDirection(heading);
      });
    });
  }

  @override
  void dispose() {
    _compass.stopListening(); // Stop the compass listener
    super.dispose();
  }

  void initializeGrid() {
    final random = Random();
    grid = List.generate(
      gridSize,
      (y) => List.generate(
        gridSize,
        (x) => Tile(
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

  void findPath() {
    List<Node> path = findPathWithAStar(grid, startTile, endTile);
    //List<Node> path = jumpPointSearch(grid, startTile, endTile);
    print(path);
    narratePath(path, _currentFacing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('A* Pathfinding Visualization'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
              ),
              itemCount: 100,
              itemBuilder: (context, index) {
                int x = index ~/ 10;
                int y = index % 10;
                Tile tile = grid[x][y];
                return GestureDetector(
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
          Text(
            'Azimuth: $_currentFacing°',
            style: TextStyle(fontSize: 24),
          ),
          ElevatedButton(
            onPressed: findPath,
            child: const Text('Find Path'),
          ),
          ElevatedButton(
            onPressed: initializeGrid,
            child: const Text('Reset Grid'),
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
