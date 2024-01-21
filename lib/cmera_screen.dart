import 'package:camera/camera.dart';
//import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
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
        actions: [
          // IconButton(
          //   onPressed: () {
          //     _toggleFlash();
          //   },
          //   icon: Icon(
          //     isFlashOn ? Icons.flash_on : Icons.flash_off,
          //   ),
          // ),
          Switch(
      value: isFlashOn,
      onChanged: (value) {
        _toggleFlashManually();
      },
    ),
        ],
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
    await _controller.setFlashMode(isFlashOn ? FlashMode.off : FlashMode.torch);
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

    try {
      // Process the image and get the recognized text
      final RecognizedText recognisedText =
          await textRecognizer.processImage(inputImage);

      // Extract and print the recognized text
      String extractedText = recognisedText.text;
      print("Extracted Text:\n$extractedText");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(extractedText: extractedText),
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
