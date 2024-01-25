import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_ml_kit/google_ml_kit.dart';


import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({super.key, required this.camera});
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool isFlashOn = false;

  String? _currentAddress = "";
  Position? _currentPosition;

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
      _getAddressFromLatLng(_currentPosition!);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  getTime() {
    DateTime now = DateTime.now();
    String dateString = now.toString();
    print("Current date and time: $dateString");
  }

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
    _controller.setFlashMode(FlashMode.off);
    _getCurrentPosition();
  }

  @override
  void dispose() {
    // Dispose of the camera controller when the widget is disposed
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera OCR'),
        // actions: [
        //   // IconButton(
        //   //   onPressed: () {
        //   //     _toggleFlash();
        //   //   },
        //   //   icon: Icon(
        //   //     isFlashOn ? Icons.flash_on : Icons.flash_off,
        //   //   ),
        //   // ),
        //   Switch(
        //     value: isFlashOn,
        //     onChanged: (value) {
        //       _toggleFlashManually();
        //     },
        //   ),
        // ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the camera preview
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            // Ensure the camera is initialized
            await _initializeControllerFuture;
            //  await _toggleFlash();

            // Capture the image
            final image = await _controller.takePicture();

            // Pass the image file to the OCR function
            await extractTextFromImage(image.path);
          } catch (e) {
            print("Error capturing image: $e");
          }
        },
        child: Icon(Icons.camera),
      ),
    );
  }

//  Future<void> extractTextFromImage(String imagePath) async {
//   // Create a FirebaseVisionImage object from the image file
//   final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFilePath(imagePath);

//   // Initialize a TextRecognizer
//   final TextRecognizer textRecognizer = FirebaseVision.instance.textRecognizer();

//   try {
//     // Retrieve the recognized text
//     final VisionText visionText = await textRecognizer.processImage(visionImage);

//     // Extract and print the recognized text
//     String extractedText = "";
//     for (TextBlock block in visionText.blocks) {
//       for (TextLine line in block.lines) {
//         extractedText += "${line.text}\n";
//       }
//     }

//     // Display the extracted text (you can use this however you want)
//     print("Extracted Text:\n$extractedText");
//   } catch (e) {
//     print("Error extracting text: $e");
//   } finally {
//     // Dispose of the textRecognizer
//     textRecognizer.close();
//   }
// }

  void _toggleFlashManually() async {
    if (!_controller.value.isInitialized) {
      return;
    }

    try {
      await _controller
          .setFlashMode(isFlashOn ? FlashMode.off : FlashMode.torch);
      setState(() {
        isFlashOn = !isFlashOn;
      });
    } catch (e) {
      print("Error toggling flash: $e");
    }
  }

  Future<void> _toggleFlash() async {
    if (!_controller.value.isInitialized) {
      return;
    }

    try {
      await _controller
          .setFlashMode(isFlashOn ? FlashMode.off : FlashMode.torch);
      setState(() {
        isFlashOn = !isFlashOn;
      });
    } catch (e) {
      print("Error toggling flash: $e");
    }
  }

  Future<void> extractTextFromImage(String imagePath) async {
    // Create an image from the image file
    final inputImage = InputImage.fromFilePath(imagePath);

    // Initialize the text recognizer
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final File imageFile = File(imagePath);
    List<int> imageBytes = imageFile.readAsBytesSync();
    String base64Image = base64Encode(imageBytes);
    print(base64Image);

    try {
      // Process the image and get the recognized text
      final RecognizedText recognisedText =
          await textRecognizer.processImage(inputImage);

      // Extract and print the recognized text
      String extractedText = recognisedText.text;
      print("Extracted Text:\n$extractedText");
      setState(() {
        isFlashOn = false;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(
            extractedText: extractedText,
            imagePath: imagePath,
            address: _currentAddress!,
            base64Image: base64Image,
          ),
        ),
      );
    } catch (e) {
      print("Error extracting text: $e");
    } finally {
      // Close the text recognizer
      textRecognizer.close();
    }
  }
}
