import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:ultralytics_yolo/yolo_view.dart';

class YoloPage extends StatefulWidget {
  const YoloPage({super.key});

  @override
  State<YoloPage> createState() => _YoloPageState();
}

class _YoloPageState extends State<YoloPage> {
  late YOLO yolo;
  // late YOLOViewController controller;
  List<YOLOResult> currentResults = [];

  Future<void> initializeYOLO() async {
    yolo = YOLO(
      modelPath: 'yolo11n.tflite',
      task: YOLOTask.detect,
    );
    await yolo.loadModel();
    debugPrint('YOLO model loaded successfully!');
  }

  @override
  void initState() {
    super.initState();
    // controller = YOLOViewController();
    initializeYOLO();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera view with YOLO processing
          YOLOView(
            modelPath: 'yolo11n.tflite',
            task: YOLOTask.detect,
            onResult: (results) {
              setState(() {
                currentResults = results;
              });
            },
            onPerformanceMetrics: (metrics) {
              debugPrint('FPS: ${metrics.fps.toStringAsFixed(1)}');
              debugPrint(
                  'Processing time: ${metrics.processingTimeMs.toStringAsFixed(1)}ms');
            },
          ),

          // Overlay UI
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Objects: ${currentResults.length}',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
