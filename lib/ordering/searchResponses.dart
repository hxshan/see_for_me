final List<Map<String, String>> helpResponses = [
    {
      "searching": '''Here are the steps you should follow:
  - Start by saying "product type" followed by the type of product you want to search for.
  - Next, specify the quantity of the product by saying "quantity" followed by the amount and unit (e.g., 500 grams or 1 liter).
  - Then, say "brand" followed by the brand name you prefer.
  - Listen to the system to hear how many items were found. If only one item is found, you can say "describe the item" to get a description of that item.
  - If you don’t know any product types, you can say "product types" to get a list of available product types.
  - If you don’t know any brands, you can say "brands" to get a list of available brands.
  - If you want to clear the current search, say "clear search."
  '''
    }
  ];

  final List<Map<String, String>> responses = [
    {"productType": "Please say the type of product you want to search for."},
    {"Quantity": "Please specify the quantity in liters or grams "},
    {"brand": "Please say the brand you prefer."},
    {
      "help": '''these are the following help commands:
    - Say the word searching to get information on how to search".
    '''
    },
    {"error": "Sorry, I didn't understand that."},
  ];