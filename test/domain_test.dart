import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:aquaculture_knowledge_app/domain.dart';

class PendingService implements QuestionService {
  final pending = <Completer<Answer>>[];
  @override
  Future<Answer> complete(QuestionJob job, DemoScenario scenario) {
    final completer = Completer<Answer>();
    pending.add(completer);
    return completer.future;
  }
}

void main() {
  test('invalid and unknown statuses never expose final or raw model text', () {
    for (final status in ['VALIDATION_FAILED', 'UNKNOWN']) {
      final answer = presentAnswer({
        'answer_status': status,
        'final_answer': 'blocked final',
        'raw_model_answer': 'blocked raw',
      });
      expect(answer.status, AnswerStatus.invalid);
      expect(answer.text, isNot(contains('blocked')));
    }
    expect(
      presentAnswer({
        'answer_status': 'ANSWERED_GROUNDED',
        'raw_model_answer': 'blocked raw',
      }).status,
      AnswerStatus.invalid,
    );
  });
  test('valid answer uses only guarded text', () {
    final answer = presentAnswer({
      'answer_status': 'ANSWERED_GROUNDED',
      'final_answer': 'guarded',
      'raw_model_answer': 'raw',
    });
    expect(answer.status, AnswerStatus.grounded);
    expect(answer.text, 'guarded');
  });
  test('question validation matches API length and character constraints', () {
    expect(validateQuestion('  '), isNotNull);
    expect(validateQuestion('fish\u0000'), isNotNull);
    expect(validateQuestion('魚' * 2001), isNotNull);
    expect(validateQuestion('魚' * 2000), isNull);
  });
  test('all seven demo scenarios finish with the intended state', () async {
    for (final scenario in DemoScenario.values) {
      final store = AppStore(
        service: const DemoQuestionService(delay: Duration.zero),
      );
      store.setScenario(scenario);
      final id = store.submit('問題', '虱目魚');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final job = store.findJob(id)!;
      if ([
        DemoScenario.offline,
        DemoScenario.busy,
        DemoScenario.failed,
      ].contains(scenario)) {
        expect(job.status, JobStatus.failed);
        expect(job.error, isNotEmpty);
      } else {
        expect(job.status, JobStatus.done);
        if ([
          DemoScenario.invalid,
          DemoScenario.insufficient,
        ].contains(scenario)) {
          expect(job.answer!.sources, isEmpty);
        }
      }
      store.dispose();
    }
  });
  test(
    'one active task, clear invalidates late completion, dispose is safe',
    () async {
      final service = PendingService();
      final store = AppStore(service: service);
      store.submit('問題', '虱目魚');
      expect(() => store.submit('另一個問題', '鱸魚'), throwsStateError);
      store.clear();
      service.pending.first.complete(
        const Answer(status: AnswerStatus.grounded, text: 'late'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(store.jobs, isEmpty);
      store.submit('新問題', '鱸魚');
      store.dispose();
      service.pending.last.complete(
        const Answer(status: AnswerStatus.grounded, text: 'after dispose'),
      );
      await Future<void>.delayed(Duration.zero);
    },
  );
  test('saving is idempotent; note editing and removal preserve original answer and history', () async {
    final store = AppStore(
      service: const DemoQuestionService(delay: Duration.zero),
    );
    final id = store.submit('問題', '虱目魚');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final job = store.findJob(id)!;
    final original = job.answer!.text;
    store.save(job);
    store.save(job);
    expect(store.saved.length, 1);
    store.updateNote(id, 'personal observation');
    expect(job.answer!.text, original);
    store.removeSaved(id);
    expect(store.saved, isEmpty);
    expect(store.jobs.length, 1);
    store.logout();
    expect(store.jobs, isEmpty);
    expect(store.signedIn, false);
    store.dispose();
  });
}
