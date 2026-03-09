import 'package:flutter/material.dart';
import '../models/difficulty.dart';
import '../services/puzzle_repository.dart';
import '../services/record_service.dart';
import '../models/record_item.dart';
import '../widgets/flippable_record_card.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  Set<String> finishedIds = {};
  List<RecordItem> customRecords = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final ids = await RecordService.getFinishedPuzzleIds();
    final custom = await RecordService.getCustomRecords();

    setState(() {
      finishedIds = ids;
      customRecords = custom;
    });
  }

  Future<void> _resetGame() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('清空紀錄'),
        content: const Text('確定要清空所有過關紀錄嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (shouldReset != true) return;

    await RecordService.clearAll();
    await _loadRecords();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已清空所有紀錄')));
  }

  Color _getSectionColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return const Color(0xFFEAF7EC);
      case Difficulty.medium:
        return const Color(0xFFEAF1FB);
      case Difficulty.hard:
        return const Color(0xFFFFF3E3);
    }
  }

  Color _getBorderColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return const Color(0xFF74B47B);
      case Difficulty.medium:
        return const Color(0xFF5C88C4);
      case Difficulty.hard:
        return const Color(0xFFF0B35A);
    }
  }

  Widget _buildSystemSection(Difficulty difficulty) {
    final puzzles = PuzzleRepository.puzzlesByDifficulty(difficulty);
    final finished = puzzles.where((p) => finishedIds.contains(p.id)).toList();

    final allDone = puzzles.isNotEmpty && finished.length == puzzles.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getSectionColor(difficulty),
        border: Border.all(color: _getBorderColor(difficulty), width: 3),
        boxShadow: [
          BoxShadow(
            color: _getBorderColor(difficulty).withOpacity(0.55),
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            difficulty.label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: Color(0xFF2F4F78),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '已完成 ${finished.length} / ${puzzles.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5A6D85),
            ),
          ),
          if (allDone)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '此難度已全部過關！',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 14),
          if (finished.isEmpty)
            const Text(
              '目前還沒有完成的圖片',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A6D85),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: finished.map((puzzle) {
                return FlippableRecordCard(
                  title: puzzle.title,
                  imagePath: puzzle.imagePath,
                  difficulty: puzzle.difficulty,
                  isCustom: false,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF4FF),
        border: Border.all(color: const Color(0xFFC28AE6), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFD9B5F3),
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '玩家自訂收藏',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: Color(0xFF6C3C8C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '已收藏 ${customRecords.length} 張',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7A5C8F),
            ),
          ),
          const SizedBox(height: 14),
          if (customRecords.isEmpty)
            const Text(
              '目前還沒有完成的圖片',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7A5C8F),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: customRecords.map((record) {
                return FlippableRecordCard(
                  title: record.title,
                  imagePath: record.imagePath,
                  difficulty: record.difficulty,
                  isCustom: true,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPixelDeleteButton() {
    return GestureDetector(
      onTap: _resetGame,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6A6A6),
          border: Border.all(color: const Color(0xFFB85B5B), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF8E4545),
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, size: 18, color: Colors.white),
            SizedBox(width: 6),
            Text(
              '清空',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        title: const Text('紀錄館'),
        centerTitle: true,
        backgroundColor: const Color(0xFFEAF4FF),
        foregroundColor: const Color(0xFF2F4F78),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: _buildPixelDeleteButton()),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: 340,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
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
                  const Text(
                    '我的收藏紀錄',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Color(0xFF2F4F78),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '點擊圖片可以翻轉查看像素圖',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A6D85),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ListView(
                      children: [
                        ...Difficulty.values.map(_buildSystemSection),
                        _buildCustomSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
