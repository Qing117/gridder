import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:typed_data';


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
      home: GridOverlayScreen(),
    );
  }
}

class GridOverlayScreen extends StatefulWidget {
  const GridOverlayScreen({super.key});

  @override
  GridOverlayScreenState createState() => GridOverlayScreenState();
}

class GridOverlayScreenState extends State<GridOverlayScreen> {
  File? _selectedImage;

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
        setState(() {
          _selectedImage = File(pickedFile.path);
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
  
          // Save to gallery
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
              child:RepaintBoundary(
                key: _globalKey,
                child: Stack(
                  fit: StackFit.expand, 
                  children: [
                    if (_selectedImage != null)
                      Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      )
                    else
                      Image.asset(
                        'assets/sample.jpeg',
                        fit: BoxFit.cover,
                      ),
                    CustomPaint(
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Number of Columns'),
                  TextField(
                    controller: _colController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter number of columns',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _exportImage(context, _globalKey),
                      child: const Text('Export Image'),
                    ),
                  ),
                  const Text('Number of Rows'),
                  TextField(
                    controller: _rowController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter number of rows',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
                      onPressed: _applyGridSettings,
                      child: const Text('Done'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text('Pick an Image from Gallery'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Grid Line Boldness'),
                  Slider(
                    value: _gridStrokeWidth,
                    min: 0.5,
                    max: 5.0,
                    divisions: 9,
                    label: _gridStrokeWidth.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _gridStrokeWidth = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Grid Line Opacity'),
                  Slider(
                    value: _gridOpacity,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    label: _gridOpacity.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _gridOpacity = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Grid Line Color'),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Pick Grid Color"),
                              content: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    BlockPicker(
                                      pickerColor: _gridColor,
                                      availableColors: const [
                                        Colors.yellow,
                                        Colors.orange,
                                        Colors.red,
                                        Colors.pink,
                                        Colors.purple,
                                        Colors.blue,
                                        Colors.cyan,
                                        Colors.green,
                                        Colors.brown,
                                        Colors.grey,
                                        Colors.black,
                                        Colors.white,
                                        ],
                                      onColorChanged: (color) {
                                        setState(() {
                                          _gridColor = color;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('Or pick a custom color'),
                                    SlidePicker(
                                      pickerColor: _gridColor,
                                      onColorChanged: (color) {
                                        setState(() {
                                          _gridColor = color;
                                        });
                                      },
                                      enableAlpha: false,
                                      labelTypes: const [],
                                      showIndicator: true,
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text("Choose Color"),
                    ),
                  ),
                ],
              ),
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