import 'package:see_for_me/models/groceryItem.dart';

String describeItem(List<GroceryItem> items, String productType, String weight, String brand ,String weightUnit) {
  String response;

  if (items.isEmpty) {
    // No items found at all
    if (productType.isEmpty && weight.isEmpty && brand.isEmpty) {
      response = "Please search for an item.";
    } else {
      // User searched with product type, quantity, and brand but no item found
      response = "No items found under the product type '$productType', weight '$weight' '$weightUnit' , and brand '$brand'.";
    }
  } else if (items.length == 1) {
    // One item found, describe the item
    var item = items[0];
    response = "Item found: ${item.name} with price Rs ${item.price} and weight available is ${item.weight} ${item.unit}.";
  } else {
    // Multiple items found, no description given
    response = "Multiple items found. Please refine your search by specifying all requirements: brand and weight.";
  }
  return response;
}

String listBrands(String productType,List<Map<String, List<String>>> brandList) {

  String response = "";

    // Check if product type has been mentioned
    if (productType.isEmpty) {
      response ="Please specify the product type first to list the available brands.";
    } else {
      // Check for the brands under the specified product type
      bool productTypeFound = false;
      for (var category in brandList) {
        if (category.containsKey(productType.toLowerCase())) {
          productTypeFound = true;
          List<String> brands = category[productType.toLowerCase()]!;

          // List the available brands for the mentioned product type
          response = "The available brands for $productType are: ${brands.join(', ')}.";
          break;
        }
      }

      if (!productTypeFound) {
        response = "Sorry, no brands available for the specified product type.";
      }

    }

    return response;
  }

