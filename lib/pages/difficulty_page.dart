import 'package:flutter/material.dart';
import '../models/difficulty.dart';
import '../services/puzzle_generator.dart';
import '../services/puzzle_repository.dart';
import '../services/record_service.dart';
import 'game_page.dart';

class DifficultyPage extends StatelessWidget {
  const DifficultyPage({super.key});

  Future<void> _startGame(BuildContext context, Difficulty difficulty) async {
    final finishedIds = await RecordService.getFinishedPuzzleIds();

    final picked = PuzzleRepository.pickRandomUnfinished(
      difficulty: difficulty,
      finishedIds: finishedIds,
    );

    if (picked == null) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('已完成'),
          content: Text('你已完成 ${difficulty.label} 的所有關卡'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
      return;
    }

    final puzzle = await PuzzleGenerator.generateFromAsset(picked);

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GamePage(puzzle: puzzle)),
    );
  }

  Color _getCardColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return const Color(0xFF74B47B);
      case Difficulty.medium:
        return const Color(0xFF5C88C4);
      case Difficulty.hard:
        return const Color(0xFFF0B35A);
    }
  }

  Color _getBorderColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return const Color(0xFF3E6B44);
      case Difficulty.medium:
        return const Color(0xFF2F4F78);
      case Difficulty.hard:
        return const Color(0xFF9A6423);
    }
  }

  Color _getShadowColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return const Color(0xFF29472D);
      case Difficulty.medium:
        return const Color(0xFF1E3552);
      case Difficulty.hard:
        return const Color(0xFF6C4314);
    }
  }

  String _getSubtitle(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return '適合新手練習';
      case Difficulty.medium:
        return '挑戰你的觀察力';
      case Difficulty.hard:
        return '高難度像素解謎';
    }
  }

  @override
  Widget build(BuildContext context) {
    final levels = Difficulty.values;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        title: const Text('選擇難度'),
        centerTitle: true,
        backgroundColor: const Color(0xFFEAF4FF),
        foregroundColor: const Color(0xFF2F4F78),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 320,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '選擇難度',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Color(0xFF2F4F78),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '請選擇你想挑戰的關卡大小',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A6D85),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ...levels.map((difficulty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _DifficultyPixelCard(
                        title: difficulty.label,
                        subtitle: _getSubtitle(difficulty),
                        backgroundColor: _getCardColor(difficulty),
                        borderColor: _getBorderColor(difficulty),
                        shadowColor: _getShadowColor(difficulty),
                        onTap: () => _startGame(context, difficulty),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyPixelCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final VoidCallback onTap;

  const _DifficultyPixelCard({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.borderColor,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        child: Row(
          children: [
            const Icon(Icons.grid_view_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}
