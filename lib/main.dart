import 'package:flutter/material.dart';
import 'package:bizzio/screens/dashboard_screen.dart';

void main() async {
  runApp(const BizzioApp());
}

class BizzioApp extends StatelessWidget {
  const BizzioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Bizzio',
      home: DashboardScreen(),  
    );
  }
}
