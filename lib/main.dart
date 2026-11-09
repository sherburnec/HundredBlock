import 'package:flutter/material.dart';

void main() => runApp(const HundredBlockApp());

class HundredBlockApp extends StatelessWidget {
  const HundredBlockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Hundred Block',
      home: Scaffold(body: Center(child: Text('Hundred Block'))),
    );
  }
}
