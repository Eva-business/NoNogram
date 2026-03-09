import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

import '../models/difficulty.dart';

class FlippableRecordCard extends StatefulWidget {
  final String title;
  final String imagePath;
  final Difficulty difficulty;
  final bool isCustom;

  const FlippableRecordCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.difficulty,
    required this.isCustom,
  });

  @override
  State<FlippableRecordCard> createState() => _FlippableRecordCardState();
}

class _FlippableRecordCardState extends State<FlippableRecordCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  Uint8List? previewBytes;
  bool isLoading = false;

  bool get _isFront => _animation.value < 0.5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _loadPixelPreview();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _gridSize {
    switch (widget.difficulty) {
      case Difficulty.easy:
        return 5;
      case Difficulty.medium:
        return 10;
      case Difficulty.hard:
        return 15;
    }
  }

  Future<void> _loadPixelPreview() async {
    setState(() {
      isLoading = true;
    });

    try {
      Uint8List bytes;

      if (widget.isCustom) {
        bytes = await File(widget.imagePath).readAsBytes();
      } else {
        final data = await rootBundle.load(widget.imagePath);
        bytes = data.buffer.asUint8List();
      }

      final decoded = img.decodeImage(bytes);
      if (decoded == null) return;

      final flattened = _flattenToWhiteBackground(decoded);
      final resized = img.copyResize(
        flattened,
        width: _gridSize,
        height: _gridSize,
        interpolation: img.Interpolation.average,
      );
      final grayscale = img.grayscale(resized);

      final threshold = _computeAdaptiveThreshold(grayscale);

      final binary = List.generate(_gridSize, (y) {
        return List.generate(_gridSize, (x) {
          final pixel = grayscale.getPixel(x, y);
          final gray = pixel.r.toInt();
          return gray < threshold ? 1 : 0;
        });
      });

      final preview = _buildPixelPreviewImage(binary, pixelSize: 16);

      setState(() {
        previewBytes = Uint8List.fromList(img.encodePng(preview));
      });
    } catch (_) {
      // ignore preview failures
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  img.Image _flattenToWhiteBackground(img.Image source) {
    final bg = img.Image(width: source.width, height: source.height);
    img.fill(bg, color: img.ColorRgb8(255, 255, 255));
    return img.compositeImage(bg, source, blend: img.BlendMode.alpha);
  }

  int _computeAdaptiveThreshold(img.Image grayscale) {
    int sum = 0;
    int count = 0;

    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixel(x, y);
        sum += pixel.r.toInt();
        count++;
      }
    }

    final avg = sum ~/ count;
    return (avg - 15).clamp(60, 200);
  }

  img.Image _buildPixelPreviewImage(
    List<List<int>> grid, {
    int pixelSize = 16,
  }) {
    final rows = grid.length;
    final cols = grid.first.length;
    final width = cols * pixelSize;
    final height = rows * pixelSize;

    final canvas = img.Image(width: width, height: height);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final isBlack = grid[y][x] == 1;
        final color = isBlack
            ? img.ColorRgb8(53, 76, 111)
            : img.ColorRgb8(255, 255, 255);

        for (int py = 0; py < pixelSize; py++) {
          for (int px = 0; px < pixelSize; px++) {
            canvas.setPixel(x * pixelSize + px, y * pixelSize + py, color);
          }
        }

        // 畫格線
        final lineColor = img.ColorRgb8(210, 215, 225);
        for (int i = 0; i < pixelSize; i++) {
          canvas.setPixel(x * pixelSize + i, y * pixelSize, lineColor);
          canvas.setPixel(x * pixelSize, y * pixelSize + i, lineColor);
        }
      }
    }

    return canvas;
  }

  void _toggleFlip() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  Widget _buildFrontImage() {
    if (widget.isCustom) {
      return Image.file(
        File(widget.imagePath),
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 80,
            height: 80,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image),
          );
        },
      );
    }

    return Image.asset(
      widget.imagePath,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
    );
  }

  Widget _buildBackImage() {
    if (isLoading) {
      return Container(
        width: 80,
        height: 80,
        color: const Color(0xFFF1F4FA),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (previewBytes == null) {
      return Container(
        width: 80,
        height: 80,
        color: const Color(0xFFF1F4FA),
        alignment: Alignment.center,
        child: const Icon(Icons.grid_view),
      );
    }

    return Image.memory(
      previewBytes!,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final angle = _animation.value * math.pi;
              final showFront = angle < math.pi / 2;

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.white,
                    child: showFront
                        ? _buildFrontImage()
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _buildBackImage(),
                          ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 80,
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
