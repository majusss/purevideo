import 'package:flutter/material.dart';

class MyListScreen extends StatelessWidget {
  const MyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moja lista'), centerTitle: true),
      body: const Center(child: Text('Ekran mojej listy - w budowie')),
    );
  }
}
