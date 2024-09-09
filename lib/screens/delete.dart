import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:see_for_me/screens/shoppingList.dart';
import 'package:see_for_me/screens/shoppingListPage.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import 'shoppingList.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  final ShoppingList _shoppingList = ShoppingList();

  bool _speechEnabled = false;
  String wordsSpoken = "";
  bool _creatingNewList = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _shoppingList.loadList();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    print("Start");
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    print("end");
    await _speechToText.stop();
    setState(() {});
  }

  // void processCommand(result) {
  //   String response = "";
  //   // if (result.toString().toLowerCase().contains('hello')) {
  //   //   response = maze[4][5].walkable.toString();
  //   // } else {
  //   //   response = "${result.recognizedWords}";
  //   // }
  //   setState(() {
  //     //wordsSpoken = response;
  //     wordsSpoken = "${result.recognizedWords}";
  //   });
  // }

  void _onSpeechResult(result) {
    print(result);
    processCommand(result);
    
  }

  void processCommand(String command) {
    command = command.toLowerCase();
    if (command == 'create new list') {
      _startNewList();
    } else if (_creatingNewList) {
      if (command == 'finish list') {
        _finishNewList();
      } else {
        _addItemToList(command);
      }
    } else if (command == 'read next item') {
      _readNextItem();
    } else {
      speak("Command not found");
    }
  }

  void _startNewList() {
    setState(() {
      _creatingNewList = true;
      // _shoppingList.clearList();
    });
    speak("Starting a new list. Please say items to add. Say 'finish list' when done.");
  }

  void _addItemToList(String item) {
    _shoppingList.addItem(item);
    speak("Added $item to the list.");
  }

  void _finishNewList() {
    setState(() {
      _creatingNewList = false;
    });
    speak("List creation finished. Your list has ${_shoppingList.items.length} items.");
  }

  Future<void> _readNextItem() async {
    String? nextItem = _shoppingList.getNextUnreadItem();
    if (nextItem != null) {
      print("Item =");
      print(nextItem);
      await speak("Next item: $nextItem.");
      // Wait for user confirmation (you might want to add a button for this)
      _shoppingList.markItemAsRead(nextItem);
    } else {
      await speak("You've found all items on your list!");
      _shoppingList.resetReadItems();
    }
  }

  speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1);
    await flutterTts.speak(text);
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
            const SizedBox(height: 40),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.purple[300],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.mic, size: 60, color: Colors.black),
                onPressed: _speechToText.isListening
                    ? _stopListening
                    : _startListening,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ShoppingListPage()),
                );
              },
              child: Text('Open Shopping List'),
            ),
            const SizedBox(height: 20),
            Text(
              _creatingNewList ? "Creating new list..." : "Not creating list",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _readNextItem, 
              child: const Text("Read the item list")
            )
          ],
        ),
      ),
    );
  }
}
