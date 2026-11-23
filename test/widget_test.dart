import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:aquaculture_knowledge_app/main.dart';
import 'package:aquaculture_knowledge_app/domain.dart';

void main() {
  testWidgets('Phone flow: login, ask, sources, save independent note', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = AppStore(
      service: const DemoQuestionService(delay: Duration.zero),
    );
    await tester.pumpWidget(AquacultureApp(store: store));
    await tester.tap(find.text('進入示範帳號'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('開始提問'));
    await tester.tap(find.text('開始提問'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '虱目魚遇到寒流，應先確認哪些資料？');
    await tester.ensureVisible(find.text('送出問題'));
    await tester.tap(find.text('送出問題'));
    await tester.pumpAndSettle();
    expect(find.text('有據回答'), findsOneWidget);
    await tester.ensureVisible(find.text('查看引用來源（示範）'));
    await tester.tap(find.text('查看引用來源（示範）'));
    await tester.pumpAndSettle();
    expect(find.text('示範文件名稱（非真實來源）'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('收藏這則回答'));
    await tester.tap(find.text('收藏這則回答'));
    await tester.pumpAndSettle();
    final original = store.saved.single.job.answer!.text;
    await tester.enterText(find.byType(TextField).first, '下次整理觀察紀錄');
    await tester.ensureVisible(find.text('儲存示範筆記'));
    await tester.tap(find.text('儲存示範筆記'));
    await tester.pumpAndSettle();
    expect(store.saved.single.note, '下次整理觀察紀錄');
    expect(store.saved.single.job.answer!.text, original);
    expect(tester.takeException(), isNull);
  });
  testWidgets('320px phone login remains readable without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(AquacultureApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('進入示範帳號'));
    expect(tester.takeException(), isNull);
  });
}
