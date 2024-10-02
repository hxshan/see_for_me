class Product {
  final int id;
  final String productName;

  Product({
    required this.id,
    required this.productName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      productName: json['productName'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
    };
  }
}
