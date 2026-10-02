// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:step_seoul_app/main.dart';

void main() {
  testWidgets('Dashboard renders at desktop and phone widths', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('본사 임원 대시보드'), findsOneWidget);
    expect(find.text('최근 7일 판매금액'), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Navigation, search, and detail work', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('주문 · 배송').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '에어 러너');
    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();
    expect(find.text('클래식 로퍼'), findsNothing);
    expect(find.text('에어 러너 01'), findsWidgets);
    await tester.tap(find.text('상세보기').first);
    await tester.pumpAndSettle();
    expect(find.text('상세 정보'), findsOneWidget);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final name in ['전체 재고', '품의 관리', '발주 · 수주', '판매 현황', '기준 정보']) {
      await tester.tap(find.text(name).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: name);
    }
    await tester.tap(find.text('기준 정보 등록'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('이름을 입력하세요'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '새로운 대리점');
    await tester.enterText(fields.at(1), '서울시 강남구');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('새로운 대리점'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
