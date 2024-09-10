import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:see_for_me/models/cartItem.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:see_for_me/models/groceryItem.dart'; //importing class and mock data
import 'package:see_for_me/ordering/searchFuncions.dart';
import 'package:see_for_me/ordering/searchResponses.dart';

class OrderingPage extends StatefulWidget {
  const OrderingPage({super.key});

  @override
  State<OrderingPage> createState() => _OrderingPageState();
}

class _OrderingPageState extends State<OrderingPage> {
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();

  final List<String> productTypes = [
    "milk powder",
    "milk",
    "flour",
    "soda",
    "rice"
  ];

  Map<String, String> unitMap = {
    "liters": "l",
    "liter": "l",
    "l": "l",
    "litres": "l",
    "litre": "l",
    "kilograms": "kg",
    "kg": "kg",
    "kilogram": "kg",
    "grams": "g",
    "g": "g",
    "milliliters": "ml",
    "ml": "ml"
    // Add more units as needed
  };

  final brandList = [
    {
      "milk powder": ["Anchor", "Maliban", "Nestle"]
    },
    {
      "biscuits": ["Oreo", "Marie", "Digestive"]
    },
    {
      "soda": ["fanta", "sprite", "mounten dew"]
    },
    {
      "milk": ["Anchor", "Maliban", "Nestle"]
    }
    // Add more categories and brands as needed
  ];

  final Map<String, String> misrecognizedWords = {
    "melbourne": "Maliban",
    "ankhor": "Anchor",
  };

  

  final List<GroceryItem> searchedItems = [];
  List<Item> items = List.empty(growable: true);

  late SharedPreferences sp;

  getSharedPreferences() async {
    sp = await SharedPreferences.getInstance();
  }

  saveIntoSp(){
    List<String> itemListString = items.map((item)=>jsonEncode(item.toJson())).toList();
    sp.setStringList("myCart", itemListString);
  }

  /*readFromSp() {
  List<String>? itemListString = sp.getStringList("myCart");

  if (itemListString != null) {
    items = itemListString.map((item) => Item.fromJson(json.decode(item))).toList();
  } else {
    // Initialize items as an empty list if null
    items = [];
  }
}*/

List<Item> readFromSp() {
  List<String>? itemListString = sp.getStringList("myCart");

  if (itemListString != null) {
    return itemListString.map((item) => Item.fromJson(json.decode(item))).toList();
  } else {
    return [];
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

  int filterSearchItems() {
    // Clear the previous search results
    searchedItems.clear();

    int matchedItemsCount = 0;

    // Filter groceryItems based on the selected productType, quantity, and brand
    for (var item in groceryItems) {
      bool matchesType = productType.isEmpty ||
          item.type.toLowerCase() == productType.toLowerCase();
      bool matchesQuantity = quantity.isEmpty
          ? true
          : item.unit == quantityUnit &&
              item.quantity == (double.tryParse(quantityValue) ?? 0.0);
      bool matchesBrand =
          brand.isEmpty || item.brand.toLowerCase() == brand.toLowerCase();

      if (matchesType && matchesQuantity && matchesBrand) {
        searchedItems.add(item);
        matchedItemsCount++;
      }
    }

    return matchedItemsCount;
  }

  void processProductType(String spokenWords) {
    // Normalize spoken words by converting to lowercase
    String normalizedWords = spokenWords.toLowerCase();

    quantity = "";
    quantityValue = "";
    quantityUnit = "";
    bool productTypeFound = false;

    // Check each product type for an exact match
    for (String type in productTypes) {
      if (normalizedWords.contains(type.toLowerCase())) {
        productType = type;
        productTypeFound = true;

        if (previousType.isEmpty || previousType == productType) {
          // If no previous type or the same product type is mentioned
          noItems = filterSearchItems();
          response ="$productType product type searched and number of items found was $noItems";
        } else if (previousType != productType) {
          // If a different product type is mentioned
          noItems = filterSearchItems();
          response ="Changed to $productType. Number of items found was $noItems";
        }
        previousType = productType;
        break;
      }
    }

    if (!productTypeFound) {
      response = "Sorry, this product type is not available.";
    }

    setState(() {});
  }

  void processQuantity(String spokenWords) {
    
    String normalizedWords = spokenWords.toLowerCase();

    // Split the spoken words into individual words
    List<String> words = normalizedWords.split(RegExp(r'\s+')); // Handle multiple spaces and punctuation

    // Extract possible quantity and unit
    String possibleQuantity = "";
    String possibleUnit = "";

    if (productType.isEmpty) {
      response = "please specify the product type you want first";
      return;
    }

    // Iterate through words to find quantity and unit
    for (int i = 0; i < words.length; i++) {
      if (double.tryParse(words[i]) != null) {
        possibleQuantity = words[i];
      } else if (unitMap.containsKey(words[i])) {
        possibleUnit = unitMap[words[i]] ?? "";
      }
    }

    // Check if both quantity and unit were found
    if (possibleQuantity.isNotEmpty && possibleUnit.isNotEmpty) {
      // Set the quantity value and unit
      quantityValue = possibleQuantity;
      quantityUnit = possibleUnit;
      quantity = "$quantityValue $quantityUnit";

      noItems = filterSearchItems();
      if (noItems > 0) {
        response = "Quantity $quantity is available and the number of items found was $noItems for $productType";
      } else {
        response ="quantity $quantity is not available for $productType";
      }
    } else {
      // Handle missing quantity or unit
      if (possibleQuantity.isEmpty) {
        response = "Sorry, I couldn't find a quantity in your request.";
      } else if (possibleUnit.isEmpty) {
        response ="Sorry, I couldn't find a valid unit. Please specify a valid unit like liters, kilograms, etc.";
      }
    }

    setState(() {});
  }

  void processBrand(String spokenWords) {
    // Normalize spoken words by converting to lowercase
    String normalizedWords = spokenWords.toLowerCase();
    bool brandFound = false;

    // Ensure product type is mentioned first
    if (productType.isEmpty) {
      response = "Please specify the product type first.";
      speak(response);
      return;
    }

    // Ensure quantity is mentioned
    if (quantity.isEmpty) {
      response = "Please specify the quantity first.";
      speak(response);
      return;
    }

    // Correct any misrecognized words using the misrecognizedWords map
    misrecognizedWords.forEach((key, value) {
      if (normalizedWords.contains(key.toLowerCase())) {
        normalizedWords =
            normalizedWords.replaceAll(key.toLowerCase(), value.toLowerCase());
      }
    });

    // Find the correct category (productType) and match the brand within it
    if (brandList.any((category) => category.containsKey(productType.toLowerCase()))) {
      // Extract the brands for the current product type
      List<String>? brands = brandList.firstWhere((category) => category
          .containsKey(productType.toLowerCase()))[productType.toLowerCase()];

      if (brands != null) {
        // Check each brand in the product type for a match
        for (String brandName in brands) {
          if (normalizedWords.contains(brandName.toLowerCase())) {
            brand = brandName;
            brandFound = true;

            // Filter items based on the selected brand
            noItems = filterSearchItems();

            // Respond based on whether items were found or not
            if (noItems == 0) {
              response ="Sorry, no items found for the brand $brand in the selected product type.";
            } else {
              response ="$brand brand searched, and number of items found was $noItems.";
            }
            break;
          }
        }
      }
    } else {
      response = "Sorry, the product type $productType is not available.";
    }

    // If brand not found
    if (!brandFound) {
      searchedItems.clear();
      response = "Sorry, this brand is not available.";
    }

    setState(() {});

  }


  void describeItemFunc() {
    response = describeItem(searchedItems, productType, quantity, brand);
  }

void addToCart() {
  // Check if there is only one item in the searchedItems list
  if (searchedItems.length == 1) {
    // If only one item is found, add it to the items list (cart)
    GroceryItem searchedItem = searchedItems[0];

    Item newItem = Item(
      productId: searchedItem.productID,
      name: searchedItem.name,
    );

    // Add the new item to the items list
    items.add(newItem);
    saveIntoSp();
    // Optionally, print or provide a confirmation message
    response = '${newItem.name} has been added to the cart.';
    
  } else {
    // If more than one item is found, prompt the user to refine their search
    response = "Please refine your search until only one item is left";
  }
}

void viewCart() {
    List<Item> cartItems = readFromSp();

    // Display cart items in an alert dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Items in Cart"),
          content: cartItems.isEmpty
              ? Text("Your cart is empty.")
              : SizedBox(
                  height: 200, // Adjust height as needed
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text("Product ID: ${item.productId}"),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }


  void clearSearch() {
    // Clear the search-related variables
    previousType = productType;
    productType = "";
    quantity = "";
    quantityValue = "";
    quantityUnit = "";
    brand = "";

    searchedItems.clear();
    response = "Previous search cleared. Ready for a new search.";

  }

  void listProductTypes() {

    String productList = productTypes.join(", ");
    response = "The available product types are: $productList.";
    speak(response);
  }

  void listBrandFunc(){
    response = listBrands(productType,brandList);
  }

// Function to tell the user what product type was searched
  void productSearched() {
    if (productType.isNotEmpty) {
      response ="The previous product type you searched for was $previousType.";
    } else {
      response ="You haven't searched for any product type yet.";
    }
  }

  bool _speechEnabled = false;
  String wordsSpoken = "";
  String response = "";
  String productType = "";
  String quantity = "";
  String brand = "";
  String quantityValue = ""; // Numeric part of quantity
  String quantityUnit = ""; // Unit part of quantity
  int noItems = 0;
  String previousType = "";

  @override
  void initState() {
    getSharedPreferences();
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

  // Function to process recognized voice commands
  void processCommand(SpeechRecognitionResult result) {
    String spokenWords = result.recognizedWords.toLowerCase();

    // Handle "repeat" command
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

    if (spokenWords.contains("clear search")) {
      clearSearch();
      setState(() {
        wordsSpoken = spokenWords;
      });
      speak(response);
      return;
    }

    if (spokenWords.contains("product types")) {
      listProductTypes();
      setState(() {
        wordsSpoken = spokenWords;
      });
      return;
    }

    if (spokenWords.contains("product type searched")) {
      productSearched();
      setState(() {
        wordsSpoken = spokenWords;
      });
      return;
    }

    // Check for "help" command first
    if (spokenWords.contains("help")) {
      response = getResponse("help");
      setState(() {
        wordsSpoken = spokenWords;
      });
      speak(response);
      return;
    } else if (spokenWords.contains("searching")) {
      response = getResponse("searching");
      setState(() {
        wordsSpoken = spokenWords;
      });
      speak(response);
      return;
    } else if (spokenWords.contains("product type")) {
      processProductType(spokenWords);
    } else if (spokenWords.contains("quantity")) {
      processQuantity(spokenWords);
    } else if (spokenWords.contains("brands")) {
      listBrandFunc();
    } else if (spokenWords.contains("brand")) {
      processBrand(spokenWords);
    } else if (spokenWords.contains("describe item")) {
      describeItemFunc();
    } else if (spokenWords.contains("add item to cart")) {
      addToCart();
    }  else {
      // If none of the keywords match, set response to prompt the user again
      response = getResponse("error");
    }

    setState(() {
      wordsSpoken = spokenWords;
    });

    speak(response);
  }

 

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      processCommand(result);
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

  speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1);
    await flutterTts.speak(text);
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Online order page"),
      ),
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Display spoken words
          Text(
            "Words spoken: $wordsSpoken",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Button to toggle listening
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

          // Button to view cart
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: viewCart,
            child: Text("View Cart"),
          ),

          // Show filtered items in a list
          const SizedBox(height: 40),
          Expanded(
            child: searchedItems.isEmpty
                ? const Center(child: Text("No items found."))
                : ListView.builder(
                    itemCount: searchedItems.length,
                    itemBuilder: (context, index) {
                      GroceryItem item = searchedItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                              "Type: ${item.type}\nBrand: ${item.brand}\nPrice: \$${item.price}\nQuantity: ${item.quantity} ${item.unit}"),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}