import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert'; // Add this import for JSON decoding
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Upload Example',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Uint8List? _selectedImageBytes;
  String? _prediction;

  final List<String> classNames = [
    // ... Class names (omitted for brevity)
  ];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final Uint8List imageBytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = imageBytes;
      });

      print(
          'Image picked and converted to bytes. Image size: ${imageBytes.length} bytes.');

      // Send image to the backend and get response
      final prediction = await _sendImageToBackend(imageBytes);
      setState(() {
        _prediction = prediction;
      });

      print('Prediction from backend: $_prediction');
    } else {
      print('No image selected.');
    }
  }

  Future<String?> _sendImageToBackend(Uint8List imageBytes) async {
    final uri = Uri.parse('http://127.0.0.1:8000/predict/');
    final request = http.MultipartRequest('POST', uri);

    print('Sending request to $uri');

    request.files.add(http.MultipartFile.fromBytes('image', imageBytes,
        filename: 'image.png'));

    try {
      final streamedResponse = await request.send();
      print('Request sent. Status code: ${streamedResponse.statusCode}');

      final response = await http.Response.fromStream(streamedResponse);
      print('Response received. Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = utf8.decode(response.bodyBytes);
        print('Response body: $responseData');

        // Parse the JSON response
        final Map<String, dynamic> jsonResponse = jsonDecode(responseData);
        final predictionValue = jsonResponse['prediction'];

        return predictionValue.toString();
      } else {
        print('Error: ${response.reasonPhrase}');
        return 'Error: ${response.reasonPhrase}';
      }
    } catch (e) {
      print('Exception occurred: $e');
      return 'Exception: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedImageBytes != null)
              Image.memory(
                _selectedImageBytes!,
                height: 200,
              ),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Upload Image'),
            ),
            if (_prediction != null) Text('Prediction: $_prediction'),
          ],
        ),
      ),
    );
  }
}
