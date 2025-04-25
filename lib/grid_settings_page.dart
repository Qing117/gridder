import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class GridSettingsPage extends StatefulWidget {
  final TextEditingController rowController;
  final TextEditingController colController;
  final double strokeWidth;
  final double opacity;
  final Color gridColor;
  final void Function(Color) onColorChanged;
  final void Function(double) onOpacityChanged;
  final void Function(double) onStrokeChanged;
  final void Function() onApply;

  const GridSettingsPage({
    super.key,
    required this.rowController,
    required this.colController,
    required this.strokeWidth,
    required this.opacity,
    required this.gridColor,
    required this.onColorChanged,
    required this.onOpacityChanged,
    required this.onStrokeChanged,
    required this.onApply,
  });

  @override
  State<GridSettingsPage> createState() => _GridSettingsPageState();
}

class _GridSettingsPageState extends State<GridSettingsPage> {
  late double _localStrokeWidth;
  late double _localOpacity;
  late Color _localColor;

  @override
  void initState() {
    super.initState();
    _localStrokeWidth = widget.strokeWidth;
    _localOpacity = widget.opacity;
    _localColor = widget.gridColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grid Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Number of Columns'),
              TextField(
                controller: widget.colController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter number of columns',
                ),
              ),
              const SizedBox(height: 12),
              const Text('Number of Rows'),
              TextField(
                controller: widget.rowController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter number of rows',
                ),
              ),
              const SizedBox(height: 24),
              const Text('Grid Line Boldness'),
              Slider(
                value: _localStrokeWidth,
                min: 1.0,
                max: 10.0,
                divisions: 20,
                label: _localStrokeWidth.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _localStrokeWidth = value;
                  });
                  widget.onStrokeChanged(value);
                },
              ),
              const SizedBox(height: 12),
              const Text('Grid Line Opacity'),
              Slider(
                value: _localOpacity,
                min: 0.1,
                max: 1.0,
                divisions: 18,
                label: _localOpacity.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _localOpacity = value;
                  });
                  widget.onOpacityChanged(value);
                },
              ),
              const SizedBox(height: 24),
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
                                  pickerColor: _localColor,
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
                                      _localColor = color;
                                    });
                                    widget.onColorChanged(color);
                                  },
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
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply();
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
