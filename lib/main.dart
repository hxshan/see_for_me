import 'package:flutter/material.dart';
import 'package:see_for_me/screens/OnlineOrderScreens/checkout_page.dart';
import 'package:see_for_me/screens/home_page.dart';
import 'package:see_for_me/screens/locate_item_page.dart';
import 'package:see_for_me/screens/OnlineOrderScreens/ordering_page.dart';
import 'package:see_for_me/screens/OnlineOrderScreens/cart_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/order': (context) => const OrderingPage(),
        '/cart': (context) => const CartPage(),
        '/checkout': (context) => const CheckoutPage(),
        '/map': (context) => const LocateItemPage()
      },
    );
  }
}
