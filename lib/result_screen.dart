// result_page.dart

import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final String extractedText;

  ResultPage({required this.extractedText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Text Extraction Result'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            extractedText,
            style: TextStyle(fontSize: 18.0),
          ),
        ),
      ),
    );
  }
}
