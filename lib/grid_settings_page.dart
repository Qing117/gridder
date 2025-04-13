import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class GridSettingsPage extends StatelessWidget {
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
                controller: colController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter number of columns',
                ),
              ),
              const SizedBox(height: 12),

              const Text('Number of Rows'),
              TextField(
                controller: rowController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter number of rows',
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: () {
                  onApply();
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
              const SizedBox(height: 24),

              const Text('Grid Line Boldness'),
              Slider(
                value: strokeWidth,
                min: 0.5,
                max: 5.0,
                divisions: 9,
                label: strokeWidth.toStringAsFixed(1),
                onChanged: onStrokeChanged,
              ),
              const SizedBox(height: 12),

              const Text('Grid Line Opacity'),
              Slider(
                value: opacity,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: opacity.toStringAsFixed(1),
                onChanged: onOpacityChanged,
              ),
              const SizedBox(height: 12),

              const Text('Grid Line Color'),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Pick Grid Color"),
                        content: SingleChildScrollView(
                          child: BlockPicker(
                            pickerColor: gridColor,
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
                            onColorChanged: onColorChanged,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text("Choose Color"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
