class GroceryItem {
  final String productID;
  final String name;
  final String type;
  final String brand;
  final double price;
  final double weight;
  final String unit;

  GroceryItem({
    required this.productID,
    required this.name,
    required this.type,
    required this.brand,
    required this.price,
    required this.weight,
    required this.unit
  });

  @override
  String toString() {
    return '''
    Product ID : $productID
    Item Name: $name
    Brand: $brand
    Type: $type
    Price: \$${price.toStringAsFixed(2)}
    Weight: ${weight.toStringAsFixed(2)} $unit
    ''';
  }
}

