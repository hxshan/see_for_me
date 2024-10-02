import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:shared_preferences/shared_preferences.dart'; //shared preference
import 'package:see_for_me/models/cartItem.dart';//cart class
import 'dart:convert'; // For json.decode
import 'package:see_for_me/ordering/searchResponses.dart';

class User {
  String id;
  String name;
  String address;
  String email;
  String phoneNumber;

  User({
    required this.id,
    required this.name,
    required this.address,
    required this.email,
    required this.phoneNumber,
  });
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  

  bool _speechEnabled = false;
  String wordsSpoken = "";
  String response = "";

  List<Item> items = List.empty(growable: true);

  final User user = User(
    id: "U12345",
    name: "John Doe",
    address: "123 Main St, Cityville",
    email: "john.doe@example.com",
    phoneNumber: "+1234567890",
  );

    void _loadCartItemsFromSharedPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? storedItems = prefs.getStringList('myCart');
  
  if (storedItems != null) {
    setState(() {
      // Decoding JSON strings into Item objects
      items = storedItems
          .map((itemString) => Item.fromJson(json.decode(itemString)))
          .toList();
    });
  } else {
    // If no items found in SharedPreferences, set items to an empty list
    setState(() {
      items = [];
    });
  }
}

 String getResponse(String key) {
    if (key.contains("searching")) {
      for (var response in helpResponses) {
        if (response.containsKey(key)) {
          return response[key]!;
        }
      }
      return "Sorry, I didn't understand that.";
    } else {
      for (var response in responses) {
        if (response.containsKey(key)) {
          return response[key]!;
        }
      }
      return "Sorry, I didn't understand that.";
    }
  }

      void announceCurrentPage(String pageName) {
  // Construct the response to inform the user which page they are on
  response = "You are currently on the $pageName page.";
  
  // Use the text-to-speech feature to speak the response
  speak(response);
}


  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadCartItemsFromSharedPreferences();
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
     if (spokenWords.contains("repeat")) {
      if (response.isNotEmpty) {
        speak(response); // Repeat the last response
      } else {
        response = getResponse("error");
        speak(response);
      }
      setState(() {
        wordsSpoken = spokenWords;
      });
      return;
    }

    if(spokenWords.contains("price")){
    promptTotalPrice();
  } else if(spokenWords.contains("current page")){
    announceCurrentPage("Checkout");
  } else {
      response = "Say again";
      speak(response); // Speak the response
    }

    setState(() {
      wordsSpoken = spokenWords;
    });
  }

  void promptTotalPrice() {
  double totalPrice = 0.0;

  // Calculate total price since all items will have a quantity of at least 1
  for (var item in items) {
    totalPrice += item.quantity! * item.price;
  }

  // Construct the response to inform the user about the total price
  response = "The total price of all items in your cart is \$${totalPrice.toStringAsFixed(2)}.";
  
  speak(response);
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
  double totalPrice = 0.0;
  
  // Calculate total price for all items in the cart
  for (var item in items) {
    totalPrice += item.price * (item.quantity ?? 1);
  }

  return Scaffold(
    appBar: AppBar(
      title: Text("Checkout Page"),
    ),
    backgroundColor: Colors.white,
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User details section
          Text(
            "User Details",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text("ID: ${user.id}", style: TextStyle(fontSize: 18)),
          Text("Name: ${user.name}", style: TextStyle(fontSize: 18)),
          Text("Address: ${user.address}", style: TextStyle(fontSize: 18)),
          Text("Email: ${user.email}", style: TextStyle(fontSize: 18)),
          Text("Phone: ${user.phoneNumber}", style: TextStyle(fontSize: 18)),
          SizedBox(height: 20),

          // Cart items section
          Text(
            "Cart Items",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),

          Expanded(
            child: items.isNotEmpty
                ? ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Price: \$${item.price.toStringAsFixed(2)}"),
                              Text("Quantity: ${item.quantity ?? 1}"),
                            ],
                          ),
                          trailing: Text(
                            "Total: \$${(item.price * (item.quantity ?? 1)).toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      "Your cart is empty",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),

          // Total price section at the end
          SizedBox(height: 20),
          Text(
            "Total Price: \$${totalPrice.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          SizedBox(height: 20),
          Center(
            child: Container(
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
          ),
          SizedBox(height: 20),
          Center(
            child: Text(
              "wordsSpoken: $wordsSpoken",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}