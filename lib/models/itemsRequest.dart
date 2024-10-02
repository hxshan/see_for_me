import 'package:see_for_me/models/cartItem.dart';


class ItemRequest {
  final String userID;
  final List<Item> items;

  ItemRequest({
    required this.userID,
    required this.items,
  });

  // Convert the ItemRequest object to JSON
  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
