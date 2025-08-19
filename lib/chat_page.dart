import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/core/message.dart';
import 'package:flutter_gemma/core/model_response.dart';
import 'package:flutter_gemma/flutter_gemma_interface.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project_x/model.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.model});
  final Model model;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _gemma = FlutterGemmaPlugin.instance;
  // InferenceChat? chat;
  InferenceModelSession? chat;
  final _messages = <Message>[];
  bool _isModelInitialized = false;
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String response = "Response appears here";

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
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

    setState(() {
      _isModelInitialized = true;
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty && _selectedImageBytes == null) return;

    final message = _selectedImageBytes != null
        ? Message.withImage(
            text: text.trim(),
            imageBytes: _selectedImageBytes!,
            isUser: true,
          )
        : Message.text(
            text: text.trim(),
            isUser: true,
          );
    if (message != null) {
      processMessage(message);
    }

    _textController.clear();
    _clearImage();
  }

  void _clearImage() {
    setState(() {
      _selectedImageBytes = null;
    });
  }

  Future<void> _pickImage() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Image selection error: $e')),
      );
    }
  }

  Future<void> processMessage(Message message) async {
    await chat?.addQueryChunk(message);
    String res = await chat!.getResponse();
    setState(() {
      response = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text("Model is initialized: $_isModelInitialized"),
          SizedBox(
            height: 200,
          ),
          IconButton(
            icon: Icon(
              Icons.image,
              color: _selectedImageBytes != null ? Colors.blue : Colors.black,
            ),
            onPressed: _pickImage,
            tooltip: 'Add image',
          ),
          Center(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: _selectedImageBytes != null
                    ? 'Add description to image...'
                    : 'Send message',
                hintStyle: const TextStyle(color: Colors.black),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
              maxLines: null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.black),
            onPressed: () => _handleSubmitted(_textController.text),
          ),
          Divider(),
          Text(response),
        ],
      ),
    );
  }
}
