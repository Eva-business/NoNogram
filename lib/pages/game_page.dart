import 'dart:io';
import 'package:first_aigame/models/difficulty.dart';
import 'package:flutter/material.dart';

import '../models/cell_state.dart';
import '../models/input_mode.dart';
import '../models/nonogram_puzzle.dart';
import '../models/record_item.dart';
import '../services/record_service.dart';
import '../widgets/nonogram_board.dart';

class GamePage extends StatefulWidget {
  final NonogramPuzzle puzzle;

  const GamePage({super.key, required this.puzzle});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late List<List<CellState>> playerGrid;

  InputMode currentMode = InputMode.fill;

  int lives = 3;
  int hintsLeft = 3;
  bool hasCompleted = false;

  @override
  void initState() {
    super.initState();
    playerGrid = List.generate(
      widget.puzzle.size,
      (_) => List.generate(widget.puzzle.size, (_) => CellState.empty),
    );
  }

  Future<void> _saveCompletedRecord() async {
    if (widget.puzzle.source.imagePath.startsWith('assets/')) {
      await RecordService.markPuzzleFinished(widget.puzzle.source.id);
    } else {
      await RecordService.addCustomRecord(
        RecordItem(
          id: widget.puzzle.source.id,
          title: widget.puzzle.source.title,
          imagePath: widget.puzzle.source.imagePath,
          difficulty: widget.puzzle.difficulty,
          isCustom: true,
        ),
      );
    }
  }

  void _handleCellTap(int row, int col) async {
    if (hasCompleted || lives <= 0) return;

    final isBlackAnswer = widget.puzzle.solutionGrid[row][col] == 1;
    final current = playerGrid[row][col];

    if (current != CellState.empty) return;

    bool isWrong = false;

    if (currentMode == InputMode.fill) {
      if (isBlackAnswer) {
        setState(() {
          playerGrid[row][col] = CellState.filled;
        });
      } else {
        isWrong = true;
        setState(() {
          playerGrid[row][col] = CellState.crossed;
        });
      }
    } else {
      if (!isBlackAnswer) {
        setState(() {
          playerGrid[row][col] = CellState.crossed;
        });
      } else {
        isWrong = true;
        setState(() {
          playerGrid[row][col] = CellState.filled;
        });
      }
    }

    if (isWrong) {
      _loseLife();
    }

    _updateSolvedLines();

    if (_checkWin()) {
      hasCompleted = true;
      await _saveCompletedRecord();
      if (!mounted) return;
      _showWinDialog();
    }
  }

  void _loseLife() {
    setState(() {
      lives--;
    });

    if (lives <= 0) {
      _showGameOverDialog();
    }
  }

  bool _checkWin() {
    for (int r = 0; r < widget.puzzle.size; r++) {
      for (int c = 0; c < widget.puzzle.size; c++) {
        final answerBlack = widget.puzzle.solutionGrid[r][c] == 1;
        final state = playerGrid[r][c];

        if (answerBlack && state != CellState.filled) {
          return false;
        }

        if (!answerBlack && state == CellState.filled) {
          return false;
        }
      }
    }
    return true;
  }

  bool _isRowSolved(int row) {
    for (int col = 0; col < widget.puzzle.size; col++) {
      final answerBlack = widget.puzzle.solutionGrid[row][col] == 1;
      final state = playerGrid[row][col];

      if (answerBlack && state != CellState.filled) {
        return false;
      }

      if (!answerBlack && state == CellState.filled) {
        return false;
      }
    }
    return true;
  }

  bool _isColSolved(int col) {
    for (int row = 0; row < widget.puzzle.size; row++) {
      final answerBlack = widget.puzzle.solutionGrid[row][col] == 1;
      final state = playerGrid[row][col];

      if (answerBlack && state != CellState.filled) {
        return false;
      }

      if (!answerBlack && state == CellState.filled) {
        return false;
      }
    }
    return true;
  }

  void _autoCrossSolvedRow(int row) {
    for (int col = 0; col < widget.puzzle.size; col++) {
      if (playerGrid[row][col] == CellState.empty) {
        playerGrid[row][col] = CellState.crossed;
      }
    }
  }

  void _autoCrossSolvedCol(int col) {
    for (int row = 0; row < widget.puzzle.size; row++) {
      if (playerGrid[row][col] == CellState.empty) {
        playerGrid[row][col] = CellState.crossed;
      }
    }
  }

  void _updateSolvedLines() {
    setState(() {
      for (int row = 0; row < widget.puzzle.size; row++) {
        if (_isRowSolved(row)) {
          _autoCrossSolvedRow(row);
        }
      }

      for (int col = 0; col < widget.puzzle.size; col++) {
        if (_isColSolved(col)) {
          _autoCrossSolvedCol(col);
        }
      }
    });
  }

  void _useHint() async {
    if (hasCompleted || hintsLeft <= 0 || lives <= 0) return;

    for (int r = 0; r < widget.puzzle.size; r++) {
      for (int c = 0; c < widget.puzzle.size; c++) {
        final answerBlack = widget.puzzle.solutionGrid[r][c] == 1;
        final state = playerGrid[r][c];

        if (answerBlack && state != CellState.filled) {
          setState(() {
            playerGrid[r][c] = CellState.filled;
            hintsLeft--;
          });

          _updateSolvedLines();

          if (_checkWin()) {
            hasCompleted = true;
            await _saveCompletedRecord();
            if (!mounted) return;
            _showWinDialog();
          }
          return;
        }

        if (!answerBlack && state != CellState.crossed) {
          setState(() {
            playerGrid[r][c] = CellState.crossed;
            hintsLeft--;
          });

          _updateSolvedLines();

          if (_checkWin()) {
            hasCompleted = true;
            await _saveCompletedRecord();
            if (!mounted) return;
            _showWinDialog();
          }
          return;
        }
      }
    }
  }

  void _resetBoard() {
    setState(() {
      lives = 3;
      hintsLeft = 3;
      hasCompleted = false;
      currentMode = InputMode.fill;
      playerGrid = List.generate(
        widget.puzzle.size,
        (_) => List.generate(widget.puzzle.size, (_) => CellState.empty),
      );
    });
  }

  Widget _buildPuzzleImagePreview() {
    final path = widget.puzzle.source.imagePath;

    if (path.startsWith('assets/')) {
      return Image.asset(path, width: 220, height: 220, fit: BoxFit.cover);
    }

    return Image.file(
      File(path),
      width: 220,
      height: 220,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          width: 220,
          height: 220,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, size: 48),
        );
      },
    );
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF74B47B), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF4F8755),
                offset: Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '過關！',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Color(0xFF2F4F78),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD7E4F2), width: 3),
                ),
                child: ClipRect(child: _buildPuzzleImagePreview()),
              ),
              const SizedBox(height: 14),
              Text(
                widget.puzzle.source.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2F4F78),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '你成功完成這張圖片，已收藏到紀錄館。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5A6D85),
                ),
              ),
              const SizedBox(height: 20),
              _PixelMiniButton(
                text: '回上一頁',
                backgroundColor: const Color(0xFF74B47B),
                borderColor: const Color(0xFF3E6B44),
                shadowColor: const Color(0xFF29472D),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFF0B35A), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF9A6423),
                offset: Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '挑戰失敗',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2F4F78),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '生命已用完，請重新挑戰。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5A6D85),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PixelMiniButton(
                    text: '重新開始',
                    backgroundColor: const Color(0xFF5C88C4),
                    borderColor: const Color(0xFF2F4F78),
                    shadowColor: const Color(0xFF1E3552),
                    onTap: () {
                      Navigator.pop(context);
                      _resetBoard();
                    },
                  ),
                  const SizedBox(width: 14),
                  _PixelMiniButton(
                    text: '返回',
                    backgroundColor: const Color(0xFFF0B35A),
                    borderColor: const Color(0xFF9A6423),
                    shadowColor: const Color(0xFF6C4314),
                    textColor: const Color(0xFF2B1A05),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLives() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD7E4F2), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFC9D9EA),
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.favorite,
              color: index < lives
                  ? const Color(0xFFE94B5B)
                  : Colors.grey.shade300,
              size: 28,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildModeSwitch() {
    final isFill = currentMode == InputMode.fill;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD7E4F2), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFC9D9EA),
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeButton(
            icon: Icons.close,
            selected: !isFill,
            selectedColor: const Color(0xFFF0B35A),
            borderColor: const Color(0xFF9A6423),
            iconColor: const Color(0xFF2B1A05),
            onTap: () {
              setState(() {
                currentMode = InputMode.cross;
              });
            },
          ),
          const SizedBox(width: 10),
          _modeButton(
            icon: Icons.crop_square,
            selected: isFill,
            selectedColor: const Color(0xFF5C88C4),
            borderColor: const Color(0xFF2F4F78),
            iconColor: Colors.white,
            onTap: () {
              setState(() {
                currentMode = InputMode.fill;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required IconData icon,
    required bool selected,
    required Color selectedColor,
    required Color borderColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: selected ? selectedColor : const Color(0xFFF4F7FB),
          border: Border.all(
            color: selected ? borderColor : const Color(0xFFD7E4F2),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: selected ? borderColor : const Color(0xFFC9D9EA),
              offset: const Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 30,
          color: selected ? iconColor : const Color(0xFF7E879A),
        ),
      ),
    );
  }

  Widget _buildHintButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: _useHint,
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFB884F6),
              border: Border.all(color: const Color(0xFF7446B2), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF512D80),
                  offset: Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE94B5B),
              border: Border.all(color: const Color(0xFF9E2E38), width: 2),
            ),
            child: Text(
              '$hintsLeft',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshButton() {
    return GestureDetector(
      onTap: _resetBoard,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          border: Border.all(color: const Color(0xFFD7E4F2), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFC9D9EA),
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Icon(Icons.refresh, size: 20, color: Color(0xFF2F4F78)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = widget.puzzle;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF4FF),
        elevation: 0,
        centerTitle: true,
        foregroundColor: const Color(0xFF2F4F78),
        title: Column(
          children: [
            Text(
              puzzle.source.title,
              style: const TextStyle(
                color: Color(0xFF2F4F78),
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              puzzle.difficulty.label,
              style: const TextStyle(
                color: Color(0xFF5A6D85),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: _buildRefreshButton()),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Container(
              width: 380,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFB7CCE6), width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFB7CCE6),
                    offset: Offset(6, 6),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildLives(),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Center(
                        child: NonogramBoard(
                          size: puzzle.size,
                          rowHints: puzzle.rowHints,
                          colHints: puzzle.colHints,
                          playerGrid: playerGrid,
                          onCellTap: _handleCellTap,
                          isRowSolved: _isRowSolved,
                          isColSolved: _isColSolved,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildModeSwitch(),
                      const SizedBox(width: 24),
                      _buildHintButton(),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PixelMiniButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final Color textColor;

  const _PixelMiniButton({
    required this.text,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.shadowColor,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
