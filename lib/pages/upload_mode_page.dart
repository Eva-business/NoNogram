import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/difficulty.dart';
import '../services/puzzle_generator.dart';
import '../widgets/pixel_button.dart';
import 'game_page.dart';

class UploadModePage extends StatefulWidget {
  const UploadModePage({super.key});

  @override
  State<UploadModePage> createState() => _UploadModePageState();
}

class _UploadModePageState extends State<UploadModePage> {
  Difficulty selectedDifficulty = Difficulty.easy;
  File? selectedImage;
  bool isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    setState(() {
      selectedImage = File(file.path);
    });
  }

  Future<void> _startCustomPuzzle() async {
    if (selectedImage == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final puzzle = await PuzzleGenerator.generateFromFile(
        imageFile: selectedImage!,
        difficulty: selectedDifficulty,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GamePage(puzzle: puzzle)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('圖片轉換失敗：$e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Color _difficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return const Color(0xFF74B47B);
      case Difficulty.medium:
        return const Color(0xFF5C88C4);
      case Difficulty.hard:
        return const Color(0xFFF0B35A);
    }
  }

  Color _difficultyBorder(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return const Color(0xFF3E6B44);
      case Difficulty.medium:
        return const Color(0xFF2F4F78);
      case Difficulty.hard:
        return const Color(0xFF9A6423);
    }
  }

  Color _difficultyShadow(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return const Color(0xFF29472D);
      case Difficulty.medium:
        return const Color(0xFF1E3552);
      case Difficulty.hard:
        return const Color(0xFF6C4314);
    }
  }

  Widget _buildDifficultyOption(Difficulty difficulty) {
    final selected = selectedDifficulty == difficulty;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDifficulty = difficulty;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _difficultyColor(difficulty),
          border: Border.all(
            color: selected ? Colors.white : _difficultyBorder(difficulty),
            width: selected ? 3.5 : 3,
          ),
          boxShadow: [
            BoxShadow(
              color: _difficultyShadow(difficulty),
              offset: const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          difficulty.label,
          style: TextStyle(
            color: difficulty == Difficulty.hard
                ? const Color(0xFF2B1A05)
                : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildPixelUploadButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF8CC6FF),
          border: Border.all(color: const Color(0xFF3E6FA3), width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF2B5681),
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              '從相簿選擇圖片',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewBox() {
    if (selectedImage != null) {
      return Container(
        width: 220,
        height: 220,
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
        child: ClipRect(child: Image.file(selectedImage!, fit: BoxFit.cover)),
      );
    }

    return Container(
      width: 220,
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFE),
        border: Border.all(color: const Color(0xFFD7E4F2), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFC9D9EA),
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 42, color: Color(0xFF8AA3BF)),
          SizedBox(height: 10),
          Text(
            '尚未選擇圖片',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7D92),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFB9C8D8),
          border: Border.all(color: const Color(0xFF7D8FA5), width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF627488),
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return PixelButton(
      text: '生成自訂關卡',
      backgroundColor: const Color(0xFFB884F6),
      borderColor: const Color(0xFF7446B2),
      shadowColor: const Color(0xFF512D80),
      onPressed: _startCustomPuzzle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        title: const Text('玩家上傳模式'),
        centerTitle: true,
        backgroundColor: const Color(0xFFEAF4FF),
        foregroundColor: const Color(0xFF2F4F78),
        elevation: 0,
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
                    '自訂你的關卡',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Color(0xFF2F4F78),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '上傳一張圖片，系統會幫你轉成數織關卡',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A6D85),
                    ),
                  ),
                  const SizedBox(height: 22),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '1. 選擇難度',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2F4F78),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: Difficulty.values
                        .map((d) => _buildDifficultyOption(d))
                        .toList(),
                  ),

                  const SizedBox(height: 24),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '2. 選擇圖片',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2F4F78),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildPixelUploadButton(),

                  const SizedBox(height: 22),

                  _buildPreviewBox(),

                  const Spacer(),

                  Opacity(
                    opacity: selectedImage == null && !isLoading ? 0.6 : 1,
                    child: IgnorePointer(
                      ignoring: selectedImage == null && !isLoading,
                      child: _buildGenerateButton(),
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
