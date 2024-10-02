import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import 'shoppingList.dart';
//import 'package:see_for_me/screens/shoppingListPage.dart';
//import 'shoppingListTest.dart';

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
  String response = "";

  final Shoppinglist shoppingList = Shoppinglist();
  bool createNewListState = false;
  bool addQuantityState = false;

  String tempItem = "";

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

void processCommand(SpeechRecognitionResult result) {
  String spokenWords = result.recognizedWords.toLowerCase();

  // Compare the spoken words with "order online"
  if (spokenWords.contains('order online')) {
    response = "Navigating to Order Page";
    speak(response); // Speak the response
    // Navigate to the '/order' page
    Navigator.pushNamed(context, '/order');
  
    return; // Exit the function after handling this command
    } else if (spokenWords.contains('locate')) {
      response = "Retrieving Store information";
      speak(response);
      Navigator.pushNamed(context, '/map');
    } else {
      response = "Say again";
      speak(response); // Speak the response
    }

    setState(() {
      wordsSpoken = spokenWords;
    });

    if (spokenWords.contains("create new list")) {
      _startNewList();
    } else if (addQuantityState) {
      addItemToList(spokenWords);
    } else if (createNewListState) {
      if (result == 'finish list') {
        _finishNewList();
      } else {
        setQuantity(spokenWords);
      }
    } else if (result == "read list") {
      _readList();
    } else if (result == 'read next item') {
      //_readNextItem();
    } else if (result == "delete list") {
      _deleteList();
    } else {
      speak("Command not found");
    }
  }

  setState(() {
    wordsSpoken = spokenWords; // Store the recognized words
  });

  // Command handling
  if (spokenWords == 'create new list') {
    _startNewList();
  } else if (spokenWords == 'finish list' && createNewListState) {
    // This checks if the user is in the state of creating a new list
    _finishNewList();
  } else if (addQuantityState) {
    // If the user is in the state of adding quantity, add the item to the list
    addItemToList(spokenWords);
  } else if (createNewListState) {
    // Set quantity when creating a new list and spoken words are not 'finish list'
    setQuantity(spokenWords);
  } else if (spokenWords == "read list") {
    _readList();
  } else if (spokenWords == 'read next item') {
    //_readNextItem();
  } else if (spokenWords == "delete list") {
    _deleteList();
  } else {
    // Default response if no valid command is recognized
    speak("Command not found");
  }
}

  void _startNewList() {
    speak(
        "Starting a new list. Please say items to add. Say 'finish list' when done.");
    setState(() {
      createNewListState = true;
      addQuantityState = false;
      // shoppingList.clearList();
    });
  }

  void setQuantity(String result) {
    setState(() {
      addQuantityState = true;
      tempItem = result;
    });
    speak("How many $tempItem");
  }

  void addItemToList(String qtyString) {
    int? quantity = int.tryParse(qtyString);
    if (quantity != null) {
      shoppingList.addItem(tempItem, quantity);
      speak(
          "Added $quantity ${quantity == 1 ? 'unit' : 'units'} of $tempItem to the list.");
      setState(() {
        tempItem = "";
        addQuantityState = false;
      });
    } else {
      speak("Sorry, I didn't understand that quantity. Please try again.");
    }
  }

  void _finishNewList() {
    speak(
        "List creation finished. Your list has ${shoppingList.itemList.length} items.");
    setState(() {
      createNewListState = false;
      addQuantityState = false;
    });
  }

  Future<void> _readList() async {
    if (shoppingList.itemList.isEmpty) {
      await speak("Your shopping list is empty.");
      return;
    }

    await speak("Here are all the items in your shopping list:");

    for (var entry in shoppingList.itemList.entries) {
      String item = entry.key;
      int quantity = entry.value;
      await speak("$quantity ${quantity == 1 ? 'unit' : 'units'} of $item");
      await Future.delayed(Duration(milliseconds: 2000));
    }

    await speak("That's all the items in your list.");
  }

/*
  Future<void> _readNextItem() async {
    String? nextItem = shoppingList.getNextUnreadItem();
    if (nextItem != null) {
      print("Item =");
      print(nextItem);
      await speak("Next item: $nextItem.");
      shoppingList.markItemAsRead(nextItem);
    } else {
      await speak("You've found all items on your list!");
      shoppingList.resetReadItems();
    }
  }
*/
  Future<void> _deleteList() async {
    if (shoppingList.itemList.isEmpty) {
      await speak("Your shopping list is already empty.");
      return;
    }

    int itemCount = shoppingList.itemList.length;
    shoppingList.clearList();

    setState(() {});

    await speak(
        "All $itemCount items have been deleted from your shopping list.");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home page"),
      ),
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
/*
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
              createNewListState ? "Creating new list..." : "Not creating list",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            /*ElevatedButton(
              onPressed: _readNextItem, 
              child: const Text("Read the item list")
            )*/*/
          ],
        ),
      ),
    );
  }
}
