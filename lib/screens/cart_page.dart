import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:see_for_me/models/groceryItem.dart'; //grocery class and mock data
import 'package:shared_preferences/shared_preferences.dart'; //shared preference
import 'package:see_for_me/models/cartItem.dart';//cart class
import 'dart:convert'; // For json.decode
import 'package:see_for_me/ordering/searchResponses.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();

  bool _speechEnabled = false;
  String wordsSpoken = "";
  String response = "";
  int currentItemIndex = 0; // Keeps track of the current item during review
  bool isReviewing = false;
  bool awaitingQuantity = false; // Tracks if we're waiting for the quantity

  List<Item> items = List.empty(growable: true);
  List<GroceryItem> filteredItems = List.empty(growable: true);


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
    _filterCartItems();
  } else {
    // If no items found in SharedPreferences, set items to an empty list
    setState(() {
      items = [];
    });
  }
}


  void _filterCartItems() {
    setState(() {
      filteredItems = groceryItems
          .where((groceryItem) =>
              items.any((item) => item.productId == groceryItem.productID))
          .toList();
    });
  }

  void askForItem(GroceryItem item) {
    String question = "Do you want ${item.name}?";
    speak(question);
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
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


  if (spokenWords.contains('start edit')) {
    startEdit();
  } else if (spokenWords.contains('describe item')) {
    describeCurrentItem();
  } else if(spokenWords.contains('start review')){
    promptAllItemsInCart();
  } else if(spokenWords.contains("add more")){
    addItems();
  } else if(spokenWords.contains("proceed")){
    checkOut();
  } else if (awaitingQuantity) {
    handleQuantityInput(spokenWords);
  } else if(spokenWords.contains("total price")){
    promptTotalPrice();
  } else if(spokenWords.contains("current page")){
    announceCurrentPage("Manage cart");
  } else if(spokenWords.contains("clear card")){
    removeAllItems();
  } else if (isReviewing) {
    handleReviewCommand(spokenWords);
  } else {
    response = "Say 'start review' to begin reviewing your cart.";
    speak(response); // Speak the response
  }

  setState(() {
    wordsSpoken = spokenWords;
  });
}
void describeCurrentItem() {
  if (currentItemIndex < filteredItems.length) {
    final groceryItem = filteredItems[currentItemIndex];
    response = "${groceryItem.name} costs ${groceryItem.price}, and its weight is ${groceryItem.weight}.";
    speak(response);
  } else {
    response = "No item to describe.";
    speak(response);
  }
}

void promptAllItemsInCart() {
  if (filteredItems.isNotEmpty) {
    response = "You have the following items in your cart: ";
    for (var groceryItem in filteredItems) {
      // Find the corresponding item in the items list to get the quantity
      Item? cartItem = items.firstWhere(
          (item) => item.productId == groceryItem.productID,
          orElse: () => Item(productId: groceryItem.productID, name: groceryItem.name, price: groceryItem.price)); // Fallback to a new Item without quantity

      // Calculate total price for the item (default quantity to 1 if null)
      int quantity = cartItem.quantity ?? 1;
      double totalPrice = quantity * groceryItem.price;

      // Create the response string
      response += "${groceryItem.name}, costing ${groceryItem.price.toStringAsFixed(2)} dollars per unit, weighing ${groceryItem.weight} ${groceryItem.unit}";

      // Include quantity and total price in the response
      response += ", with a quantity of $quantity, totaling ${totalPrice.toStringAsFixed(2)} dollars.";

      response += " "; // End sentence for each item
    }
    speak(response); // Text-to-speech for the entire cart description
  } else {
    speak("Your cart is empty.");
  }
}

void startEdit() {
  if (filteredItems.isNotEmpty) {
    currentItemIndex = 0;
    isReviewing = true;
    awaitingQuantity = false; // Ensure this is reset
    askAboutCurrentItem();
  } else {
    response = "Your cart is empty.";
    speak(response);
  }
}

void askAboutCurrentItem() {
  double totalPrice = 0.0;

   for (var item in items) {
    totalPrice += item.quantity! * item.price;
  }

  if (currentItemIndex < filteredItems.length) {
    final groceryItem = filteredItems[currentItemIndex];
    final cartItem = items.firstWhere(
      (item) => item.productId == groceryItem.productID,
      orElse: () => Item(productId: groceryItem.productID, name: groceryItem.name , price: groceryItem.price), // Fallback
    );

    // Include quantity if it is set
    String quantityInfo = cartItem.quantity != null 
        ? " with a quantity of ${cartItem.quantity}." 
        : ".";

    response = "Do you want to keep ${groceryItem.name}${quantityInfo} Say yes or no.";
    speak(response);
  } else {
    response = "You have reviewed all items in your cart. and the total price of all items in your cart is \$${totalPrice.toStringAsFixed(2)}.";
    speak(response);
    isReviewing = false;
    _saveUpdatedCart();
  }
}


void handleReviewCommand(String spokenWords) {
  if (spokenWords.contains('no')) {
    removeCurrentItem();
  } else if (spokenWords.contains('yes')) {
    response = "How many do you want?";
    speak(response);
    awaitingQuantity = true; // Awaiting quantity input from user
  } else {
    response = "Please say yes or no.";
    speak(response);
  }
}

void handleQuantityInput(String spokenWords) {
  final quantity = _extractQuantity(spokenWords);
  if (quantity != null) {
    updateItemQuantity(quantity);
    awaitingQuantity = false; // Reset awaiting quantity flag
  } else {
    response = "Invalid quantity. Please try again.";
    speak(response);
  }
}

void removeCurrentItem() {
  setState(() {
    items.removeWhere((item) => item.productId == filteredItems[currentItemIndex].productID);
    filteredItems.removeAt(currentItemIndex);
  });
  askAboutCurrentItem(); // Move to the next item
}

void removeAllItems() {
  setState(() {
    // Clear both the items and filteredItems lists
    items.clear();
    filteredItems.clear();
  });

  // Inform the user that all items have been removed from the cart
  response = "All items have been removed from the cart.";
  speak(response); // Use the TTS function to speak the response

  // Optionally, you can navigate to another page or reset the cart state here
}

void updateItemQuantity(int quantity) {
  setState(() {
    items.firstWhere((item) => item.productId == filteredItems[currentItemIndex].productID)
        .quantity = quantity;
  });
  promptTotalPrice();
  currentItemIndex++;
  askAboutCurrentItem(); // Move to the next item
   printItemsWithQuantity();
}

void printItemsWithQuantity() {
  if (items.isNotEmpty) {
    for (var item in items) {
      print(
          "Product: ${item.name}, ID: ${item.productId}, Quantity: ${item.quantity ?? 'Not set'} Price : ${item.price}");
    }
  } else {
    print("Your cart is empty.");
  }
}

void addItems() {
 
  response = "Navigating to the ordering Page to add more items";
  speak(response);
  Navigator.pushNamed(context, '/order'); 
}

void checkOut() {
  // Check if there are items in the cart
  if (items.isEmpty) { // Assuming 'items' is your cart list
    response = "No items found in your cart. Please add items before proceeding to checkout.";
    speak(response);
  } else {
    response = "Navigating to the checkout page to complete order.";
    speak(response);
    Navigator.pushNamed(context, '/checkout');
  }
}
int? _extractQuantity(String spokenWords) {
  final match = RegExp(r'\d+').firstMatch(spokenWords);
  return match != null ? int.parse(match.group(0)!) : null;
}

void _saveUpdatedCart() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> itemStrings = items.map((item) => json.encode(item.toJson())).toList();
  await prefs.setStringList('myCart', itemStrings);
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
        title: const Text("Cart Page"),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Text(
            "Words Spoken: $wordsSpoken",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final groceryItem = filteredItems[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groceryItem.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Type: ${groceryItem.type}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          "Brand: ${groceryItem.brand}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          "Price: \$${groceryItem.price.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          "Weight: ${groceryItem.weight} ${groceryItem.unit}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
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
      ),
    );
  }
}