import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/message.dart';
import 'package:flutter_gemma/flutter_gemma_interface.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project_x/model.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:ultralytics_yolo/yolo_view.dart';

class SpeechPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  Model model;
  SpeechPage({super.key, required this.cameras, required this.model});

  @override
  State<SpeechPage> createState() => _SpeechPageState();
}

class _SpeechPageState extends State<SpeechPage> {
  late CameraController controller;
  late YOLO yolo;
  FlutterTts flutterTts = FlutterTts();
  String currentDescription = "Hello !!!";
  bool isProcessing = false;
  bool isInitialized = false; ////////////

  final _gemma = FlutterGemmaPlugin.instance;
  InferenceModelSession? chat;

  Uint8List? _selectedImageBytes;
  XFile? _capturedImage;
  String language = "";

  String _wordsSpoken = "";
  List<LocaleName> _speechLocales = [];
  String _currentLocaleId = '';
  bool _speechEnabled = false;
  final SpeechToText _speechToText = SpeechToText();
  double _confidenceLevel = 0;
  List<YOLOResult> currentResults = [];
  bool objectDetection = false;
  String option = "6";

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
    initSpeech();
    initializeYOLO();
  }

  Future<void> initializeTts() async {
    await flutterTts.setLanguage(_currentLocaleId); // Set desired language
    await flutterTts.setSpeechRate(0.5); // Adjust speech rate
    await flutterTts.setVolume(1.0); // Set volume
    await flutterTts.setPitch(1.0);
    List<Map> voices = await flutterTts.getVoices; // Set pitch
    debugPrint(voices as String?);
  }

  Future<void> speakDescription(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> initializeYOLO() async {
    yolo = YOLO(modelPath: 'yolo11n.tflite', task: YOLOTask.detect);
    await yolo.loadModel();
    debugPrint('YOLO model loaded successfully!');
  }

  Future<void> _initializeModel() async {
    speakDescription(
      language == "Hindi (India)"
          ? "कृपया प्रतीक्षा करें, हमारा मॉडल आपकी सहायता के लिए तैयार हो रहा है"
          : "Please wait our model is getting ready to assist you",
    );
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
    await speakDescription(
      language == "Hindi (India)"
          ? "बोलना शुरू करने के लिए, स्क्रीन के निचले आधे हिस्से को दबाएँ। जब आप बोलना समाप्त कर लें, तो इसे फिर से दबाएँ।"
          : "To start speaking, press the bottom half of the screen. Press it again when you've finished.",
    );
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    if (_speechEnabled) {
      _speechLocales = await _speechToText.locales();
      var systemLocale = await _speechToText.systemLocale();
      if (systemLocale != null) {
        _currentLocaleId = systemLocale.localeId;
      }
    }
    setState(() {});
  }

  void _startListening() async {
    objectDetection = false;
    option = "10";
    setState(() {});
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: _currentLocaleId,
    );
    setState(() {
      _confidenceLevel = 0;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    _classifyRequest();
    setState(() {});
  }

  void _classifyRequest() async {
    final message = Message.text(
      text:
          "statement:${_wordsSpoken.trim()}\nOptions: 1.Describe(To provide description of surrounding)\n2.Navigate(To assit go somewhere)\n3.Detect Objects(To tell which all objects are in the surrounding)\n4.Other(Some Informative thing)\n5.None of the above(Gibberish)\nYou are an assistant of a visually impaired person . Use nlp and classify the above statement into one of the options and return only the number u think the statement belong to",
      isUser: true,
    );

    await chat?.addQueryChunk(message);
    option = await chat!.getResponse();

    switch (option) {
      case "1":
        _takePicture();
        break;
      case "2":
        _navigate();
        break;

      case "3":
        _navigate();
        break;

      case "4":
        _navigate();
        break;

      default:
        speakDescription(
          language == "Hindi (India)"
              ? "मैं आपको सुन नहीं सकता"
              : "Cant here you",
        );
        break;
    }
  }

  void _navigate() async {
    await speakDescription(
      language == "Hindi (India)"
          ? "सुविधा उपलब्ध नहीं है"
          : "Feature not available",
    );
  }

  void _onSpeechResult(result) {
    setState(() {
      _wordsSpoken = "${result.recognizedWords}";
      _confidenceLevel = result.confidence;
    });
  }

  Future<void> _takePicture() async {
    speakDescription(
      language == "Hindi (India)"
          ? "ठीक है, मुझे आस-पास का नज़ारा देखने दो।"
          : "Ok, let me see the surrounding.",
    );
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
    String text =
        "Describe the image in short with no usage of emojis and output in language:$language";
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

  Future<void> _speakObjects(List<YOLOResult> objs) async {
    for (var obj in objs) {
      await speakDescription("${obj.className} detected");
    }
  }

  Future<void> _detectObject() async {
    speakDescription(
      "Ok, let me see the surrounding and detect objects. Move your hand slowly",
    );
    objectDetection = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Center(child: Text('Describe'))),
      body: Stack(
        children: <Widget>[
          if (objectDetection)
            YOLOView(
              modelPath: 'yolo11n.tflite',
              task: YOLOTask.detect,
              onResult: (results) {
                setState(() {
                  currentResults = results;
                  for (var obj in results) {
                    speakDescription("${obj.className} detected");
                  }
                });
              },
            ),
          if (!objectDetection)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: CameraPreview(controller),
              ),
            ),
          Align(
            alignment: Alignment.topCenter,
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
                children: <Widget>[
                  Text(
                    "Select a language",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  _buildLanguageDropdown(),
                  const SizedBox(height: 10),
                  Container(
                    child: Text(
                      _speechToText.isListening
                          ? "Listening ..."
                          : _speechEnabled
                              ? "Tap microphone"
                              : "Speech not available",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  if (isProcessing)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
      floatingActionButton: SizedBox(
        height: 350,
        child: FittedBox(
          child: FloatingActionButton(
            onPressed:
                _speechToText.isListening ? _stopListening : _startListening,
            tooltip: 'Listen',
            child: Icon(
              _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
              color: Colors.white,
            ),
            backgroundColor: const Color.fromARGB(255, 177, 125, 241),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildLanguageDropdown() {
    if (_speechLocales.isEmpty) {
      return const Text(
        "Loading languages...",
        style: TextStyle(color: Colors.white),
      );
    }
    return DropdownButton<String>(
      value: _currentLocaleId,
      style: TextStyle(color: Colors.white, backgroundColor: Colors.black),
      items: _speechLocales.map((LocaleName locale) {
        return DropdownMenuItem<String>(
          value: locale.localeId,
          child: Text(
            locale.name,
          ),
          // e.g., "Hindi (India)"
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _currentLocaleId = newValue!;
          _updateLanguage(newValue);
        });
      },
    );
  }

  void _updateLanguage(String lId) {
    for (var locale in _speechLocales) {
      if (locale.localeId == lId) {
        language = locale.name;
      }
    }
  }
}
