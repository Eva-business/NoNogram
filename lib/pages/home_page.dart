import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../services/audio_service.dart';
import '../widgets/pixel_button.dart';
import 'difficulty_page.dart';
import 'record_page.dart';
import 'upload_mode_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  bool isMuted = false;
  bool isReversed = false;

  late final AnimationController _earthTapController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _initMusic();

    _earthTapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.86,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.86,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.08,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_earthTapController);

    _rotateAnimation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _earthTapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _earthTapController.dispose();
    super.dispose();
  }

  Future<void> _initMusic() async {
    await AudioService.playBgm();
  }

  Future<void> _toggleMusicFromEarth() async {
    final oldReversed = isReversed;

    setState(() {
      isMuted = !isMuted;
      isReversed = !isReversed;
    });

    await _earthTapController.forward(from: 0);

    if (mounted) {
      setState(() {
        // 保持最終翻面狀態
      });
    }

    await AudioService.setVolume(isMuted ? 0.0 : 1.0);

    // 確保動畫結束後固定在新方向，不回彈到原角度
    if (_earthTapController.status == AnimationStatus.completed) {
      _earthTapController.value = 0;
    }

    // oldReversed 只是避免 analyzer warning 可不使用
    if (oldReversed == isReversed) {}
  }

  Widget _buildEarthMusicArea() {
    return GestureDetector(
      onTap: _toggleMusicFromEarth,
      child: AnimatedBuilder(
        animation: _earthTapController,
        builder: (context, child) {
          final extraRotation = _rotateAnimation.value;
          final baseRotation = isReversed ? pi : 0.0;
          final totalRotation = baseRotation + extraRotation;

          return Column(
            children: [
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(pi + totalRotation),
                child: Lottie.asset(
                  'assets/lottie/Stickman.json',
                  width: 140,
                  repeat: true,
                ),
              ),
              const SizedBox(height: 2),
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(_scaleAnimation.value)
                  ..rotateY(totalRotation),
                child: SizedBox(
                  width: 190,
                  child: Lottie.asset('assets/lottie/Earth.json', repeat: true),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 300,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFB7CCE6),
                      width: 3,
                    ),
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
                        '數織遊戲',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: Color(0xFF2F4F78),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '歡迎來到像素世界',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5A6D85),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),

                      Container(
                        width: 240,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFEFF),
                          border: Border.all(
                            color: const Color(0xFFD7E4F2),
                            width: 5,
                          ),
                        ),
                        child: _buildEarthMusicArea(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 34),

                PixelButton(
                  text: '開始遊戲',
                  backgroundColor: const Color(0xFF5C88C4),
                  borderColor: const Color(0xFF2F4F78),
                  shadowColor: const Color(0xFF1E3552),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DifficultyPage()),
                    );
                  },
                ),

                const SizedBox(height: 18),

                PixelButton(
                  text: '玩家上傳模式',
                  backgroundColor: const Color(0xFF74B47B),
                  borderColor: const Color(0xFF3E6B44),
                  shadowColor: const Color(0xFF29472D),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UploadModePage()),
                    );
                  },
                ),

                const SizedBox(height: 18),

                PixelButton(
                  text: '紀錄館',
                  backgroundColor: const Color(0xFFF0B35A),
                  borderColor: const Color(0xFF9A6423),
                  shadowColor: const Color(0xFF6C4314),
                  textColor: const Color(0xFF2B1A05),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RecordPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
