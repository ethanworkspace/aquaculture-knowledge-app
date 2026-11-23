import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aquaculture_knowledge_app/gateway_service.dart';
import 'package:aquaculture_knowledge_app/domain.dart';

http.Response response(Map<String, dynamic> data, [int status = 200]) =>
    http.Response(
      jsonEncode(data),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
Map<String, dynamic> session() => {
  'model_id': 'M2',
  'model_digest': 'm2-digest',
  'corpus_version': 'corpus-v6',
  'session_token': 'session-test-token',
};
Map<String, dynamic> record({
  String status = 'ANSWERED_GROUNDED',
  String digest = 'm2-digest',
}) => {
  'model_id': 'M2',
  'model_digest': digest,
  'corpus_version': 'corpus-v6',
  'answer_status': status,
  'final_answer': 'Guarded final text',
  'raw_model_answer': 'DO_NOT_SHOW_RAW',
  'answer_origin': 'MODEL_GENERATED',
  'missing_information': [],
  'evidence': [
    {
      'title': 'Actual source title',
      'locator': 'page 3',
      'quote': 'Actual source quote',
    },
  ],
};
void main() {
  test('discovery rejects non-TLS, credentials, arbitrary hosts and redirect-shaped paths', () {
    for (final value in [
      'http://a.trycloudflare.com',
      'https://evil.example',
      'https://user:pass@a.trycloudflare.com',
      'https://a.trycloudflare.com/secret',
      'https://a.trycloudflare.com?token=x',
    ]) {
      expect(
        () => GatewayService.validateBase(value),
        throwsA(isA<QuestionFailure>()),
      );
    }
    expect(
      GatewayService.validateBase('https://valid-example.trycloudflare.com')
          .host,
      'valid-example.trycloudflare.com',
    );
  });
  test(
    'auth, fixed request UUID, polling and real evidence are mapped',
    () async {
      final bodies = <String>[];
      final client = MockClient((req) async {
        if (req.url.host == 'raw.githubusercontent.com') {
          expect(req.headers.containsKey('authorization'), isFalse);
          return response({
            'service': 'marine-knowledge-api',
            'backend_url': 'https://test.trycloudflare.com',
          });
        }
        if (req.url.path == '/app/v1/session') return response(session());
        expect(req.headers['authorization'], 'Bearer session-test-token');
        if (req.method == 'POST') {
          bodies.add(req.body);
          expect(jsonDecode(req.body).containsKey('model_id'), isFalse);
          return response({
            'request_id': 'request-1',
            'status': 'RUNNING',
          }, 202);
        }
        return response({
          'request_id': 'request-1',
          'status': 'DONE',
          'record': record(),
        });
      });
      final service = GatewayService(
        client: client,
        pollInterval: Duration.zero,
      );
      await service.signIn('test-access-code');
      final job = QuestionJob(
        id: 'request-1',
        question: 'Question',
        species: '虱目魚',
        at: DateTime.now(),
      );
      final answer = await service.complete(job, DemoScenario.grounded);
      expect(answer.text, 'Guarded final text');
      expect(answer.sources.single.locator, 'page 3');
      expect(answer.origin, 'MODEL_GENERATED');
      await service.complete(job, DemoScenario.grounded);
      expect(bodies[0], bodies[1]);
      service.dispose();
    },
  );
  test('invalid output never displays raw text or sources', () async {
    final service = GatewayService(
      client: MockClient((req) async {
        if (req.url.host == 'raw.githubusercontent.com') {
          return response({
            'service': 'marine-knowledge-api',
            'backend_url': 'https://test.trycloudflare.com',
          });
        }
        if (req.url.path == '/app/v1/session') return response(session());
        return response({
          'request_id': 'request-2',
          'status': 'DONE',
          'record': record(status: 'VALIDATION_FAILED'),
        });
      }),
    );
    await service.signIn('test-code');
    final answer = await service.complete(
      QuestionJob(
        id: 'request-2',
        question: 'Q',
        species: '全部魚種',
        at: DateTime.now(),
      ),
      DemoScenario.grounded,
    );
    expect(answer.status, AnswerStatus.invalid);
    expect(answer.sources, isEmpty);
    expect(answer.text, isNot(contains('DO_NOT_SHOW_RAW')));
    service.dispose();
  });
  test('busy and ambiguous network failure are resumable, model mismatch is not accepted', () async {
    var mode = 'busy';
    final service = GatewayService(
      client: MockClient((req) async {
        if (req.url.host == 'raw.githubusercontent.com') {
          return response({
            'service': 'marine-knowledge-api',
            'backend_url': 'https://test.trycloudflare.com',
          });
        }
        if (req.url.path == '/app/v1/session') return response(session());
        if (mode == 'busy') {
          return response({
            'error': {'code': 'SERVICE_BUSY', 'message': 'Busy'},
          }, 429);
        }
        if (mode == 'network') throw http.ClientException('offline');
        return response({
          'request_id': 'request-3',
          'status': 'DONE',
          'record': record(digest: 'wrong-model'),
        });
      }),
    );
    await service.signIn('test-code');
    final job = QuestionJob(
      id: 'request-3',
      question: 'Q',
      species: '全部魚種',
      at: DateTime.now(),
    );
    for (final value in ['busy', 'network']) {
      mode = value;
      await expectLater(
        service.complete(job, DemoScenario.grounded),
        throwsA(
          isA<QuestionFailure>().having((e) => e.canResume, 'canResume', true),
        ),
      );
    }
    mode = 'mismatch';
    await expectLater(
      service.complete(job, DemoScenario.grounded),
      throwsA(isA<QuestionFailure>()),
    );
    service.dispose();
  });
  test('new mobile requests are UUID v4', () {
    final id = newRequestId();
    expect(
      id,
      matches(
        RegExp(
          r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
        ),
      ),
    );
  });
}
