import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/food_recognition_service.dart';
import '../../providers/menu_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/menu_item.dart';
const _orange = Color(0xFFea580c);

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
  File? _capturedImage;
  RecognitionOutput? _output;
  List<MenuItem> _matchedItems = [];
  String? _error;
  String _statusMsg = '';

  final _recognizer = FoodRecognitionService();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _recognizer.loadModel(); // preload MobileNet
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
      final back = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      _cameraCtrl = CameraController(back, ResolutionPreset.medium,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
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
    setState(() { _isProcessing = true; _error = null; _statusMsg = 'Running MobileNetV3…'; });
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
    final xFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xFile == null) return;
    setState(() { _isProcessing = true; _error = null; _statusMsg = 'Running MobileNetV3…'; });
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
    final menu = context.read<MenuProvider>();
    try {
      final output = await _recognizer.recognize(imageFile);
      if (output.modelUsed == 'yolo_small' && mounted) {
        setState(() => _statusMsg = 'Upgraded to YOLOv11-small…');
      }
      final keywords = output.results.map((r) => r.label.replaceAll('_', ' ')).toList();
      final matched = menu.searchByKeywords(keywords);
      if (mounted) {
        setState(() {
          _output = output;
          _matchedItems = matched.take(10).toList();
          _error = null;
        });
        if (output.results.isNotEmpty) _showResultsSheet();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _showResultsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResultsSheet(
        output: _output!,
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
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_cameraReady && _cameraCtrl != null)
            Positioned.fill(child: CameraPreview(_cameraCtrl!))
          else
            const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.camera_alt, size: 64, color: Colors.white54),
                SizedBox(height: 12),
                Text('Camera unavailable', style: TextStyle(color: Colors.white54)),
              ]),
            ),

          // Viewfinder corners
          if (_cameraReady)
            Positioned.fill(
              child: CustomPaint(painter: _ViewfinderPainter()),
            ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Point at food — tap the shutter or pick from gallery',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Captured image overlay
          if (_capturedImage != null)
            Positioned.fill(child: Image.file(_capturedImage!, fit: BoxFit.cover)),

          // Processing overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const CircularProgressIndicator(color: _orange),
                    const SizedBox(height: 16),
                    Text(_statusMsg.isNotEmpty ? _statusMsg : 'Recognizing food…',
                        style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ]),
                ),
              ),
            ),

          // Error banner
          if (_error != null)
            Positioned(
              bottom: 120, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade900, borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      heroTag: 'gallery',
                      onPressed: _isProcessing ? null : _pickFromGallery,
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.photo_library, color: Colors.black),
                    ),
                    // Shutter
                    GestureDetector(
                      onTap: _isProcessing ? null : _captureAndRecognize,
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: _isProcessing ? Colors.grey : _orange,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                      ),
                    ),
                    FloatingActionButton(
                      heroTag: 'results',
                      onPressed: _output == null ? null : _showResultsSheet,
                      backgroundColor: _output == null ? Colors.grey : const Color(0xFF16a34a),
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

// Orange corner viewfinder
class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _orange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const margin = 60.0, len = 28.0;
    final corners = [
      [Offset(margin, margin), Offset(margin + len, margin), Offset(margin, margin + len)],
      [Offset(size.width - margin, margin), Offset(size.width - margin - len, margin), Offset(size.width - margin, margin + len)],
      [Offset(margin, size.height - margin - 80), Offset(margin + len, size.height - margin - 80), Offset(margin, size.height - margin - 80 - len)],
      [Offset(size.width - margin, size.height - margin - 80), Offset(size.width - margin - len, size.height - margin - 80), Offset(size.width - margin, size.height - margin - 80 - len)],
    ];
    for (final c in corners) {
      final path = Path()..moveTo(c[1].dx, c[1].dy)..lineTo(c[0].dx, c[0].dy)..lineTo(c[2].dx, c[2].dy);
      canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── Results bottom sheet ──────────────────────────────────────────────────────

class _ResultsSheet extends StatefulWidget {
  final RecognitionOutput output;
  final List<MenuItem> matchedItems;
  final File? capturedImage;

  const _ResultsSheet({
    required this.output,
    required this.matchedItems,
    this.capturedImage,
  });

  @override
  State<_ResultsSheet> createState() => _ResultsSheetState();
}

class _ResultsSheetState extends State<_ResultsSheet> {
  bool _reportOpen = false;
  bool? _reportCorrect;
  String _reportActualLabel = '';
  bool _reportIsOther = false;
  String _reportNotes = '';
  bool _reportSubmitting = false;
  bool _reportDone = false;

  Map<String, dynamic>? _nutritionData;

  @override
  void initState() {
    super.initState();
    if (widget.output.results.isNotEmpty) {
      _fetchNutrition(widget.output.results.first.label);
    }
  }

  Future<void> _fetchNutrition(String foodClass) async {
    try {
      final row = await Supabase.instance.client
          .from('food_nutrition_reference')
          .select()
          .eq('food_class', foodClass)
          .maybeSingle();
      if (row != null && mounted) setState(() => _nutritionData = row);
    } catch (_) {}
  }

  static const _allClasses = [
    'amok', 'bai_sach_chrouk', 'banana_pancakes', 'buddha_bowl', 'curry',
    'dumplings', 'french_fries', 'fried_egg', 'fried_rice', 'grilled_corn',
    'grilled_pork_ribs', 'grilled_skewer', 'hamburger', 'khor_ko', 'kuy_teav',
    'laksa', 'lok_lak', 'nom_banh_chok', 'num_pang', 'pad_thai',
    'papaya_salad', 'pho', 'pizza', 'pleah_sach_ko', 'ramen',
    'rice porridge', 'samlor_korko', 'samlor_machu', 'spring_rolls', 'sushi',
    'tofu_bowl', 'tom_yum_soup',
  ];

  Future<void> _submitReport() async {
    if (_reportCorrect == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Correct or Wrong.')));
      return;
    }
    if (_reportCorrect == false && _reportActualLabel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or type the actual food.')));
      return;
    }
    setState(() => _reportSubmitting = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('scan_reports').insert({
        'student_id': user?.id,
        'detected_label': widget.output.results.isNotEmpty
            ? widget.output.results.first.label : null,
        'detected_confidence': widget.output.topConfidence,
        'model_used': widget.output.modelUsed,
        'all_predictions': widget.output.results
            .map((r) => {'label': r.label, 'confidence': r.confidence})
            .toList(),
        'is_correct': _reportCorrect,
        'actual_label': _reportCorrect == true ? null : _reportActualLabel,
        'notes': _reportNotes.isEmpty ? null : _reportNotes,
      });
      setState(() { _reportSubmitting = false; _reportDone = true; });
    } catch (e) {
      setState(() => _reportSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final results = widget.output.results;
    final modelLabel = widget.output.modelUsed == 'mobilenet'
        ? 'MobileNetV3' : 'YOLOv11-small';
    final confPct = (widget.output.topConfidence * 100).toStringAsFixed(0);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header row
            Row(children: [
              if (widget.capturedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(widget.capturedImage!,
                      width: 56, height: 56, fit: BoxFit.cover),
                ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Recognition Results',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 12),

            // Model badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.output.modelUsed == 'mobilenet'
                    ? const Color(0xFFeff6ff) : const Color(0xFFfdf4ff),
                border: Border.all(
                  color: widget.output.modelUsed == 'mobilenet'
                      ? const Color(0xFFbfdbfe) : const Color(0xFFe9d5ff)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  widget.output.modelUsed == 'mobilenet'
                      ? Icons.offline_bolt : Icons.security,
                  size: 14,
                  color: widget.output.modelUsed == 'mobilenet'
                      ? const Color(0xFF1d4ed8) : const Color(0xFF7c3aed),
                ),
                const SizedBox(width: 6),
                Text(
                  '$modelLabel · $confPct% confidence',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: widget.output.modelUsed == 'mobilenet'
                        ? const Color(0xFF1d4ed8) : const Color(0xFF7c3aed),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),

            // Nutrition card
            if (_nutritionData != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFf0fdf4),
                  border: Border.all(color: const Color(0xFF86efac)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.local_fire_department,
                          size: 14, color: Color(0xFF16a34a)),
                      const SizedBox(width: 4),
                      Text(
                        '${_nutritionData!['display_name'] ?? ''} · per serving (${_nutritionData!['serving_size_g'] ?? '?'}g)',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: Color(0xFF166534)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NutrientChip('${_nutritionData!['calories_per_serving'] ?? '?'}', 'kcal'),
                        _NutrientChip('${_nutritionData!['protein_g'] ?? '?'}g', 'protein'),
                        _NutrientChip('${_nutritionData!['carbs_g'] ?? '?'}g', 'carbs'),
                        _NutrientChip('${_nutritionData!['fat_g'] ?? '?'}g', 'fat'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Detected foods
            if (results.isNotEmpty) ...[
              const Text('Detected Foods',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                      color: _orange, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 4,
                children: results.take(4).map((r) => Chip(
                  label: Text(
                    '${r.displayLabel}  ${(r.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: const Color(0xFFdcfce7),
                  side: const BorderSide(color: Color(0xFF16a34a)),
                  padding: EdgeInsets.zero,
                )).toList(),
              ),
              const SizedBox(height: 12),
            ],

            const Divider(),

            // Matched menu items
            Text(
              widget.matchedItems.isEmpty
                  ? 'No matching menu items'
                  : '${widget.matchedItems.length} item(s) on menu',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                  color: _orange, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            if (widget.matchedItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Try scanning different food or browse the menu manually.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)),
              )
            else
              ...widget.matchedItems.map((item) {
                final inCart = cart.contains(item.id);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(item.image, width: 52, height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 52, height: 52,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.fastfood),
                          )),
                    ),
                    title: Text(item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${item.shop} · \$${item.discountedPrice.toStringAsFixed(2)}'
                      '${item.discountPercent > 0 ? '  -${item.discountPercent.toStringAsFixed(0)}%' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        inCart ? Icons.check_circle : Icons.add_circle,
                        color: const Color(0xFF16a34a),
                      ),
                      onPressed: () {
                        cart.addItem(item);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('${item.name} added to cart'),
                          duration: const Duration(seconds: 1),
                        ));
                      },
                    ),
                  ),
                );
              }),

            const Divider(height: 24),

            // ── Report section ────────────────────────────────────────────────
            if (_reportDone)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFdcfce7),
                  border: Border.all(color: const Color(0xFF16a34a)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(children: [
                  Icon(Icons.check_circle, color: Color(0xFF16a34a), size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text(
                    'Report submitted — thank you for helping improve the model!',
                    style: TextStyle(color: Color(0xFF166534), fontSize: 13),
                  )),
                ]),
              )
            else if (!_reportOpen)
              TextButton.icon(
                onPressed: () => setState(() => _reportOpen = true),
                icon: const Icon(Icons.flag_outlined, size: 16, color: _orange),
                label: const Text('Was the detection wrong? Report to admin',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            else ...[
              const Text('Report Detection',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                      color: _orange, letterSpacing: 0.5)),
              const SizedBox(height: 10),

              // Correct / Wrong
              const Text('Was the detection correct?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: _ReportToggle(
                  label: 'Correct', icon: Icons.thumb_up,
                  selected: _reportCorrect == true,
                  selectedColor: const Color(0xFF16a34a),
                  selectedBg: const Color(0xFFdcfce7),
                  onTap: () => setState(() => _reportCorrect = true),
                )),
                const SizedBox(width: 8),
                Expanded(child: _ReportToggle(
                  label: 'Wrong', icon: Icons.thumb_down,
                  selected: _reportCorrect == false,
                  selectedColor: Colors.red,
                  selectedBg: const Color(0xFFfee2e2),
                  onTap: () => setState(() => _reportCorrect = false),
                )),
              ]),
              const SizedBox(height: 12),

              // Actual label (when wrong)
              if (_reportCorrect == false) ...[
                const Text('What food is it actually?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _reportIsOther ? '__other__'
                      : (_reportActualLabel.isEmpty ? null : _reportActualLabel),
                  hint: const Text('— select food —'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFfed7aa))),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    ..._allClasses.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.replaceAll('_', ' '),
                              style: const TextStyle(fontSize: 13)),
                        )),
                    const DropdownMenuItem(
                      value: '__other__',
                      child: Text('Other (type food name…)',
                          style: TextStyle(fontSize: 13,
                              fontStyle: FontStyle.italic)),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    if (v == '__other__') {
                      _reportIsOther = true;
                      _reportActualLabel = '';
                    } else {
                      _reportIsOther = false;
                      _reportActualLabel = v ?? '';
                    }
                  }),
                ),
                if (_reportIsOther) ...[
                  const SizedBox(height: 8),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Type food name…',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: _orange)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (v) => _reportActualLabel = v,
                  ),
                ],
                const SizedBox(height: 12),
              ],

              // Notes
              const Text('Notes (optional)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextField(
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g. poor lighting, unusual angle…',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFfed7aa))),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (v) => _reportNotes = v,
              ),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _reportOpen = false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _reportSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(backgroundColor: _orange),
                    icon: _reportSubmitting
                        ? const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send, size: 16, color: Colors.white),
                    label: const Text('Submit Report',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ]),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _NutrientChip extends StatelessWidget {
  final String value;
  final String label;
  const _NutrientChip(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold,
              color: Color(0xFF15803d))),
      Text(label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF166534))),
    ]);
  }
}

class _ReportToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final Color selectedBg;
  final VoidCallback onTap;

  const _ReportToggle({
    required this.label, required this.icon, required this.selected,
    required this.selectedColor, required this.selectedBg, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? selectedBg : Colors.white,
          border: Border.all(
              color: selected ? selectedColor : Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: selected ? selectedColor : Colors.grey),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: selected ? selectedColor : Colors.grey)),
        ]),
      ),
    );
  }
}
