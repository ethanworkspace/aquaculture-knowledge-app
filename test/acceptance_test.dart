import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:aquaculture_knowledge_app/domain.dart';
import 'package:aquaculture_knowledge_app/gateway_service.dart';

import 'gateway_test.dart' as fixtures;

void main() {
  test('completion arriving on the last allowed poll is displayed', () async {
    final service = GatewayService(
      pollInterval: Duration.zero,
      maxPolls: 1,
      client: MockClient((request) async {
        if (request.url.host == 'raw.githubusercontent.com') {
          return fixtures.response({
            'service': 'marine-knowledge-api',
            'backend_url': 'https://test.trycloudflare.com',
          });
        }
        if (request.url.path == '/app/v1/session') {
          return fixtures.response(fixtures.session());
        }
        return fixtures.response({
          'request_id': 'last-poll',
          'status': request.method == 'POST' ? 'RUNNING' : 'DONE',
          if (request.method == 'GET') 'record': fixtures.record(),
        });
      }),
    );
    addTearDown(service.dispose);
    await service.signIn('test-only-code');
    final answer = await service.complete(
      QuestionJob(
        id: 'last-poll',
        question: 'A question answered just before the deadline',
        species: '全部魚種',
        at: DateTime.now(),
      ),
      DemoScenario.grounded,
    );
    expect(answer.text, 'Guarded final text');
    expect(answer.sources, isNotEmpty);
  });
}
