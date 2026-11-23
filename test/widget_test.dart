import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:aquaculture_knowledge_app/main.dart';
import 'package:aquaculture_knowledge_app/domain.dart';
import 'package:aquaculture_knowledge_app/gateway_service.dart';
import 'package:http/testing.dart';

import 'gateway_test.dart' as fixtures;

void main() {
  testWidgets('Live login errors and answer sources work on a 320px phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var permitLogin = false;
    late final AppStore store;
    final service = GatewayService(
      client: MockClient((req) async {
        if (req.url.host == 'raw.githubusercontent.com') {
          return fixtures.response({
            'service': 'marine-knowledge-api',
            'backend_url': 'https://test.trycloudflare.com',
          });
        }
        if (req.url.path == '/app/v1/session') {
          return permitLogin
              ? fixtures.response(fixtures.session())
              : fixtures.response({
                  'error': {
                    'code': 'INVALID_ACCESS_CODE',
                    'message': '工作區存取碼不正確。',
                  },
                }, 401);
        }
        return fixtures.response({
          'request_id': store.jobs.single.id,
          'status': 'DONE',
          'record': fixtures.record(),
        });
      }),
    );
    store = AppStore(service: service);
    await tester.pumpWidget(AquacultureApp(store: store));
    expect(find.text('進入示範帳號'), findsNothing);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'test-only-access-code');
    await tester.ensureVisible(find.text('連線登入'));
    await tester.runAsync(() async {
      await tester.tap(find.text('連線登入'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('工作區存取碼不正確。'), findsOneWidget);
    permitLogin = true;
    await tester.runAsync(() async {
      await tester.tap(find.text('連線登入'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('線上知識庫 · M2 問答'), findsOneWidget);
    await tester.ensureVisible(find.text('開始提問'));
    await tester.tap(find.text('開始提問'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'Test a real-service UI question',
    );
    await tester.ensureVisible(find.text('送出問題'));
    await tester.runAsync(() async {
      await tester.tap(find.text('送出問題'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('Guarded final text'), findsOneWidget);
    expect(find.text('知識庫版本：corpus-v6'), findsOneWidget);
    await tester.ensureVisible(find.text('查看引用來源'));
    await tester.tap(find.text('查看引用來源'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Actual source quote'));
    expect(find.text('Actual source quote'), findsOneWidget);
    expect(find.text('查看引用來源（示範）'), findsNothing);
    expect(tester.takeException(), isNull);
  });
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
    await tester.pumpWidget(AquacultureApp(store: AppStore()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('進入示範帳號'));
    expect(tester.takeException(), isNull);
  });
}
