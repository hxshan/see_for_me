import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:see_for_me/data/store_map.dart';
import 'package:see_for_me/data/tile.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  List<List<Tile?>> _mapGrid = [];

  bool _speechEnabled = false;
  String wordsSpoken = "";

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _fetchAndSetMapGrid();
  }

  Future<void> _fetchAndSetMapGrid() async {
    List<List<Tile?>> mapGrid = await createMapGrid();
    setState(() {
      _mapGrid = mapGrid; // Set the map grid after fetching
    });
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

  void processCommand(result) {
    String response = "";
    // if (result.toString().toLowerCase().contains('hello')) {
    //   response = maze[4][5].walkable.toString();
    // } else {
    //   response = "${result.recognizedWords}";
    // }
    setState(() {
      //wordsSpoken = response;
      wordsSpoken = "${result.recognizedWords}";
    });
  }

  void _onSpeechResult(result) {
    processCommand(result);
  }

  speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1);
    await flutterTts.speak(text);
  }

  Future<StoreMap> fetchMap() async {
    final uri = Uri.parse('http://10.0.2.2:5224/api/floor/1');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return StoreMap.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load map');
  }

  Future<List<List<Tile?>>> createMapGrid() async {
    try {
      StoreMap storeMap = await fetchMap();
      List<List<Tile?>> grid = List.generate(
          storeMap.height, (x) => List.generate(storeMap.width, (x) => null));
      for (Tile tile in storeMap.tiles) {
        grid[tile.x][tile.y] = tile;
      }

      return grid;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ignore: prefer_const_constructors
            Text(
              "wordsSpoken:$wordsSpoken",
              // ignore: prefer_const_constructors
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
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
                icon: Icon(Icons.mic, size: 60, color: Colors.black),
                onPressed: _speechToText.isListening
                    ? _stopListening
                    : _startListening,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
