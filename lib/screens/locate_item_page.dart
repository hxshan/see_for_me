import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:see_for_me/data/node.dart';
import 'package:see_for_me/data/store_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:see_for_me/data/tile.dart';
import 'package:see_for_me/services/Direction.dart';
import 'package:see_for_me/services/compass.dart';
import 'package:see_for_me/services/pathfinding.dart';
import 'package:see_for_me/services/pathnarration.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class LocateItemPage extends StatefulWidget {
  const LocateItemPage({super.key});

  @override
  State<LocateItemPage> createState() => _LocateItemPageState();
}

class _LocateItemPageState extends State<LocateItemPage> {
  late Future<StoreMap> storeMap;
  List<Tile> shelfTiles = [];
  List<List<Tile>> grid = [];
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  List<Node> path = [];

  bool _speechEnabled = false;
  String wordsSpoken = "";
  String response = "";

  final Compass _compass = Compass();
  Direction _currentFacing = Direction.north;

  @override
  void initState() {
    super.initState();
    storeMap = fetchStoreMap();
    _initSpeech();

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
    _compass.stopListening();
    super.dispose();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    // Only process the command when the user has finished speaking
    if (result.finalResult) {
      processCommand(result);
    }
  }

  speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1);
    await flutterTts.speak(text);
  }

  void findPath(Tile? startTile, Tile? endTile) {
    if (startTile == null || endTile == null) return;
    List<Node> pathList = findPathWithAStar(grid, startTile, endTile);
    setState(() {
      path = pathList;
    });
    //List<Node> path = jumpPointSearch(grid, startTile, endTile);
    //narratePath(path, _currentFacing);
    //Navigator.pushNamed(context, '/home');
  }

  void processCommand(SpeechRecognitionResult result) {
    String spokenWords = result.recognizedWords.toLowerCase();
    setState(() {
      wordsSpoken = spokenWords;
    });

    if (spokenWords.contains('find')) {
      List<String> wordsList = spokenWords.split(' ');
      wordsList.removeWhere((word) => word == 'find');

      Tile? startTile = grid[1][1];
      Tile? endTile = null;
      print(shelfTiles.length);
      for (var tile in shelfTiles) {
        if (tile.products.isNotEmpty) {
          for (var prod in tile.products) {
            if (wordsList.any((word) =>
                word.toLowerCase() == prod.productName.toLowerCase())) {
              endTile = tile;
              break;
            }
          }
        }
      }

      if (endTile == null) {
        speak("Sorry, I could not find your product");
        return;
      }
      findPath(startTile, endTile);
      print(path);
      var curr = path[0];
      while (curr != path[path.length - 1]) {
        print("object");
        curr = generateNarrationUntilTurn(path, curr, _currentFacing);
      }

      Navigator.pushNamed(context, '/home');
    } else if (spokenWords.contains('go back')) {
      Navigator.pushNamed(context, '/home');
    } else {
      speak("Sorry! I didn't get that");
    }
  }

  Future<StoreMap> fetchStoreMap() async {
    final response =
        await http.get(Uri.parse('http://10.0.2.2:5224/api/floor/first'));

    if (response.statusCode == 200) {
      StoreMap map = StoreMap.fromJson(jsonDecode(response.body));

      shelfTiles = map.tiles.expand((i) => i).where((tile) {
        return ['shelfUp', 'shelfDown', 'shelfRight', 'shelfLeft']
            .contains(tile.type);
      }).toList();

      grid = map.tiles;

      return map;
    } else {
      speak("Sorry an Unexpected error occured");
      throw Exception('Failed to load store map');
    }
  }

  void _toggleListening() async {
    if (_speechToText.isListening) {
      _stopListening();
    } else {
      await flutterTts.stop();
      _startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Store Map'), // Title of the AppBar
        actions: [
          IconButton(
            icon: Icon(Icons.settings), // Example icon in the AppBar
            onPressed: () {
              // Define what happens when the settings button is pressed
              print('Settings button pressed');
            },
          ),
        ],
      ),
      body: FutureBuilder<StoreMap>(
        future: storeMap,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No data found.'));
          }

          // Assuming StoreMap has a property `tiles` which is a List<List<Tile>>
          final storeMapData = snapshot.data!;
          final tiles = storeMapData.tiles;

          return Column(
            children: [
              // Use a Container to wrap the GridView
              Container(
                padding: const EdgeInsets.all(8.0), // Padding around the grid
                child: GridView.builder(
                  shrinkWrap:
                      true, // Allow GridView to take only necessary space
                  physics: NeverScrollableScrollPhysics(), // Disable scrolling
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        tiles[0].length, // Number of columns based on the width
                    childAspectRatio: 1, // Adjust to your preference
                  ),
                  itemCount: tiles.length * tiles[0].length,
                  itemBuilder: (context, index) {
                    // Calculate x and y from the index
                    int x = index % tiles[0].length;
                    int y = index ~/ tiles[0].length;
                    final tile = tiles[y][x];

                    Color tileColor;
                    switch (tile.type) {
                      case "empty":
                        tileColor = Colors.grey;
                        break;
                      case "wall":
                        tileColor = Colors.black;
                        break;
                      case "counter":
                        tileColor = Colors.green;
                        break;
                      case "shelfUp":
                      case "shelfDown":
                      case "shelfLeft":
                      case "shelfRight":
                        tileColor = Colors.blue;
                        break;
                      default:
                        tileColor = Colors.white;
                    }

                    return Container(
                      alignment: Alignment.center,
                      margin: EdgeInsets.all(2), // Space between tiles
                      color: tileColor, // Example colors based on type
                    );
                  },
                ),
              ),
              SizedBox(height: 40),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.purple[300],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.mic, size: 60, color: Colors.black),
                  onPressed: _toggleListening,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
