import 'package:flutter/material.dart';

void main() {
  runApp(const BizzioApp());
}

class BizzioApp extends StatelessWidget {
  const BizzioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bizzio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bizzio Home'),
      ),
      body: const Center(
        child: Text('Welcome to Bizzio!'),
      ),
    );
  }
}
