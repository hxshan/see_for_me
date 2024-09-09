import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';


import 'shoppingList.dart';
import 'package:see_for_me/screens/shoppingListPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();

  bool _speechEnabled = false;
  String wordsSpoken = "";

  final ShoppingList _shoppingList = ShoppingList();
  bool _creatingNewList = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
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

    result = result.recognizedWords.toLowerCase();
    if (result == 'create new list') {
      _startNewList();
    } else if (_creatingNewList) {
      if (result == 'finish list') {
        _finishNewList();
      } else {
        _addItemToList(result);
      }
    } else if (result == "read list"){
      _readList();
    } else if (result == 'read next item') {
      _readNextItem();
    } else if(result == "delete list") {
      _deleteList();
    }else {
      speak("Command not found");
    }

    

    
  }

  void _startNewList() {
    print("Inside start new list");
    speak("Starting a new list. Please say items to add. Say 'finish list' when done.");
    setState(() {
      _creatingNewList = true;
      // _shoppingList.clearList();
    });
    
  }

  void _addItemToList(String item) {
    _shoppingList.addItem(item);
    speak("Added $item to the list.");
  }

  void _finishNewList() {
    speak("List creation finished. Your list has ${_shoppingList.items.length} items.");
    setState(() {
      _creatingNewList = false;
    });  
  }

  Future<void> _readList() async {
     if (_shoppingList.items.isEmpty) {
      await speak("Your shopping list is empty.");
      return;
    }

    await speak("Here are all the items in your shopping list:");

    for (int i = 0; i < _shoppingList.items.length; i++) {
      String item = _shoppingList.items[i];
      await speak("Item ${i + 1}: $item");
      
      // Add a short pause between items for better comprehension
      await Future.delayed(Duration(milliseconds: 1500));
    }

    await speak("That's all the items in your list.");
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

  Future<void> _deleteList() async {
    if (_shoppingList.items.isEmpty) {
      await speak("Your shopping list is already empty.");
      return;
    }

    int itemCount = _shoppingList.items.length;
    _shoppingList.clearList();

    setState(() {
      // This will trigger a rebuild of the UI if you're displaying the list
    });

    await speak("All $itemCount items have been deleted from your shopping list.");
  }

  void _onSpeechResult(result) {
    processCommand(result);
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




