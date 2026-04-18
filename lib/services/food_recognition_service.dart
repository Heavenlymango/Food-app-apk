import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../config/app_config.dart';

class RecognitionResult {
  final String label;
  final double confidence;

  const RecognitionResult({required this.label, required this.confidence});

  String get displayLabel {
    return label
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class FoodRecognitionService {
  static FoodRecognitionService? _instance;
  factory FoodRecognitionService() => _instance ??= FoodRecognitionService._();
  FoodRecognitionService._();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _modelLoaded = false;

  bool get isModelLoaded => _modelLoaded;

  Future<bool> loadModel() async {
    if (_modelLoaded) return true;
    try {
      _interpreter = await Interpreter.fromAsset(AppConfig.mobilenetModelPath);
      final labelsData =
          await rootBundle.loadString(AppConfig.mobilenetLabelsPath);
      _labels = labelsData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      _modelLoaded = true;
      return true;
    } catch (e) {
      _modelLoaded = false;
      return false;
    }
  }

  // ── OFFLINE: MobileNet inference ──────────────────────────────────────────
  Future<List<RecognitionResult>> recognizeOffline(File imageFile) async {
    if (!_modelLoaded) {
      final loaded = await loadModel();
      if (!loaded) throw Exception('MobileNet model not loaded');
    }

    final imageBytes = await imageFile.readAsBytes();
    final rawImage = img.decodeImage(imageBytes);
    if (rawImage == null) throw Exception('Cannot decode image');

    // Resize to 224×224
    final resized = img.copyResize(rawImage,
        width: AppConfig.modelInputSize, height: AppConfig.modelInputSize);

    // Build input tensor: [1, 224, 224, 3] float32 normalised to [-1, 1]
    final input = List.generate(
      1,
      (_) => List.generate(
        AppConfig.modelInputSize,
        (y) => List.generate(
          AppConfig.modelInputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              (pixel.r / 127.5) - 1.0,
              (pixel.g / 127.5) - 1.0,
              (pixel.b / 127.5) - 1.0,
            ];
          },
        ),
      ),
    );

    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final numClasses = outputShape.last;
    final output = [List<double>.filled(numClasses, 0.0)];

    _interpreter!.run(input, output);

    final scores = output[0];
    final indexed = List.generate(scores.length, (i) => MapEntry(i, scores[i]));
    indexed.sort((a, b) => b.value.compareTo(a.value));

    return indexed.take(5).map((e) {
      final label = e.key < _labels.length ? _labels[e.key] : 'unknown';
      return RecognitionResult(label: label, confidence: e.value);
    }).toList();
  }

  // ── ONLINE: YOLOv8 nano via Roboflow API ──────────────────────────────────
  Future<List<RecognitionResult>> recognizeOnline(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final uri = Uri.parse(
        '${AppConfig.roboflowApiUrl}?api_key=${AppConfig.roboflowApiKey}');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: base64Image,
    );

    if (response.statusCode != 200) {
      throw Exception('Online recognition failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final predictions = data['predictions'] as List<dynamic>? ?? [];

    if (predictions.isEmpty) return [];

    // Aggregate by class label
    final classScores = <String, double>{};
    for (final p in predictions) {
      final pred = p as Map<String, dynamic>;
      final className = pred['class'] as String;
      final confidence = (pred['confidence'] as num).toDouble();
      if (!classScores.containsKey(className) ||
          classScores[className]! < confidence) {
        classScores[className] = confidence;
      }
    }

    final results = classScores.entries
        .map((e) => RecognitionResult(label: e.key, confidence: e.value))
        .toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    return results.take(5).toList();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _modelLoaded = false;
    _instance = null;
  }
}

// ── Uint8List helper for older API ────────────────────────────────────────
extension Uint8ListExt on Uint8List {
  Float32List toFloat32NormalizedRgb(int width, int height) {
    final decoded = img.decodeImage(this)!;
    final resized = img.copyResize(decoded, width: width, height: height);
    final float32 = Float32List(width * height * 3);
    int idx = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = resized.getPixel(x, y);
        float32[idx++] = (pixel.r / 127.5) - 1.0;
        float32[idx++] = (pixel.g / 127.5) - 1.0;
        float32[idx++] = (pixel.b / 127.5) - 1.0;
      }
    }
    return float32;
  }
}
