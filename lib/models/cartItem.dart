class Item{
  String productId;
  String name;
  int? quantity;
  double price;
  Item({required this.productId, required this.name ,required this.price ,this.quantity = 1});

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        productId: json["productId"],
        name: json["name"],
        price: (json["price"] ?? 0.0).toDouble(),
        quantity: json["quantity"] ?? 1, 
    );

    Map<String, dynamic> toJson() => {
        "productId": productId,
        "name": name,
        "price": price,
        "quantity": quantity,
    };
}