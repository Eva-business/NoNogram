import 'package:flutter/material.dart';
import '../models/cell_state.dart';

class NonogramBoard extends StatefulWidget {
  final int size;
  final List<List<int>> rowHints;
  final List<List<int>> colHints;
  final List<List<CellState>> playerGrid;
  final void Function(int row, int col) onCellTap;
  final bool Function(int row) isRowSolved;
  final bool Function(int col) isColSolved;

  const NonogramBoard({
    super.key,
    required this.size,
    required this.rowHints,
    required this.colHints,
    required this.playerGrid,
    required this.onCellTap,
    required this.isRowSolved,
    required this.isColSolved,
  });

  @override
  State<NonogramBoard> createState() => _NonogramBoardState();
}

class _NonogramBoardState extends State<NonogramBoard> {
  final GlobalKey _gridKey = GlobalKey();
  final Set<String> _dragVisited = {};

  late double cellSize;
  late double rowHintWidth;
  late double colHintHeight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupSizes();
  }

  @override
  void didUpdateWidget(covariant NonogramBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setupSizes();
  }

  void _setupSizes() {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    const rowHintFactor = 2.0;
    const colHintFactor = 2.0;

    // 給提示區和整體布局多一點空間
    const horizontalPadding = 28.0;
    const verticalPadding = 210.0;

    final availableWidth = screenWidth - horizontalPadding;
    final availableHeight = screenHeight - verticalPadding;

    final widthBasedCell = availableWidth / (widget.size + rowHintFactor);
    final heightBasedCell = availableHeight / (widget.size + colHintFactor);

    cellSize = widthBasedCell < heightBasedCell
        ? widthBasedCell
        : heightBasedCell;

    // 刻意讓棋盤再小一點，換取更大的提示數字空間
    cellSize = cellSize * 0.90;

    if (widget.size == 15) {
      cellSize = cellSize.clamp(16.0, 24.0);
    } else if (widget.size == 10) {
      cellSize = cellSize.clamp(24.0, 34.0);
    } else {
      cellSize = cellSize.clamp(42.0, 56.0);
    }

    rowHintWidth = (cellSize * 2.15).clamp(54.0, 96.0);
    colHintHeight = (cellSize * 2.15).clamp(54.0, 96.0);
  }

  void _handlePointer(Offset globalPosition) {
    final context = _gridKey.currentContext;
    if (context == null) return;

    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(globalPosition);

    final col = (local.dx ~/ cellSize);
    final row = (local.dy ~/ cellSize);

    if (row < 0 || row >= widget.size || col < 0 || col >= widget.size) {
      return;
    }

    final key = '$row-$col';
    if (_dragVisited.contains(key)) return;

    _dragVisited.add(key);
    widget.onCellTap(row, col);
  }

  void _startDrag(Offset globalPosition) {
    _dragVisited.clear();
    _handlePointer(globalPosition);
  }

  void _updateDrag(Offset globalPosition) {
    _handlePointer(globalPosition);
  }

  void _endDrag() {
    _dragVisited.clear();
  }

  double _colHintFontSize() {
    if (widget.size <= 5) return 20;
    if (widget.size <= 10) return 16;
    return 13;
  }

  double _rowHintFontSize() {
    if (widget.size <= 5) return 20;
    if (widget.size <= 10) return 17;
    return 14;
  }

  Widget _buildCell(CellState state, int row, int col) {
    return Container(
      width: cellSize,
      height: cellSize,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade400, width: 0.8),
          left: BorderSide(color: Colors.grey.shade400, width: 0.8),
          right: BorderSide(
            color: Colors.grey.shade400,
            width: (col + 1) % 5 == 0 && col != widget.size - 1 ? 2 : 0.8,
          ),
          bottom: BorderSide(
            color: Colors.grey.shade400,
            width: (row + 1) % 5 == 0 && row != widget.size - 1 ? 2 : 0.8,
          ),
        ),
      ),
      child: Center(
        child: switch (state) {
          CellState.empty => const SizedBox.shrink(),
          CellState.filled => Container(
            width: cellSize * 0.78,
            height: cellSize * 0.78,
            decoration: BoxDecoration(
              color: const Color(0xFF354C6F),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          CellState.crossed => Icon(
            Icons.close,
            size: cellSize * 0.72,
            color: const Color(0xFF6B758C),
          ),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final board = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(width: rowHintWidth),
            ...List.generate(widget.size, (col) {
              final solved = widget.isColSolved(col);

              return Container(
                width: cellSize,
                height: colHintHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4FA),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300, width: 1),
                    left: BorderSide(color: Colors.grey.shade300, width: 1),
                    right: BorderSide(
                      color: Colors.grey.shade300,
                      width: (col + 1) % 5 == 0 && col != widget.size - 1
                          ? 2
                          : 1,
                    ),
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.colHints[col].join('\n'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _colHintFontSize(),
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                        color: solved
                            ? const Color(0xFF2E355C).withOpacity(0.28)
                            : const Color(0xFF2E355C),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: List.generate(widget.size, (row) {
                final solved = widget.isRowSolved(row);

                return Container(
                  width: rowHintWidth,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4FA),
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300, width: 1),
                      left: BorderSide(color: Colors.grey.shade300, width: 1),
                      right: BorderSide(color: Colors.grey.shade300, width: 1),
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                        width: (row + 1) % 5 == 0 && row != widget.size - 1
                            ? 2
                            : 1,
                      ),
                    ),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.rowHints[row].join(' '),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: _rowHintFontSize(),
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          color: solved
                              ? const Color(0xFF2E355C).withOpacity(0.28)
                              : const Color(0xFF2E355C),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            GestureDetector(
              onPanStart: (details) => _startDrag(details.globalPosition),
              onPanUpdate: (details) => _updateDrag(details.globalPosition),
              onPanEnd: (_) => _endDrag(),
              child: Container(
                key: _gridKey,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Column(
                  children: List.generate(widget.size, (row) {
                    return Row(
                      children: List.generate(widget.size, (col) {
                        return _buildCell(
                          widget.playerGrid[row][col],
                          row,
                          col,
                        );
                      }),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return Center(
      child: FittedBox(fit: BoxFit.contain, child: board),
    );
  }
}
