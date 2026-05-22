import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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

  bool get isModelLoaded => _mobileNetLoaded || AppConfig.inferenceApiUrl.isNotEmpty;

  bool get _cloudAvailable => AppConfig.inferenceApiUrl.isNotEmpty;

  // ── ImageNet normalisation constants ───────────────────────────────────────
  static const _mean = [0.485, 0.456, 0.406];
  static const _std  = [0.229, 0.224, 0.225];

  // ── Load labels (shared by both models) ───────────────────────────────────
  Future<void> _ensureLabels() async {
    if (_labels.isNotEmpty) return;
    try {
      final labelsData = await rootBundle.loadString(AppConfig.mobilenetLabelsPath);
      _labels = labelsData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
    } catch (e) {
      dev.log('Labels load failed: $e', name: 'FoodRecognition');
    }
  }

  // ── Load MobileNetV3 (called at app start) ─────────────────────────────────
  Future<bool> loadModel() async {
    if (_mobileNetLoaded) return true;
    try {
      _mobileNet = await Interpreter.fromAsset(AppConfig.mobilenetModelPath);
      await _ensureLabels();
      _mobileNetLoaded = true;
      return true;
    } catch (e, st) {
      dev.log('MobileNet load failed: $e', name: 'FoodRecognition', error: e, stackTrace: st);
      _mobileNetLoaded = false;
      return false;
    }
  }

  // ── Lazy-load YOLOv11-small (only when needed) ─────────────────────────────
  Future<bool> _loadYolo() async {
    if (_yoloLoaded) return true;
    try {
      _yoloSmall = await Interpreter.fromAsset(AppConfig.yoloModelPath);
      await _ensureLabels();
      _yoloLoaded = true;
      return true;
    } catch (e, st) {
      dev.log('YOLO load failed: $e', name: 'FoodRecognition', error: e, stackTrace: st);
      _yoloLoaded = false;
      return false;
    }
  }

  // ── Main entry point ──────────────────────────────────────────────────────
  // Pipeline: MobileNet local TFLite → if low confidence → cloud /yolo endpoint
  Future<RecognitionOutput> recognize(File imageFile) async {
    if (!_mobileNetLoaded) await loadModel();

    if (_mobileNetLoaded) {
      final mobileResults = await _runMobileNet(imageFile);
      final topConf = mobileResults.isNotEmpty ? mobileResults.first.confidence : 0.0;

      if (topConf >= AppConfig.confidenceThreshold) {
        return RecognitionOutput(results: mobileResults, modelUsed: 'mobilenet', topConfidence: topConf);
      }

      // Low confidence — try cloud YOLO first, then local YOLO as last resort
      if (_cloudAvailable) {
        try {
          return await _recognizeViaCloudYolo(imageFile);
        } catch (e) {
          dev.log('Cloud YOLO failed: $e — trying local YOLO', name: 'FoodRecognition');
        }
      }

      final yoloLoaded = await _loadYolo();
      if (!yoloLoaded) {
        return RecognitionOutput(results: mobileResults, modelUsed: 'mobilenet', topConfidence: topConf);
      }
      final yoloResults = await _runYoloSmall(imageFile);
      return RecognitionOutput(
        results: yoloResults.isNotEmpty ? yoloResults : mobileResults,
        modelUsed: 'yolo_small',
        topConfidence: yoloResults.isNotEmpty ? yoloResults.first.confidence : topConf,
      );
    }

    // MobileNet failed to load — try cloud YOLO, then local YOLO
    if (_cloudAvailable) {
      try {
        return await _recognizeViaCloudYolo(imageFile);
      } catch (e) {
        dev.log('Cloud YOLO failed: $e — trying local YOLO', name: 'FoodRecognition');
      }
    }
    final yoloLoaded = await _loadYolo();
    if (!yoloLoaded) throw Exception('No food recognition model available');
    final yoloResults = await _runYoloSmall(imageFile);
    return RecognitionOutput(
      results: yoloResults,
      modelUsed: 'yolo_small',
      topConfidence: yoloResults.isNotEmpty ? yoloResults.first.confidence : 0.0,
    );
  }

  // ── Cloud YOLO via inference server POST /yolo ─────────────────────────────
  Future<RecognitionOutput> _recognizeViaCloudYolo(File imageFile) async {
    final uri = Uri.parse('${AppConfig.inferenceApiUrl}/yolo');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('Cloud YOLO error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final preds = (data['predictions'] as List<dynamic>? ?? []);
    final results = preds.map((p) {
      final m = p as Map<String, dynamic>;
      return RecognitionResult(
        label: m['label'] as String,
        confidence: (m['confidence'] as num).toDouble(),
      );
    }).toList();

    final topConf = results.isNotEmpty ? results.first.confidence : 0.0;
    return RecognitionOutput(results: results, modelUsed: 'yolo_cloud', topConfidence: topConf);
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

    // Aggregate max class score across all anchors — apply sigmoid to convert logits → probabilities
    final classScores = List<double>.filled(nc, 0.0);
    for (int a = 0; a < numAnchors; a++) {
      for (int c = 0; c < nc; c++) {
        final score = _sigmoid(output[0][a][4 + c]);
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

  double _sigmoid(double x) => 1.0 / (1.0 + _exp(-x));

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
