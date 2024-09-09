// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';

// class ShoppingList {
//   List<String> _items = [];

//   ShoppingList() {
//     _loadList();
//   }

//   List<String> get items => _items;

//   void addItem(String item) {
//     _items.add(item);
//     _saveList();
//   }

//   void removeItem(String item) {
//     _items.remove(item);
//     _saveList();
//   }

//   String readList() {
//     if (_items.isEmpty) {
//       return 'Your shopping list is empty';
//     } else {
//       return 'Your shopping list: ${_items.join(', ')}';
//     }
//   }

//   Future<void> _saveList() async {
//     final prefs = await SharedPreferences.getInstance();
//     final String encodedList = json.encode(_items);
//     await prefs.setString('shopping_list', encodedList);
//   }

//   Future<void> loadList() async {  // Changed from _loadList to loadList
//     final prefs = await SharedPreferences.getInstance();
//     final String? encodedList = prefs.getString('shopping_list');
//     if (encodedList != null) {
//       _items = List<String>.from(json.decode(encodedList));
//     }
// }


import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ShoppingList {
  List<String> _items = [];
  Set<String> _readItems = {};

  List<String> get items => _items;

  void addItem(String item) {
    _items.add(item);
    _saveList();
  }

  void removeItem(String item) {
    _items.remove(item);
    _readItems.remove(item);
    _saveList();
  }

  String readList() {
    if (_items.isEmpty) {
      return 'Your shopping list is empty';
    } else {
      return 'Your shopping list contains: ${_items.join(', ')}';
    }
  }

  String? getNextUnreadItem() {
    for (var item in _items) {
      if (!_readItems.contains(item)) {
        return item;
      }
    }
    return null;
  }

  void markItemAsRead(String item) {
    _readItems.add(item);
  }

  void resetReadItems() {
    _readItems.clear();
  }

  void clearList() {
    items.clear();
  }

  Future<void> _saveList() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = json.encode(_items);
    await prefs.setString('shopping_list', encodedList);
  }

  Future<void> loadList() async {  // Changed from _loadList to loadList
    final prefs = await SharedPreferences.getInstance();
    final String? encodedList = prefs.getString('shopping_list');
    if (encodedList != null) {
      _items = List<String>.from(json.decode(encodedList));
    }
  }


}