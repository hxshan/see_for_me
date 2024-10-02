import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:see_for_me/models/cartItem.dart'; //cart class
import 'package:shared_preferences/shared_preferences.dart'; //shared preference
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:see_for_me/models/groceryItem.dart'; //importing class and mock data
import 'package:see_for_me/ordering/searchFuncions.dart';
import 'package:see_for_me/ordering/searchResponses.dart'; //responses
import 'package:http/http.dart' as http;
import 'package:see_for_me/ordering/misrecognizeCommands.dart';

class OrderingPage extends StatefulWidget {
  const OrderingPage({super.key});

  @override
  State<OrderingPage> createState() => _OrderingPageState();
}

class _OrderingPageState extends State<OrderingPage> {
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();

  late SharedPreferences sp;

  getSharedPreferences() async {
    sp = await SharedPreferences.getInstance();
  }

//Function to save item data to shared preference
  saveIntoSp() {
    List<String> itemListString =
        items.map((item) => jsonEncode(item.toJson())).toList();
    sp.setStringList("myCart", itemListString);
  }

//Function to clear data from shared preference
  Future<void> clearCartFromSharedPreferences() async {
    sp.remove('myCart');
    print("Cart has been cleared from SharedPreferences.");
  }

//Function to read item data from shared preference
  List<Item> readFromSp() {
    List<String>? itemListString = sp.getStringList("myCart");

    if (itemListString != null) {
      return itemListString
          .map((item) => Item.fromJson(json.decode(item)))
          .toList();
    } else {
      return [];
    }
  }

  final List<Map<String, List<String>>> brandList = []; //list of all brands from supermarket
  final List<String> productTypes = []; //list of all product types from supermarket
  List<GroceryItem> groceryItems = []; //list of all products from supermarket
  final List<GroceryItem> searchedItems = []; //list of all searched items
  List<Item> items = List.empty(growable: true); //list of all added items

  bool _speechEnabled = false;
  String wordsSpoken = ""; //User spoken words
  String response = ""; //Respose to the user
  String productType = ""; //product type storage
  String weight = ""; //weight storage
  String brand = ""; //brand storage
  String weightValue = ""; // Numeric part of weight
  String weightUnit = ""; // Unit part of weight
  int noItems = 0; //number of items
  String previousType = ""; //previous search product type

//Function to get brands
  Future<void> fetchBrandData() async {
    final url = Uri.parse('http://10.0.2.2:5224/api/ProductType');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        for (var productType in data) {
          String productTypeName = productType['name'];
          List<String> brandNames = [];
          for (var brand in productType['brands']) {
            brandNames.add(brand['name']);
          }
          brandList.add({productTypeName: brandNames});
        }

        print('Brand List: $brandList');
      } else {
        print('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

//Function to get product types
  Future<void> fetchProductTypes() async {
    final url = Uri.parse('http://10.0.2.2:5224/api/ProductType/justtypes');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<String> fetchedProductTypes = List<String>.from(data);

        productTypes.addAll(fetchedProductTypes);

        print('Updated Product Types: $productTypes');
      } else {
        print(
            'Failed to load product types. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

//Function to get all products
  Future<void> fetchProducts() async {
    final url = Uri.parse('http://10.0.2.2:5224/api/Product');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        List<GroceryItem> fetchedItems = data.map((item) {
          return GroceryItem(
            productID: item['id'].toString(),
            name: item['productName'],
            type: item['type']['name'],
            brand: item['brand']['name'],
            price: item['unitprice'].toDouble(),
            weight: double.parse(item['unitWeight']),
            unit: item['unit'] ?? '',
          );
        }).toList();
        groceryItems = fetchedItems;
        print('Grocery items updated: $groceryItems');
      } else {
        print('Failed to load products. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

//List of units for unit validation
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
  };

//list of all misrecognized brand names
  final Map<String, String> misrecognizedWords = {
    "melbourne": "Maliban",
    "ankhor": "Anchor",
  };

//Function to get responses from predefined texts
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

//Function to remove all items from cart
void removeAllItems() {
  if (items.isEmpty) {
    response = "There are no items in your cart to remove.";
  } else {
    clearCartFromSharedPreferences();
    response = "All items have been removed from the cart.";
  }
}

//Function to filter items from search list
  int filterSearchItems() {
    searchedItems.clear();

    int matchedItemsCount = 0;

    // Filter groceryItems based on the selected productType, Weight, and brand
    for (var item in groceryItems) {
      bool matchesType = productType.isEmpty ||
          item.type.toLowerCase() == productType.toLowerCase();
      bool matchesWeight = weight.isEmpty
          ? true
          : item.unit == weightUnit &&
              item.weight == (double.tryParse(weightValue) ?? 0.0);
      bool matchesBrand =
          brand.isEmpty || item.brand.toLowerCase() == brand.toLowerCase();

      if (matchesType && matchesWeight && matchesBrand) {
        searchedItems.add(item);
        matchedItemsCount++;
      }
    }

    return matchedItemsCount;
  }

//Function to filter based on product type
  void processProductType(String spokenWords) {
    String normalizedWords = spokenWords.toLowerCase();

    weight = "";
    weightValue = "";
    weightUnit = "";
    bool productTypeFound = false;

    // Check each product type for an exact match
    for (String type in productTypes) {
      if (normalizedWords.contains(type.toLowerCase())) {
        productType = type;
        productTypeFound = true;

        if (previousType.isEmpty || previousType == productType) {
          // If no previous type or the same product type is mentioned
          noItems = filterSearchItems();
          response =
              "$productType product type searched and number of items found was $noItems";
        } else if (previousType != productType) {
          // If a different product type is mentioned
          noItems = filterSearchItems();
          response =
              "Changed to $productType. Number of items found was $noItems";
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

//Function to filter based on weight
  void processWeight(String spokenWords) {
    String normalizedWords = spokenWords.toLowerCase();
    List<String> words = normalizedWords
        .split(RegExp(r'\s+')); // Handle multiple spaces and punctuation

    String possibleWeight = "";
    String possibleUnit = "";

    if (productType.isEmpty) {
      response = "please specify the product type you want first";
      return;
    }

    for (int i = 0; i < words.length; i++) {
      if (double.tryParse(words[i]) != null) {
        possibleWeight = words[i];
      } else if (unitMap.containsKey(words[i])) {
        possibleUnit = unitMap[words[i]] ?? "";
      }
    }

    if (possibleWeight.isNotEmpty && possibleUnit.isNotEmpty) {
      weightValue = possibleWeight;
      weightUnit = possibleUnit;
      weight = "$weightValue $weightUnit";

      noItems = filterSearchItems();
      if (noItems > 0) {
        response =
            "Weight $weight is available and the number of items found was $noItems for $productType";
      } else {
        response = "Weight $weight is not available for $productType";
      }
    } else {
      if (possibleWeight.isEmpty) {
        response = "Sorry, I couldn't find a Weight in your request.";
      } else if (possibleUnit.isEmpty) {
        response =
            "Sorry, I couldn't find a valid unit. Please specify a valid unit like liters, kilograms, etc.";
      }
    }

    setState(() {});
  }

//Function to filter based on brand
  void processBrand(String spokenWords) {
    String normalizedWords = spokenWords.toLowerCase();
    bool brandFound = false;

    if (productType.isEmpty) {
      response = "Please specify the product type first.";
      speak(response);
      return;
    }

    if (weight.isEmpty) {
      response = "Please specify the Weight first.";
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
    if (brandList
        .any((category) => category.containsKey(productType.toLowerCase()))) {
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
              response =
                  "Sorry, no items found for the brand $brand in the selected product type.";
            } else {
              response =
                  "$brand brand searched, and number of items found was $noItems.";
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

//Function to describe an item
  void describeItemFunc() {
    response = describeItem(searchedItems, productType, weight, brand);
  }

//Function to announce current page
  void announceCurrentPage(String pageName) {
    response = "You are currently on the $pageName page.";
  }

//Function to add item to cart
  void addToCart() {
    if (searchedItems.length == 1) {
      GroceryItem searchedItem = searchedItems[0];
      List<Item> currentCartItems = readFromSp();

      bool itemExists = currentCartItems
          .any((item) => item.productId == searchedItem.productID);

      if (itemExists) {
        response = '${searchedItem.name} is already in the cart.';
      } else {
        Item newItem = Item(
            productId: searchedItem.productID,
            name: searchedItem.name,
            price: searchedItem.price);

        // Add the new item to the current cart items list
        currentCartItems.add(newItem);

        // Update the items list with the combined list
        items = currentCartItems;

        // Save the updated cart back to SharedPreferences
        saveIntoSp();
        response = '${newItem.name} has been added to the cart.';
      }
    } else {
      response = "Please refine your search until only one item is left.";
      speak(response);
    }
  }

//Function to get item count from cart
  void getCartItemCount() {
    List<Item> currentCartItems = readFromSp();

    int itemCount = currentCartItems.length;

    if (itemCount == 0) {
      response = "Your cart is empty.";
    } else {
      response = "You have $itemCount items in your cart.";
    }
  }

//Snipet to view current cart items for checking
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

//Function to clear search and start a new search
  void clearSearch() {
    previousType = productType;
    productType = "";
    weight = "";
    weightValue = "";
    weightUnit = "";
    brand = "";

    searchedItems.clear();
    response = "Previous search cleared. Ready for a new search.";
  }

//Function to list all product types to user
  void listProductTypes() {
    String productList = productTypes.join(", ");
    response = "The available product types are: $productList.";
  }

//Function to list all brands to user
  void listBrandFunc() {
    response = listBrands(productType, brandList);
  }

// Function to tell the user what product type was searched
  void productSearched() {
    if (productType.isNotEmpty) {
      response =
          "The previous product type you searched for was $previousType.";
    } else {
      response = "You haven't searched for any product type yet.";
    }
  }

//Function to redirect user to manage cart page
  void manageCart() {
    response = "Navigating to the Cart Management Page";
    Navigator.pushNamed(context, '/cart');
  }

  @override
  void initState() {
    getSharedPreferences();
    super.initState();
    _initSpeech();
    fetchBrandData(); //to fetch brands
    fetchProductTypes(); //to fetch product types
    fetchProducts(); //to fetch all products
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



String correctMisrecognizedWords(String spokenWords) {
  misrecognizedCommands.forEach((wrong, correct) {
    if (spokenWords.contains(wrong)) {
      spokenWords = spokenWords.replaceAll(wrong, correct);
    }
  });
  return spokenWords;
}


// Function to process recognized voice commands
  void processCommand(SpeechRecognitionResult result) {
    String spokenWords = result.recognizedWords.toLowerCase();

    spokenWords = correctMisrecognizedWords(spokenWords);

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
      //Handle "clear search" command
      clearSearch();
    } else if (spokenWords.contains("clear cart")) {
      //Handle "clear" command which will clear all items in cart
      removeAllItems();
    } else if (spokenWords.contains("product types")) {
      //Handle "product types" command which will retuen all types to user
      listProductTypes();
    } else if (spokenWords.contains("help")) {
      // Check for "help" command first
      response = getResponse("help");
    } else if (spokenWords.contains("searching")) {
      response = getResponse("searching");
    } else if (spokenWords.contains("product type")) {
      processProductType(spokenWords);
    } else if (spokenWords.contains("wait")) {
      processWeight(spokenWords);
    } else if (spokenWords.contains("brands")) {
      listBrandFunc();
    } else if (spokenWords.contains("brand")) {
      processBrand(spokenWords);
    } else if (spokenWords.contains("describe item")) {
      describeItemFunc();
    } else if (spokenWords.contains("add item")) {
      addToCart();
    } else if (spokenWords.contains("amount")) {
      getCartItemCount();
    } else if (spokenWords.contains("manage card")) {
      manageCart();
    } else if (spokenWords.contains("current page")) {
      announceCurrentPage("Ordering");
    } else {
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
                              "Type: ${item.type}\nBrand: ${item.brand}\nPrice: \Rs ${item.price}\nWeight: ${item.weight} ${item.unit}"),
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
