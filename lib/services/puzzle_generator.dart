import 'package:first_aigame/models/difficulty.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

import '../models/nonogram_puzzle.dart';
import '../models/puzzle_data.dart';
import 'dart:io';

class PuzzleGenerator {
  static Future<NonogramPuzzle> generateFromFile({
    required File imageFile,
    required Difficulty difficulty,
  }) async {
    final bytes = await imageFile.readAsBytes();

    final original = img.decodeImage(bytes);
    if (original == null) {
      throw Exception('無法讀取使用者圖片');
    }

    final flattened = _flattenToWhiteBackground(original);
    final size = difficulty.size;

    final resized = img.copyResize(
      flattened,
      width: size,
      height: size,
      interpolation: img.Interpolation.average,
    );

    final grayscale = img.grayscale(resized);
    final threshold = _computeAdaptiveThreshold(grayscale);

    var solutionGrid = List.generate(size, (y) {
      return List.generate(size, (x) {
        final pixel = grayscale.getPixel(x, y);
        final gray = pixel.r.toInt();
        return gray < threshold ? 1 : 0;
      });
    });

    solutionGrid = _normalizeBlackRatio(solutionGrid, grayscale);

    final rowHints = _generateRowHints(solutionGrid);
    final colHints = _generateColHints(solutionGrid);

    return NonogramPuzzle(
      source: PuzzleData(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        title: '我的圖片',
        imagePath: imageFile.path,
        difficulty: difficulty,
      ),
      difficulty: difficulty,
      size: size,
      solutionGrid: solutionGrid,
      rowHints: rowHints,
      colHints: colHints,
    );
  }

  static Future<NonogramPuzzle> generateFromAsset(PuzzleData data) async {
    final byteData = await rootBundle.load(data.imagePath);
    final bytes = byteData.buffer.asUint8List();

    final original = img.decodeImage(bytes);
    if (original == null) {
      throw Exception('無法讀取圖片：${data.imagePath}');
    }

    final size = data.difficulty.size;

    // 1. 先轉成白底，避免透明背景被誤判
    final flattened = _flattenToWhiteBackground(original);

    // 2. 縮小成 N x N
    final resized = img.copyResize(
      flattened,
      width: size,
      height: size,
      interpolation: img.Interpolation.average,
    );

    // 3. 灰階化
    final grayscale = img.grayscale(resized);

    // 4. 根據整張圖平均亮度，動態決定 threshold
    final threshold = _computeAdaptiveThreshold(grayscale);

    // 5. 二值化
    var solutionGrid = List.generate(size, (y) {
      return List.generate(size, (x) {
        final pixel = grayscale.getPixel(x, y);
        final gray = pixel.r.toInt();
        return gray < threshold ? 1 : 0;
      });
    });

    // 6. 如果黑格比例太高，再做一次修正
    solutionGrid = _normalizeBlackRatio(solutionGrid, grayscale);

    final rowHints = _generateRowHints(solutionGrid);
    final colHints = _generateColHints(solutionGrid);

    return NonogramPuzzle(
      source: data,
      difficulty: data.difficulty,
      size: size,
      solutionGrid: solutionGrid,
      rowHints: rowHints,
      colHints: colHints,
    );
  }

  static img.Image _flattenToWhiteBackground(img.Image source) {
    final bg = img.Image(width: source.width, height: source.height);
    img.fill(bg, color: img.ColorRgb8(255, 255, 255));

    return img.compositeImage(bg, source, blend: img.BlendMode.alpha);
  }

  static int _computeAdaptiveThreshold(img.Image grayscale) {
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

    // 稍微比平均亮度低一點，避免整張太容易黑掉
    final threshold = (avg - 15).clamp(60, 200);
    return threshold;
  }

  static List<List<int>> _normalizeBlackRatio(
    List<List<int>> grid,
    img.Image grayscale,
  ) {
    final size = grid.length;
    int blackCount = 0;

    for (final row in grid) {
      for (final cell in row) {
        if (cell == 1) blackCount++;
      }
    }

    final total = size * size;
    final ratio = blackCount / total;

    // 如果超過 65% 都是黑格，代表太黑了，重新用更嚴格 threshold
    if (ratio <= 0.65) return grid;

    final stricterThreshold = 100;

    return List.generate(size, (y) {
      return List.generate(size, (x) {
        final pixel = grayscale.getPixel(x, y);
        final gray = pixel.r.toInt();
        return gray < stricterThreshold ? 1 : 0;
      });
    });
  }

  static List<List<int>> _generateRowHints(List<List<int>> grid) {
    return grid.map(_generateHintsForLine).toList();
  }

  static List<List<int>> _generateColHints(List<List<int>> grid) {
    final size = grid.length;
    return List.generate(size, (col) {
      final line = List.generate(size, (row) => grid[row][col]);
      return _generateHintsForLine(line);
    });
  }

  static List<int> _generateHintsForLine(List<int> line) {
    final hints = <int>[];
    int count = 0;

    for (final cell in line) {
      if (cell == 1) {
        count++;
      } else {
        if (count > 0) {
          hints.add(count);
          count = 0;
        }
      }
    }

    if (count > 0) {
      hints.add(count);
    }

    return hints.isEmpty ? [0] : hints;
  }
}
