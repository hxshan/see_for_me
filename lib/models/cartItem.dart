class Item{
  String productId;
  String name;
  Item({required this.productId, required this.name});

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        productId: json["productId"],
        name: json["name"],
    );

    Map<String, dynamic> toJson() => {
        "productId": productId,
        "name": name,
    };
}