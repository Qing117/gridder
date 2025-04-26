import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
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
  String? _originalImagePath;

  int _numRows = 4;
  int _numCols = 4;

  final TextEditingController _rowController = TextEditingController();
  final TextEditingController _colController = TextEditingController();

  final GlobalKey _globalKey = GlobalKey();

  Color _gridColor = Colors.yellow;
  double _gridOpacity = 1.0;
  double _gridStrokeWidth = 1.0;

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
      _originalImagePath = pickedFile.path;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9,
          CropAspectRatioPreset.ratio5x4,
          CropAspectRatioPreset.ratio7x5,
          CropAspectRatioPreset.ratio5x3,
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.teal,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        final imageFile = File(croppedFile.path);
        final data = await imageFile.readAsBytes();
        final codec = await ui.instantiateImageCodec(data);
        final frame = await codec.getNextFrame();

        setState(() {
          _selectedImage = imageFile;
          _uiImage = frame.image;
        });
      }
    }
  }

  Future<void> _recropImage() async {
    if (_originalImagePath == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _originalImagePath!,
      aspectRatioPresets: [
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9,
        CropAspectRatioPreset.ratio5x4,
        CropAspectRatioPreset.ratio7x5,
        CropAspectRatioPreset.ratio5x3,
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Again',
          toolbarColor: Colors.teal,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Again',
          aspectRatioLockEnabled: false,
        ),
      ],
    );

    if (croppedFile != null) {
      final imageFile = File(croppedFile.path);
      final data = await imageFile.readAsBytes();
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
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No image to export")),
        );
        return;
      }

      final originalBytes = await _selectedImage!.readAsBytes();
      img.Image? originalImage = img.decodeImage(originalBytes);

      if (originalImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load image")),
        );
        return;
      }

      final width = originalImage.width;
      final height = originalImage.height;

      final rowHeight = height / _numRows;
      final colWidth = width / _numCols;

      final gridColor = img.ColorRgb8(
        _gridColor.red,
        _gridColor.green,
        _gridColor.blue,
      );

      for (int i = 1; i < _numCols; i++) {
        final x = (i * colWidth).toInt();
        img.drawLine(originalImage, x1: x, y1: 0, x2: x, y2: height, color: gridColor);
      }

      for (int i = 1; i < _numRows; i++) {
        final y = (i * rowHeight).toInt();
        img.drawLine(originalImage, x1: 0, y1: y, x2: width, y2: y, color: gridColor);
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/grid_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(img.encodePng(originalImage));

      final saved = await GallerySaver.saveImage(file.path);

      if (saved == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image saved to Photos")),
        );
      } else {
        throw Exception('Image not saved');
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
                  ? RepaintBoundary(
                      key: _globalKey,
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 1.0,
                        maxScale: 5.0,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final imgAspect = _uiImage!.width / _uiImage!.height;
                            final boxAspect = constraints.maxWidth / constraints.maxHeight;

                            double renderWidth, renderHeight;
                            if (boxAspect > imgAspect) {
                              renderHeight = constraints.maxHeight;
                              renderWidth = renderHeight * imgAspect;
                            } else {
                              renderWidth = constraints.maxWidth;
                              renderHeight = renderWidth / imgAspect;
                            }

                            return Center(
                              child: SizedBox(
                                width: renderWidth,
                                height: renderHeight,
                                child: Stack(
                                  children: [
                                    Image.file(
                                      _selectedImage!,
                                      width: renderWidth,
                                      height: renderHeight,
                                      fit: BoxFit.fill,
                                    ),
                                    CustomPaint(
                                      size: Size(renderWidth, renderHeight),
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
                            );
                          },
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
                  onPressed: _recropImage,
                  child: const Text('Crop Again'),
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
    if (strokeWidth == 0.0) return;
    final paint = Paint()
      ..color = color.withOpacity(opacity)
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
