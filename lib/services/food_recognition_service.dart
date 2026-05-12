import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
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

class RecognitionOutput {
  final List<RecognitionResult> results;
  final String modelUsed; // 'mobilenet' | 'yolo_small'
  final double topConfidence;

  const RecognitionOutput({
    required this.results,
    required this.modelUsed,
    required this.topConfidence,
  });
}

class FoodRecognitionService {
  static FoodRecognitionService? _instance;
  factory FoodRecognitionService() => _instance ??= FoodRecognitionService._();
  FoodRecognitionService._();

  Interpreter? _mobileNet;
  Interpreter? _yoloSmall;
  List<String> _labels = [];
  bool _mobileNetLoaded = false;
  bool _yoloLoaded = false;

  bool get isModelLoaded => _mobileNetLoaded;

  // ── ImageNet normalisation constants ───────────────────────────────────────
  static const _mean = [0.485, 0.456, 0.406];
  static const _std  = [0.229, 0.224, 0.225];

  // ── Load MobileNetV3 (called at app start) ─────────────────────────────────
  Future<bool> loadModel() async {
    if (_mobileNetLoaded) return true;
    try {
      _mobileNet = await Interpreter.fromAsset(AppConfig.mobilenetModelPath);
      final labelsData =
          await rootBundle.loadString(AppConfig.mobilenetLabelsPath);
      _labels = labelsData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      _mobileNetLoaded = true;
      return true;
    } catch (_) {
      _mobileNetLoaded = false;
      return false;
    }
  }

  // ── Lazy-load YOLOv11-small (only when needed) ─────────────────────────────
  Future<bool> _loadYolo() async {
    if (_yoloLoaded) return true;
    try {
      _yoloSmall = await Interpreter.fromAsset(AppConfig.yoloModelPath);
      _yoloLoaded = true;
      return true;
    } catch (_) {
      _yoloLoaded = false;
      return false;
    }
  }

  // ── Two-stage pipeline ─────────────────────────────────────────────────────
  Future<RecognitionOutput> recognize(File imageFile) async {
    if (!_mobileNetLoaded) {
      final loaded = await loadModel();
      if (!loaded) throw Exception('MobileNetV3 model not loaded');
    }

    final mobileResults = await _runMobileNet(imageFile);
    final topConf = mobileResults.isNotEmpty ? mobileResults.first.confidence : 0.0;

    if (topConf >= AppConfig.confidenceThreshold) {
      return RecognitionOutput(
        results: mobileResults,
        modelUsed: 'mobilenet',
        topConfidence: topConf,
      );
    }

    // Low confidence — upgrade to YOLOv11-small
    final yoloLoaded = await _loadYolo();
    if (!yoloLoaded) {
      // Fall back to MobileNet results if YOLO fails to load
      return RecognitionOutput(
        results: mobileResults,
        modelUsed: 'mobilenet',
        topConfidence: topConf,
      );
    }
    final yoloResults = await _runYoloSmall(imageFile);
    return RecognitionOutput(
      results: yoloResults.isNotEmpty ? yoloResults : mobileResults,
      modelUsed: 'yolo_small',
      topConfidence: yoloResults.isNotEmpty
          ? yoloResults.first.confidence
          : topConf,
    );
  }

  // ── MobileNetV3 inference (224×224, ImageNet normalisation) ───────────────
  Future<List<RecognitionResult>> _runMobileNet(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final rawImage = img.decodeImage(imageBytes);
    if (rawImage == null) throw Exception('Cannot decode image');

    final resized = img.copyResize(rawImage,
        width: AppConfig.mobilenetInputSize,
        height: AppConfig.mobilenetInputSize);

    // Build [1, 224, 224, 3] input with ImageNet normalisation
    final input = List.generate(
      1,
      (_) => List.generate(
        AppConfig.mobilenetInputSize,
        (y) => List.generate(
          AppConfig.mobilenetInputSize,
          (x) {
            final p = resized.getPixel(x, y);
            return [
              (p.r / 255.0 - _mean[0]) / _std[0],
              (p.g / 255.0 - _mean[1]) / _std[1],
              (p.b / 255.0 - _mean[2]) / _std[2],
            ];
          },
        ),
      ),
    );

    final numClasses = _mobileNet!.getOutputTensor(0).shape.last;
    final output = [List<double>.filled(numClasses, 0.0)];
    _mobileNet!.run(input, output);

    final scores = output[0];
    // Apply softmax
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final exps = scores.map((v) => _exp(v - maxScore)).toList();
    final expSum = exps.reduce((a, b) => a + b);
    final probs = exps.map((e) => e / expSum).toList();

    final indexed = List.generate(probs.length, (i) => MapEntry(i, probs[i]));
    indexed.sort((a, b) => b.value.compareTo(a.value));

    return indexed
        .take(5)
        .where((e) => e.value > 0.01)
        .map((e) {
          final label = e.key < _labels.length ? _labels[e.key] : 'unknown';
          return RecognitionResult(label: label, confidence: e.value);
        })
        .toList();
  }

  // ── YOLOv11-small inference (640×640, 0-1 normalised) ─────────────────────
  Future<List<RecognitionResult>> _runYoloSmall(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final rawImage = img.decodeImage(imageBytes);
    if (rawImage == null) throw Exception('Cannot decode image');

    final size = AppConfig.yoloInputSize;
    final resized = img.copyResize(rawImage, width: size, height: size);

    // Build [1, 640, 640, 3] input normalised to 0-1
    final input = List.generate(
      1,
      (_) => List.generate(
        size,
        (y) => List.generate(
          size,
          (x) {
            final p = resized.getPixel(x, y);
            return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
          },
        ),
      ),
    );

    // YOLOv11-small TFLite output: [1, 8400, 36]  (36 = 4 bbox + 32 classes)
    final outputShape = _yoloSmall!.getOutputTensor(0).shape; // e.g. [1, 8400, 36]
    final numAnchors  = outputShape[1];
    final numCols     = outputShape[2]; // 4 + num_classes
    final nc          = numCols - 4;

    final output = [
      List.generate(numAnchors, (_) => List<double>.filled(numCols, 0.0))
    ];
    _yoloSmall!.run(input, output);

    // Aggregate max class score across all anchors
    final classScores = List<double>.filled(nc, 0.0);
    for (int a = 0; a < numAnchors; a++) {
      for (int c = 0; c < nc; c++) {
        final score = output[0][a][4 + c];
        if (score > classScores[c]) classScores[c] = score;
      }
    }

    final indexed = List.generate(nc, (i) => MapEntry(i, classScores[i]));
    indexed.sort((a, b) => b.value.compareTo(a.value));

    return indexed
        .take(5)
        .where((e) => e.value > 0.10)
        .map((e) {
          final label = e.key < _labels.length ? _labels[e.key] : 'unknown';
          return RecognitionResult(label: label, confidence: e.value);
        })
        .toList();
  }

  double _exp(double x) => x > 20 ? 485165195 : (x < -20 ? 0 : _expTable(x));
  double _expTable(double x) {
    double result = 1.0, term = 1.0;
    for (int i = 1; i <= 20; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }

  void dispose() {
    _mobileNet?.close();
    _yoloSmall?.close();
    _mobileNet = null;
    _yoloSmall = null;
    _mobileNetLoaded = false;
    _yoloLoaded = false;
    _instance = null;
  }
}
