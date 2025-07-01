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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bizzio'),
      ),
      body: const Center(
        child: Text(
          'Welcome to Bizzio!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}