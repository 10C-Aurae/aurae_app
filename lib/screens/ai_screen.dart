import 'package:flutter/material.dart';

class AIScreen extends StatelessWidget {

  const AIScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("AI Insights")),
      body: const Center(
        child: Text("AI analysis will appear here"),
      ),
    );

  }
}