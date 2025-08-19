import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/message.dart';
import 'package:flutter_gemma/flutter_gemma_interface.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project_x/model.dart';

class Describe extends StatefulWidget {
  final List<CameraDescription> cameras;
  Model model;
  Describe({
    super.key,
    required this.cameras,
    required this.model,
  });

  @override
  State<Describe> createState() => _DescribeState();
}

class _DescribeState extends State<Describe> {
  late CameraController controller;
  FlutterTts flutterTts = FlutterTts();
  String currentDescription = "Hello !!!";
  bool isProcessing = false;
  bool isInitialized = false;
  final _gemma = FlutterGemmaPlugin.instance;
  InferenceModelSession? chat;
  Uint8List? _selectedImageBytes;
  XFile? _capturedImage;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = CameraController(widget.cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
    initializeTts();
    _initializeModel();
  }

  Future<void> initializeTts() async {
    await flutterTts.setLanguage("en-US"); // Set desired language
    await flutterTts.setSpeechRate(0.5); // Adjust speech rate
    await flutterTts.setVolume(1.0); // Set volume
    await flutterTts.setPitch(1.0);
    List<Map> voices = await flutterTts.getVoices; // Set pitch
    debugPrint(voices as String?);
  }

  Future<void> speakDescription(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> _initializeModel() async {
    speakDescription("Please wait our model is getting ready to assist you");
    if (!await _gemma.modelManager.isModelInstalled) {
      final path =
          '${(await getApplicationDocumentsDirectory()).path}/${widget.model.filename}';
      await _gemma.modelManager.setModelPath(path);
      debugPrint("In isINstalled");
    }

    final model = await _gemma.createModel(
      modelType: super.widget.model.modelType,
      preferredBackend: super.widget.model.preferredBackend,
      maxTokens: 1024,
      supportImage: widget.model.supportImage, // Pass image support
      maxNumImages:
          widget.model.maxNumImages, // Maximum 4 images for multimodal models
    );

    chat = await model.createSession(
      temperature: super.widget.model.temperature,
      randomSeed: 1,
      topK: super.widget.model.topK,
      topP: super.widget.model.topP,
      enableVisionModality: true,
      //tokenBuffer: 256,
      //supportImage: widget.model.supportImage, // Image support in chat
      //supportsFunctionCalls: widget
      //.model.supportsFunctionCalls, // Function calls support from model
      // tools: _tools, // Pass the tools to the chat
    );
    debugPrint("Model Initialized");
    setState(() {
      isInitialized = true;
    });
  }

  Future<void> _takePicture() async {
    speakDescription("Ok, let me see the surrounding. Stay still.");
    setState(() {
      isProcessing = true;
    });
    final image = await controller.takePicture();
    setState(() {
      _capturedImage = image;
    });
    debugPrint("Image captured");
    _handleSubmitted();
  }

  Future<void> _handleSubmitted() async {
    String text = "Describe the image in short with no usage of emojis";
    debugPrint("In _handleSubmitted");
    final bytes = await _capturedImage?.readAsBytes();
    _selectedImageBytes = bytes;
    if (_selectedImageBytes == null) {
      debugPrint("Image is null");
      setState(() {
        isProcessing = false;
      });
      return;
    }

    final message = Message.withImage(
      text: text.trim(),
      imageBytes: _selectedImageBytes!,
      isUser: true,
    );

    processMessage(message);

    _clearImage();
  }

  void _clearImage() {
    setState(() {
      _selectedImageBytes = null;
    });
  }

  Future<void> processMessage(Message message) async {
    await chat?.addQueryChunk(message);
    String res = await chat!.getResponse();
    setState(() {
      isProcessing = false;
      currentDescription = res;
    });
    speakDescription(currentDescription);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Describe')),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: CameraPreview(controller),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isProcessing)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed:
                        !isInitialized || isProcessing ? null : _takePicture,
                    icon: const Icon(Icons.camera_alt, color: Colors.blueGrey),
                    label: const Text(
                      'Describe Scene',
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shadowColor: Colors.blueGrey.withOpacity(0.5),
                      elevation: 8,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: isProcessing || !isInitialized
                        ? null
                        : () => speakDescription(currentDescription),
                    icon: const Icon(Icons.volume_up, color: Colors.blueGrey),
                    label: const Text(
                      'Repeat Description',
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shadowColor: Colors.blueGrey.withOpacity(0.5),
                      elevation: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isInitialized)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Initializing model, please wait...',
                      style: TextStyle(color: Colors.white, fontSize: 18.0),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
