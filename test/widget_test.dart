import 'package:flutter_test/flutter_test.dart';
import 'package:first_aigame/main.dart';

void main() {
  testWidgets('Home page shows main menu buttons', (WidgetTester tester) async {
    // 建立 App
    await tester.pumpWidget(const NonogramApp());

    // 等待 UI 完全載入
    await tester.pumpAndSettle();

    // 檢查標題
    expect(find.text('數織遊戲'), findsOneWidget);

    // 檢查三個主要按鈕
    expect(find.text('開始遊戲'), findsOneWidget);
    expect(find.text('紀錄館'), findsOneWidget);
    expect(find.text('玩家上傳模式'), findsOneWidget);
  });
}
