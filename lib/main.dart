import 'package:flutter/material.dart';
import 'services/puzzle_repository.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PuzzleRepository.loadPuzzles();

  runApp(const NonogramApp());
}

class NonogramApp extends StatelessWidget {
  const NonogramApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '數織遊戲',
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      home: const HomePage(),
    );
  }
}
