import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:aquaculture_knowledge_app/gateway_service.dart';
import 'package:aquaculture_knowledge_app/domain.dart';

void main() {
  test(
    'real Flutter client: HTTPS workspace -> M2 -> grounded source',
    () async {
      final service = GatewayService();
      final code = Platform.environment['MARINE_TEST_ACCESS_CODE'];
      expect(code, isNotNull);
      await service.signIn(code!);
      final job = QuestionJob(
        id: newRequestId(),
        question: '虱目魚常見的養殖方式有哪些？',
        species: '虱目魚',
        at: DateTime.now(),
      );
      final answer = await service.complete(job, DemoScenario.grounded);
      expect([
        AnswerStatus.grounded,
        AnswerStatus.partial,
      ], contains(answer.status));
      expect(answer.sources, isNotEmpty);
      expect(answer.origin, 'MODEL_GENERATED');
      expect(answer.corpusVersion, isNotEmpty);
      final path = Platform.environment['MARINE_TEST_RESULT_PATH'];
      if (path != null) {
        File(path).writeAsStringSync(
          jsonEncode({
            'passed': true,
            'model_id': 'M2',
            'model_digest': answer.modelDigest,
            'corpus_version': answer.corpusVersion,
            'evidence_count': answer.sources.length,
            'answer_status': answer.status.name,
            'mocked': false,
          }),
        );
      }
      await service.signOut();
      service.dispose();
    },
    skip: Platform.environment['MARINE_LIVE_TEST'] != '1',
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
