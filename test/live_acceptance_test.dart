import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:aquaculture_knowledge_app/domain.dart';
import 'package:aquaculture_knowledge_app/gateway_service.dart';

void main() {
  test(
    'out-of-corpus question returns a guarded response without evidence',
    () async {
      final service = GatewayService();
      try {
        await service.signIn(Platform.environment['MARINE_TEST_ACCESS_CODE']!);
        final answer = await service.complete(
          QuestionJob(
            id: newRequestId(),
            question: '請提供火星上養殖獨角獸的官方養殖規範與精確投餌比例。',
            species: '全部魚種',
            at: DateTime.now(),
          ),
          DemoScenario.grounded,
        );
        expect([
          AnswerStatus.insufficient,
          AnswerStatus.invalid,
        ], contains(answer.status));
        expect(answer.sources, isEmpty);
        expect(answer.text, isNotEmpty);
      } finally {
        await service.signOut();
        service.dispose();
      }
    },
    skip: Platform.environment['MARINE_LIVE_TEST'] != '1',
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
