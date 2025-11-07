// 기본적인 Flutter 위젯 테스트 예시입니다.
//
// WidgetTester를 사용하면 탭, 스크롤 같은 제스처를 보내거나
// 위젯 트리에서 자식 위젯을 찾고, 텍스트를 읽고,
// 특정 위젯 속성 값이 기대대로인지 확인할 수 있습니다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // 앱을 빌드하고 첫 프레임을 그립니다.
    await tester.pumpWidget(const PTApp());

    // 카운터가 0에서 시작하는지 확인합니다.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // '+' 아이콘을 탭해 프레임을 다시 그립니다.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // 카운터 값이 증가했는지 검증합니다.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
