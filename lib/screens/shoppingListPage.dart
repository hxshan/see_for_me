import 'package:flutter/material.dart';
import 'shoppingList.dart';

class ShoppingListPage extends StatefulWidget {
  @override
  _ShoppingListPageState createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final ShoppingList _shoppingList = ShoppingList();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _shoppingList.loadList().then((_) => setState(() {}));
  }

  void _addItem(String item) {
    if (item.isNotEmpty) {
      setState(() {
        _shoppingList.addItem(item);
      });
      _textController.clear();
    }
  }

  void _removeItem(String item) {
    setState(() {
      _shoppingList.removeItem(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Enter an item',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _addItem,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addItem(_textController.text),
                  child: Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _shoppingList.items.length,
              itemBuilder: (context, index) {
                final item = _shoppingList.items[index];
                return ListTile(
                  title: Text(item),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _removeItem(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}