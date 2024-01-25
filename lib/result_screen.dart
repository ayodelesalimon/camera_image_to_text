// result_page.dart

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResultPage extends StatefulWidget {
  final String extractedText;
  final String imagePath;
  final String address;
  final String base64Image;

  const ResultPage(
      {super.key,
      required this.imagePath,
      required this.extractedText,
      required this.address,
      required this.base64Image});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(
          random.nextInt(chars.length),
        ),
      ),
    );
  }

  String dateNow = DateTime.now().toString();

  getTime() {
    DateTime now = DateTime.now();
    String dateString = now.toString();
    print("Current date and time: $dateString");
  }

  @override
  void initState() {
    getTime();
    // TODO: implement initState
    super.initState();
  }

  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Text Extraction Result'),
      ),
      bottomNavigationBar: Container(
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
                onPressed: () async {
                  setState(() {
                    isLoading = true;
                  });
                  await Supabase.instance.client.from('Readings').insert({
                    'name': generateRandomString(10),
                    'created_at': DateTime.now().toString(),
                    'location': widget.address,
                    'tank_name': widget.extractedText,
                    'reading_type': 'Open',
                    'image_path': widget.base64Image,
                  }).whenComplete(() {
                    setState(() {
                      isLoading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Data saved successfully!')));
                    Navigator.pop(context);
                  });
                },
                child: Text('Save')),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel')),
          ],
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Image.file(
                      File(widget.imagePath),
                      width: double.infinity,
                      height: 500,
                      fit: BoxFit.cover,
                    ),
                    SizedBox(
                      height: 16.0,
                    ),
                    Text(
                      widget.extractedText,
                      style: TextStyle(fontSize: 18.0),
                    ),
                    SizedBox(
                      height: 16.0,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
