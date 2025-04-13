import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'grid_settings_page.dart';

void main() {
  runApp(const ImageGridderApp());
}

class ImageGridderApp extends StatelessWidget {
  const ImageGridderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Gridder',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const GridOverlayScreen(),
    );
  }
}

class GridOverlayScreen extends StatefulWidget {
  const GridOverlayScreen({super.key});

  @override
  State<GridOverlayScreen> createState() => _GridOverlayScreenState();
}

class _GridOverlayScreenState extends State<GridOverlayScreen> {
  File? _selectedImage;
  ui.Image? _uiImage;

  int _numRows = 4;
  int _numCols = 4;

  final TextEditingController _rowController = TextEditingController();
  final TextEditingController _colController = TextEditingController();

  final GlobalKey _globalKey = GlobalKey();

  Color _gridColor = Colors.yellow;
  double _gridOpacity = 0.6;
  double _gridStrokeWidth = 1.5;

  @override
  void initState() {
    super.initState();
    _rowController.text = _numRows.toString();
    _colController.text = _numCols.toString();
  }

  @override
  void dispose() {
    _rowController.dispose();
    _colController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final data = await pickedFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();

      setState(() {
        _selectedImage = imageFile;
        _uiImage = frame.image;
      });
    }
  }

  Future<void> _exportImage(BuildContext context, GlobalKey globalKey) async {
    try {
      RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/grid_image.png';
        final file = File(filePath);
        await file.writeAsBytes(pngBytes);

        await GallerySaver.saveImage(file.path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image exported successfully!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to export image: $e")),
      );
    }
  }

  void _applyGridSettings() {
    final int? rows = int.tryParse(_rowController.text);
    final int? cols = int.tryParse(_colController.text);

    if (rows != null && rows > 0 && cols != null && cols > 0) {
      setState(() {
        _numRows = rows;
        _numCols = cols;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid positive integers")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Gridder')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _uiImage != null
                  ? FittedBox(
                      fit: BoxFit.contain,
                      child: RepaintBoundary(
                        key: _globalKey,
                        child: SizedBox(
                          width: _uiImage!.width.toDouble(),
                          height: _uiImage!.height.toDouble(),
                          child: Stack(
                            children: [
                              Image.file(
                                _selectedImage!,
                                width: _uiImage!.width.toDouble(),
                                height: _uiImage!.height.toDouble(),
                                fit: BoxFit.fill,
                              ),
                              CustomPaint(
                                size: Size(
                                  _uiImage!.width.toDouble(),
                                  _uiImage!.height.toDouble(),
                                ),
                                painter: GridPainter(
                                  rows: _numRows,
                                  columns: _numCols,
                                  color: _gridColor,
                                  opacity: _gridOpacity,
                                  strokeWidth: _gridStrokeWidth,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const Text("Please select an image."),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Pick an Image from Gallery'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _exportImage(context, _globalKey),
                  child: const Text('Export Image'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GridSettingsPage(
                          rowController: _rowController,
                          colController: _colController,
                          strokeWidth: _gridStrokeWidth,
                          opacity: _gridOpacity,
                          gridColor: _gridColor,
                          onColorChanged: (color) =>
                              setState(() => _gridColor = color),
                          onOpacityChanged: (val) =>
                              setState(() => _gridOpacity = val),
                          onStrokeChanged: (val) =>
                              setState(() => _gridStrokeWidth = val),
                          onApply: _applyGridSettings,
                        ),
                      ),
                    );
                  },
                  child: const Text('Go to Grid Settings'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final int rows;
  final int columns;
  final Color color;
  final double opacity;
  final double strokeWidth;

  GridPainter({
    required this.rows,
    required this.columns,
    required this.color,
    required this.opacity,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha((opacity * 255).round())
      ..strokeWidth = strokeWidth;

    final rowHeight = size.height / rows;
    final colWidth = size.width / columns;

    for (int i = 1; i < columns; i++) {
      final x = i * colWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (int i = 1; i < rows; i++) {
      final y = i * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.rows != rows ||
        oldDelegate.columns != columns ||
        oldDelegate.color != color ||
        oldDelegate.opacity != opacity ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
