import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class GroceryItem {
  final String name;
  final String type;
  final String brand;
  final double price;
  final double quantity;
  final String unit;

  GroceryItem({
    required this.name,
    required this.type,
    required this.brand,
    required this.price,
    required this.quantity,
    required this.unit
  });

  @override
  String toString() {
    return '''
    Item Name: $name
    Brand: $brand
    Type: $type
    Price: \$${price.toStringAsFixed(2)}
    Quantity: ${quantity.toStringAsFixed(2)} $unit
    ''';
  }
}

// Sample grocery items, including brands and quantities
final List<GroceryItem> groceryItems = [
  GroceryItem(
    name: "Anchor Milk Powder",
    type: "milk powder",
    brand: "Anchor",
    price: 4.99,
    quantity: 500,
    unit:"g"
  ),
  GroceryItem(
    name: "Anchor Milk Powder",
    type: "milk powder",
    brand: "Anchor",
    price: 4.99,
    quantity: 1,
    unit:"kg"
  ),
  GroceryItem(
    name: "Maliban Milk",
    type: "milk",
    brand: "Maliban",
    price: 5.49,
    quantity: 1.2,
    unit:"l"
  ),
  GroceryItem(
    name: "Maliban Milk",
    type: "milk",
    brand: "Maliban",
    price: 5.49,
    quantity: 2,
     unit:"l"
  ),
  GroceryItem(
    name: "fanta orange",
    type: "soda",
    brand: "fanta",
    price: 5.49,
    quantity: 2,
     unit:"l"
  ),
  GroceryItem(
    name: "fanta lime",
    type: "soda",
    brand: "fanta",
    price: 5.49,
    quantity: 1,
     unit:"l"
  ),
  // Add more products as needed
];


class OrderingPage extends StatefulWidget {
  const OrderingPage({super.key});

  @override
  State<OrderingPage> createState() => _OrderingPageState();
}
class _OrderingPageState extends State<OrderingPage> {
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();


  final List<Map<String, String>> responses = [
    {"productType": "Please say the type of product you want to search for."},

    {"Quantity": "Please specify the quantity in liters or grams "},

    {"brand": "Please say the brand you prefer."},

    {"change": "Changing product"},

    {"search":"searching product type"},

    {"add": "To add this item to your cart, say 'Add item to cart'."},

    {"help": '''these are the following help commands:
    - Say commands for searching and adding an item".
    - say commands for editiing the shopping cart".
    - say commands for proceeding to checkout".
    '''},

    {"error": "Sorry, I didn't understand that."},
  ];

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

  final List<String> brandList = [
  "Maliban",
  "Anchor",
];





  final List<Map<String,String>>  helpResponses = [

    {"searching": '''Here are the steps you should follow:
  - Start by saying "search" and then wait for the system to respond, or you can directly say the product type by saying "product type" followed by the type.
  - Next, specify the quantity of the product you want by saying "quantity" followed by the amount and unit (e.g., 500 grams or 1 liter).
  - Then, say the brand name you prefer by saying "brand" followed by the brand name.
  - You can ask for a description of the item you just searched for by saying "describe the item."
  - Finally, say "add to cart" to add the currently selected item to your cart.
  '''}

  ];

String getResponse(String key) {

    if(key.contains("searching")){
      for (var response in helpResponses) {
      if (response.containsKey(key)) {
        return response[key]!;
      }
    }
    return "Sorry, I didn't understand that.";
    }else {
       for (var response in responses) {
      if (response.containsKey(key)) {
        return response[key]!;
      }
    }
    return "Sorry, I didn't understand that.";
    }
   
  }

  final List<GroceryItem> searchedItems = [
];

int filterSearchItems() {
  // Clear the previous search results
  searchedItems.clear();

  int matchedItemsCount = 0;

  // Filter groceryItems based on the selected productType, quantity, and brand
  for (var item in groceryItems) {
    bool matchesType = productType.isEmpty || item.type.toLowerCase() == productType.toLowerCase();
    bool matchesQuantity = quantity.isEmpty
        ? true
        : item.unit == quantityUnit && item.quantity == (double.tryParse(quantityValue) ?? 0.0);
    bool matchesBrand = brand.isEmpty || item.brand.toLowerCase() == brand.toLowerCase();

    if (matchesType && matchesQuantity && matchesBrand) {
      searchedItems.add(item);
      matchedItemsCount++;
    }
  }

  return matchedItemsCount;
}

//String message = "";
// Function to extract the product type from spoken words
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
        response = "$productType product type searched and number of items found was $noItems";
      } else if (previousType != productType) {
        // If a different product type is mentioned
        noItems = filterSearchItems();
        response = "Changed to $productType. Number of items found was $noItems";
      }

      previousType = productType;

      print(previousType);
      break;
    }
  }

  if (!productTypeFound) {
    response = "Sorry, this product type is not available.";
  }

  // Update the UI with the response
  setState(() {
    wordsSpoken = spokenWords;
  });

  // Speak the response to the user
  speak(response);
}

void processQuantity(String spokenWords) {
  // Normalize spoken words by converting to lowercase
  String normalizedWords = spokenWords.toLowerCase();

  // Split the spoken words into individual words
  List<String> words = normalizedWords.split(RegExp(r'\s+')); // Handle multiple spaces and punctuation

  // Extract possible quantity and unit
  String possibleQuantity = "";
  String possibleUnit = "";

   if(productType.isEmpty){
      response = "please specify the product type you want first";
      speak(response);
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
    if(noItems > 0){
      response = "quantity" + quantity + "is available" + " and number of items found was" + '$noItems for $productType' ;
    }else{
      response = "quantity" + quantity + "is not available for" + '$productType';
    }
    
    // Update the state and speak the response
    
    setState(() {});
    speak(response);
  } else {
    // Handle missing quantity or unit
    if (possibleQuantity.isEmpty) {
      response = "Sorry, I couldn't find a quantity in your request.";
    } else if (possibleUnit.isEmpty) {
      response = "Sorry, I couldn't find a valid unit. Please specify a valid unit like liters, kilograms, etc.";
    }
    setState(() {});
    speak(response);
  }
}

void processBrand(String spokenWords) {
  // Normalize spoken words by converting to lowercase
  String normalizedWords = spokenWords.toLowerCase();

  bool brandFound = false;

  // Check each brand for an exact match
  for (String brandName in brandList) {
    if (normalizedWords.contains(brandName.toLowerCase())) {
      brand = brandName;
      brandFound = true;

      // Filter items based on the selected brand
      noItems = filterSearchItems();
      
      // If no items are found
      if (noItems == 0) {
        response = "Sorry, no items found for the brand $brand in the selected product type.";
      } else {
        // If items exist, send a response indicating success
        response = "$brand brand searched, and number of items found was $noItems.";
      }

      print("User mentioned brand: $brand");
      break;
    }
  }

  if (!brandFound) {
    response = "Sorry, this brand is not available.";
  }

  // Update the UI with the response
  setState(() {
    wordsSpoken = spokenWords;
  });

  // Speak the response to the user
  speak(response);
}

void clearSearch() {
  // Clear the search-related variables
  previousType = productType;
  productType = "";
  quantity = "";
  quantityValue = "";
  quantityUnit = "";
  brand = "";
  
  // Clear any previously searched items
  searchedItems.clear();

  // Set the response for the cleared search
  response = "Previous search cleared. Ready for a new search.";

  // Update the UI
  setState(() {});

  // Speak the response
  speak(response);
}

void listProductTypes() {
  // Create a response string with the product types
  String productList = productTypes.join(", ");
  
  // Set the response with the available product types
  response = "The available product types are: $productList.";

  // Update the UI
  setState(() {});

  // Speak the response
  speak(response);
}

// Function to tell the user what product type was searched
void productSearched() {
  if (productType.isNotEmpty) {
    response = "The previous product type you searched for was $previousType.";
  } else {
    response = "You haven't searched for any product type yet.";
  }

  setState(() {});
  speak(response);
}


  bool _speechEnabled = false;
  String wordsSpoken = "";
  String response = "";
  String productType = "";
  String quantity = "";
  String brand = "";
  String currentStep = "search";  // Track the current step
  //GroceryItem? selectedItem;
String quantityValue = "";  // Numeric part of quantity
String quantityUnit = "";  // Unit part of quantity
int noItems = 0;
String previousType = "";

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

    // Function to process recognized voice commands
  void processCommand(SpeechRecognitionResult result) {
    String spokenWords = result.recognizedWords.toLowerCase();

    // Handle "repeat" command
  if (spokenWords.contains("repeat")) {
    if (response.isNotEmpty) {
      speak(response);  // Repeat the last response
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
    }else if(spokenWords.contains("searching")){
      response = getResponse("searching");
      setState(() {
        wordsSpoken = spokenWords;
      });
      speak(response);
      return;
    }else if (spokenWords.contains("product type")) {
    processProductType(spokenWords);
    }else if (spokenWords.contains("quantity")) {
    processQuantity(spokenWords);
    }else if(spokenWords.contains("brand")){
    processBrand(spokenWords);
    } else {
    // If none of the keywords match, set response to prompt the user again
    response = getResponse("error");
  }

    setState(() {
      wordsSpoken = spokenWords;
    });

    speak(response);
  }

   void addToCart() {
    log("Adding to cart: $productType, $quantity, $brand");
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
                        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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