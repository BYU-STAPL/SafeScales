import 'package:flutter/material.dart';

class DragonPage extends StatefulWidget {
  const DragonPage({super.key});

  @override
  State<DragonPage> createState() => _DragonPageState();
}

class _DragonPageState extends State<DragonPage> {

  @override
  Widget build(BuildContext context) {

    ThemeData theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text("User's dragons will go here")
          ],
        ),
      ),// This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}