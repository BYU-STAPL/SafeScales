import 'package:flutter/material.dart';

class ToyBoxPage extends StatefulWidget {
  const ToyBoxPage({super.key});

  @override
  State<ToyBoxPage> createState() => _ToyBoxPageState();
}

class _ToyBoxPageState extends State<ToyBoxPage> {

  @override
  Widget build(BuildContext context) {

    ThemeData theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text("Toy Box will go here")
          ],
        ),
      ),// This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}