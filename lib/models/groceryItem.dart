class GroceryItem {
  final String productID;
  final String name;
  final String type;
  final String brand;
  final double price;
  final double quantity;
  final String unit;

  GroceryItem({
    required this.productID,
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

final List<GroceryItem> groceryItems = [
  GroceryItem(
    productID:"12222",
    name: "Anchor Milk Powder",
    type: "milk powder",
    brand: "Anchor",
    price: 4.99,
    quantity: 500,
    unit:"g"
  ),
  GroceryItem(
    productID:"12332",
    name: "Anchor Milk Powder",
    type: "milk powder",
    brand: "Anchor",
    price: 4.99,
    quantity: 1,
    unit:"kg"
  ),
  GroceryItem(
    productID:"14422",
    name: "Maliban Milk",
    type: "milk powder",
    brand: "Maliban",
    price: 5.49,
    quantity: 1,
    unit:"kg"
  ),
  GroceryItem(
    productID:"12222232",
    name: "Maliban Milk",
    type: "milk",
    brand: "Maliban",
    price: 5.49,
    quantity: 1.2,
    unit:"l"
  ),
   GroceryItem(
    productID:"1666622",
    name: "Anchor Milk",
    type: "milk",
    brand: "Anchor",
    price: 5.49,
    quantity: 1.2,
    unit:"l"
  ),
  GroceryItem(
    productID:"12255552",
    name: "Maliban Milk",
    type: "milk",
    brand: "Maliban",
    price: 5.49,
    quantity: 2,
     unit:"l"
  ),
  GroceryItem(
    productID:"12266666",
    name: "fanta orange",
    type: "soda",
    brand: "fanta",
    price: 5.49,
    quantity: 2,
     unit:"l"
  ),
  GroceryItem(
    productID:"1332322",
    name: "fanta lime",
    type: "soda",
    brand: "fanta",
    price: 5.49,
    quantity: 1,
     unit:"l"
  ),
  // Add more products as needed
];