import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:project_x/chat_page.dart';
import 'package:project_x/describe.dart';
import 'package:project_x/main.dart';
import 'package:project_x/model.dart';
import 'package:project_x/model_download.dart';
import 'package:project_x/speech_page.dart';
import 'package:project_x/test1.dart';

class Home extends StatefulWidget {
  final Model model;
  final List<CameraDescription> cameras;
  const Home({super.key, required this.model, required this.cameras});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late bool isDownloaded = false;
  late ModelDownloadService _downloadService;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _downloadService = ModelDownloadService(
      modelUrl: widget.model.url,
      modelFilename: widget.model.filename,
    );
    _initialize();
  }

  Future<void> _initialize() async {
    isDownloaded = await _downloadService.checkModelExistence();
    setState(() {});
  }

  Future<void> _downloadModel() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _downloadService.downloadModel(
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );
      setState(() {
        isDownloaded = true;
      });
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Failed to download the model.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _progress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isDownloaded) {
      return Scaffold(
        appBar: AppBar(title: Center(child: const Text("Gemma Chat"))),
        body: Center(
          child: Column(
            children: [
              const SizedBox(
                height: 150,
              ),
              Text(
                'Download Progress: ${(_progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 25),
              ),
              const SizedBox(height: 8),
              SizedBox(
                  width: 250,
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 10,
                  )),
              SizedBox(
                height: 50,
              ),
              Container(
                padding: EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: _downloadModel,
                  child: const Text(
                    "Download",
                    style: TextStyle(fontSize: 25),
                  ),
                ),
              ),
              const Text(
                'Model not downloaded!\nClick Download button to start downloading model\nMake sure your phone is connected to internet',
                style: TextStyle(color: Colors.redAccent),
              ),
            ],
          ),
        ),
      );
    } else {
      return Test1(
        cameras: cameras,
        model: Model.gemma3nCpu_2B,
      );
    }
  }
}
