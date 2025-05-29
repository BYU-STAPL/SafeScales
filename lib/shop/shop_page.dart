import 'package:flutter/material.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {

  @override
  Widget build(BuildContext context) {

    ThemeData theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text("Shop will go here")
          ],
        ),
      ),// This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}