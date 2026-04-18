import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/food_recognition_service.dart';
import '../../providers/menu_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/menu_item.dart';

enum ScanMode { offline, online }

class FoodScanScreen extends StatefulWidget {
  const FoodScanScreen({super.key});

  @override
  State<FoodScanScreen> createState() => _FoodScanScreenState();
}

class _FoodScanScreenState extends State<FoodScanScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraCtrl;
  List<CameraDescription> _cameras = [];
  bool _cameraReady = false;
  bool _isProcessing = false;
  ScanMode _mode = ScanMode.offline;
  File? _capturedImage;
  List<RecognitionResult> _results = [];
  List<MenuItem> _matchedItems = [];
  String? _error;

  final _recognizer = FoodRecognitionService();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraCtrl!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      _cameraCtrl = CameraController(
        _cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cameraCtrl!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (_) {
      if (mounted) setState(() => _cameraReady = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraCtrl?.dispose();
    super.dispose();
  }

  Future<void> _captureAndRecognize() async {
    if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) return;
    setState(() {
      _isProcessing = true;
      _error = null;
      _results = [];
      _matchedItems = [];
    });
    try {
      final xFile = await _cameraCtrl!.takePicture();
      await _runRecognition(File(xFile.path));
    } catch (e) {
      if (mounted) setState(() => _error = 'Camera error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final xFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile == null) return;
    setState(() {
      _isProcessing = true;
      _error = null;
      _results = [];
      _matchedItems = [];
    });
    try {
      await _runRecognition(File(xFile.path));
    } catch (e) {
      if (mounted) setState(() => _error = 'Gallery error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _runRecognition(File imageFile) async {
    setState(() => _capturedImage = imageFile);
    // Read provider before async gap
    final menu = context.read<MenuProvider>();
    try {
      final results = _mode == ScanMode.offline
          ? await _recognizer.recognizeOffline(imageFile)
          : await _recognizer.recognizeOnline(imageFile);

      // Find matching menu items
      final keywords =
          results.map((r) => r.label.replaceAll('_', ' ')).toList();
      final matched = menu.searchByKeywords(keywords);

      if (mounted) {
        setState(() {
          _results = results;
          _matchedItems = matched.take(10).toList();
          _error = null;
        });
        if (results.isNotEmpty) {
          _showResultsSheet();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  void _showResultsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResultsSheet(
        results: _results,
        matchedItems: _matchedItems,
        capturedImage: _capturedImage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_cameraReady && _cameraCtrl != null)
            Positioned.fill(child: CameraPreview(_cameraCtrl!))
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 64, color: Colors.white54),
                  SizedBox(height: 12),
                  Text('Camera unavailable',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),

          // Top bar
          SafeArea(
            child: Column(
              children: [
                // Mode toggle
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ModeButton(
                        label: 'Offline (MobileNet)',
                        icon: Icons.offline_bolt,
                        selected: _mode == ScanMode.offline,
                        onTap: () =>
                            setState(() => _mode = ScanMode.offline),
                      ),
                      _ModeButton(
                        label: 'Online (YOLOv8)',
                        icon: Icons.cloud,
                        selected: _mode == ScanMode.online,
                        onTap: () =>
                            setState(() => _mode = ScanMode.online),
                      ),
                    ],
                  ),
                ),
                // Info banner
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _mode == ScanMode.offline
                        ? 'Offline mode – runs locally on device (MobileNet)'
                        : 'Online mode – uses YOLOv8 nano for precise detection',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Captured image overlay
          if (_capturedImage != null)
            Positioned.fill(
              child: Image.file(_capturedImage!, fit: BoxFit.cover),
            ),

          // Processing overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text('Recognizing food...',
                          style: TextStyle(
                              color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),

          // Error message
          if (_error != null)
            Positioned(
              bottom: 120,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery button
                    FloatingActionButton(
                      heroTag: 'gallery',
                      onPressed: _isProcessing ? null : _pickFromGallery,
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.photo_library,
                          color: Colors.black),
                    ),
                    // Capture button
                    GestureDetector(
                      onTap: _isProcessing ? null : _captureAndRecognize,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: _isProcessing
                              ? Colors.grey
                              : Colors.white,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.black, size: 32),
                      ),
                    ),
                    // Show results button (if available)
                    FloatingActionButton(
                      heroTag: 'results',
                      onPressed: _results.isEmpty ? null : _showResultsSheet,
                      backgroundColor: _results.isEmpty
                          ? Colors.grey
                          : const Color(0xFF16a34a),
                      child: const Icon(Icons.list_alt, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF16a34a) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ── Results bottom sheet ────────────────────────────────────────────────────

class _ResultsSheet extends StatelessWidget {
  final List<RecognitionResult> results;
  final List<MenuItem> matchedItems;
  final File? capturedImage;

  const _ResultsSheet({
    required this.results,
    required this.matchedItems,
    this.capturedImage,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (capturedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(capturedImage!,
                          width: 64, height: 64, fit: BoxFit.cover),
                    ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recognition Results',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Tap items to add to cart',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Top predictions
            if (results.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detected Foods:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: results
                          .take(3)
                          .map((r) => Chip(
                                label: Text(
                                  '${r.displayLabel} (${(r.confidence * 100).toStringAsFixed(0)}%)',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: const Color(0xFF16a34a)
                                    .withOpacity(0.1),
                                side: const BorderSide(
                                    color: Color(0xFF16a34a)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            const Divider(),
            // Matched menu items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    matchedItems.isEmpty
                        ? 'No matching menu items found'
                        : '${matchedItems.length} matching items on menu:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: matchedItems.isEmpty
                  ? const Center(
                      child: Text(
                        'Try scanning different food or browse the menu manually.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: matchedItems.length,
                      itemBuilder: (ctx, i) {
                        final item = matchedItems[i];
                        final inCart = cart.contains(item.id);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.image,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 52,
                                  height: 52,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.fastfood),
                                ),
                              ),
                            ),
                            title: Text(item.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${item.shop} • \$${item.discountedPrice.toStringAsFixed(2)}'
                              '${item.isSpecial ? ' (30% off)' : ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                inCart
                                    ? Icons.check_circle
                                    : Icons.add_circle,
                                color: const Color(0xFF16a34a),
                              ),
                              onPressed: () {
                                cart.addItem(item);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('${item.name} added to cart'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
