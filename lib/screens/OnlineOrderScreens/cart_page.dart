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
import 'package:http/http.dart' as http;
import 'package:see_for_me/ordering/misrecognizeCommands.dart';


class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();

  List<GroceryItem> groceryItems = []; //List of all products
  List<Item> items = List.empty(growable: true); //List of all cart items
  List<GroceryItem> filteredItems = List.empty(growable: true); //List of all filtered items

  bool _speechEnabled = false;
  String wordsSpoken = ""; //User spoken words
  String response = ""; //Respose to the user
  int currentItemIndex = 0; //Keeps track of the current item during review
  bool isReviewing = false; // Tracks if we're revieeing the items in cart
  bool awaitingQuantity = false; // Tracks if we're waiting for the quantity



//Function to get all products
  Future<void> fetchProducts() async {
  final url = Uri.parse('http://10.0.2.2:5224/api/Product');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // Parse the JSON response
      List<dynamic> data = json.decode(response.body);

      // Convert JSON data into GroceryItem objects
      List<GroceryItem> fetchedItems = data.map((item) {
        return GroceryItem(
          productID: item['id'].toString(),
          name: item['productName'],
          type: item['type']['name'],
          brand: item['brand']['name'],
          price: item['unitprice'].toDouble(),
          weight: double.parse(item['unitWeight']), // Parse string to double
          unit: item['unit'] ?? '', // Handle null units
        );
      }).toList();

      // Update the global groceryItems list
      groceryItems = fetchedItems;

      print('Grocery items updated: $groceryItems');

    } else {
      print('Failed to load products. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching products: $e');
  }
}



//Function to load cart items from shared preference and to filteredList
Future<void>_loadCartItemsFromSharedPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? storedItems = prefs.getStringList('myCart');

  if (storedItems != null) {
    // Printing all items retrieved from SharedPreferences
    print('Stored items in SharedPreferences: $storedItems');

    setState(() {
      // Decoding JSON strings into Item objects
      items = storedItems
          .map((itemString) => Item.fromJson(json.decode(itemString)))
          .toList();
    });

    // Printing the decoded list of items
    print('Decoded items: $items');

    _filterCartItems();
  } else {
    // If no items found in SharedPreferences, set items to an empty list
    print('No items found in SharedPreferences.');
    setState(() {
      items = [];
    });
  }
}

//Function to update & save cart in shared preference
void _saveUpdatedCart() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> itemStrings = items.map((item) => json.encode(item.toJson())).toList();
  await prefs.setStringList('myCart', itemStrings);
}


//Function to clear all items in shared preference
Future<void> clearCartFromSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.remove('myCart');
  
  print("Cart has been cleared from SharedPreferences.");
}


//Function to get predefined responses
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


//Function to filter items from the grocery list
void _filterCartItems() {
  // Ensure both items and groceryItems are loaded before filtering
  if (items.isNotEmpty && groceryItems.isNotEmpty) {
    setState(() {
      filteredItems = groceryItems
          .where((groceryItem) =>
              items.any((item) => item.productId == groceryItem.productID))
          .toList();
    });
    print('Filtered items: $filteredItems');
  }else {
    print('Either cart items or grocery items are empty.');
  }
}

//Function to modify a item
  void askForItem(GroceryItem item) {
    String question = "Do you want ${item.name}?";
    speak(question);
  }

//Function to annouce what page
  void announceCurrentPage(String pageName) {
  response = "You are currently on the $pageName page.";
  speak(response);
}

//Function to describe current item
void describeCurrentItem() {
  if (currentItemIndex < filteredItems.length) {
    final groceryItem = filteredItems[currentItemIndex];
    
    // Find the corresponding item in the items list to get the quantity
    Item? cartItem = items.firstWhere(
        (item) => item.productId == groceryItem.productID,
        orElse: () => Item(productId: groceryItem.productID, name: groceryItem.name, price: groceryItem.price)); // Fallback to a new Item without quantity

    // Get the quantity (default to 1 if null)
    int quantity = cartItem.quantity ?? 1;

    response = "${groceryItem.name} costs Rs ${groceryItem.price}, weighs ${groceryItem.weight} ${groceryItem.unit}, and you have a quantity of $quantity.";
  } else {
    response = "No item to describe.";
  }
}


//Function to say user all items
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
  
      response += "${groceryItem.name}, costing ${groceryItem.price.toStringAsFixed(2)} Rupees per unit, weighing ${groceryItem.weight} ${groceryItem.unit}";
      response += ", with a quantity of $quantity, totaling ${totalPrice.toStringAsFixed(2)} dollars.";
      response += " ";

    }
  } else {
    response = "Your cart is empty.";
  }
}

//Function to start editing each item one by one
void startEdit() {
  if (filteredItems.isNotEmpty) {
    currentItemIndex = 0;
    isReviewing = true;
    awaitingQuantity = false;
    askAboutCurrentItem();
  } else {
    response = "Your cart is empty.";
    speak(response);
  }
}

//Function to ask user about current item
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
    response = "You have reviewed all items in your cart. and the total price of all items in your cart is \Rs ${totalPrice.toStringAsFixed(2)}.";
    speak(response);
    isReviewing = false;
    _saveUpdatedCart();
  }
}


//Function to handle edit commands
void handleEditCommand(String spokenWords) {
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

//Function to handle quantity input
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


//Function to remove current item
void removeCurrentItem() {
  setState(() {
    items.removeWhere((item) => item.productId == filteredItems[currentItemIndex].productID);
    filteredItems.removeAt(currentItemIndex);
  });
  askAboutCurrentItem();
}


//Function to remove all items from cart
void removeAllItems() {
  if (items.isEmpty) {
    response = "There are no items in your cart to remove.";
  } else {
    setState(() {
      items.clear();
      filteredItems.clear();
    });

    clearCartFromSharedPreferences();

    response = "All items have been removed from the cart.";
  }
}

//Function to update item Quantity
void updateItemQuantity(int quantity) {
  setState(() {
    items.firstWhere((item) => item.productId == filteredItems[currentItemIndex].productID)
        .quantity = quantity;
  });
  promptTotalPrice();
  currentItemIndex++;
  askAboutCurrentItem();
}


//Function to redirect user to add more items
void addItems() {
  response = "Navigating to the ordering Page to add more items";
  speak(response);
  Navigator.pushNamed(context, '/order'); 
}

//Function to redirect user to check out
void checkOut() {
  if (items.isEmpty) { 
    response = "No items found in your current cart. Please add items before proceeding to checkout.";
    speak(response);
  } else {
    response = "Navigating to the checkout page to complete order.";
    speak(response);
    Navigator.pushNamed(context, '/checkout');
  }
}


//Function to extract quantity
int? _extractQuantity(String spokenWords) {
  // Normalize spoken words to lowercase for comparison
  String normalizedWords = spokenWords.toLowerCase();

  // Check if the spoken words contain a number in digits
  final match = RegExp(r'\d+').firstMatch(normalizedWords);
  if (match != null) {
    return int.parse(match.group(0)!);
  }

  // Check if the spoken words contain a word-based number
  for (var word in numberWords.keys) {
    if (normalizedWords.contains(word)) {
      return numberWords[word];
    }
  }

  // Return null if no quantity found
  return null;
}

final Map<String, int> numberWords = {
  'one': 1,
  'two': 2,
  'three': 3,
  'four': 4,
  'five': 5,
  'six': 6,
  'seven': 7,
  'eight': 8,
  'nine': 9,
  'ten': 10,
  'eleven': 11,
  'twelve': 12,
  'thirteen': 13,
  'fourteen': 14,
  'fifteen': 15,
  'sixteen': 16,
  'seventeen': 17,
  'eighteen': 18,
  'nineteen': 19,
  'twenty': 20,
};



//Function to tell user the total price
void promptTotalPrice() {
  if (items.isEmpty) {
    response = "There are no items in your cart to calculate the total price.";
  } else {
    double totalPrice = 0.0;

    for (var item in items) {
      totalPrice += item.quantity! * item.price;
    }

    response = "The total price of all items in your cart is \Rs ${totalPrice.toStringAsFixed(2)}.";
  }
}

Future<void> _loadDataAndFilter() async {
  // Wait for both cart items and products to load
  await Future.wait([
    _loadCartItemsFromSharedPreferences(),
    fetchProducts()
  ]);

  // Once both are done, filter the cart items
  _filterCartItems();
}

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadDataAndFilter();
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

   void _toggleListening() async {
    if (_speechToText.isListening) {
      _stopListening();
    } else {
      await flutterTts.stop();
      _startListening();
    }
  }

  String correctMisrecognizedWords(String spokenWords) {
  misrecognizedCommands.forEach((wrong, correct) {
    if (spokenWords.contains(wrong)) {
      spokenWords = spokenWords.replaceAll(wrong, correct);
    }
  });
  return spokenWords;
}





  void processCommand(SpeechRecognitionResult result) {
  String spokenWords = result.recognizedWords.toLowerCase();

  spokenWords = correctMisrecognizedWords(spokenWords);

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
  } else if(spokenWords.contains("check out")){
    checkOut();
  } else if (awaitingQuantity) {
    handleQuantityInput(spokenWords);
  } else if(spokenWords.contains("total price")){
    promptTotalPrice();
  } else if(spokenWords.contains("current page")){
    announceCurrentPage("Manage cart");
  } else if(spokenWords.contains("clear all items")){
    removeAllItems();
  } else if (isReviewing) {
    handleEditCommand(spokenWords);
  } else {
    response = getResponse("error");
    
  }

  setState(() {
    wordsSpoken = spokenWords;
  });

  speak(response);
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
                          "Price: \Rs ${groceryItem.price.toStringAsFixed(2)}",
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