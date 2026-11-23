import 'package:flutter/foundation.dart';

const fishSpecies = ['虱目魚', '吳郭魚', '石斑魚', '鱸魚', '烏魚', '鰻魚'];
const sampleQuestions = [
  ('虱目魚遇到寒流，應先確認哪些資料？', '虱目魚', '氣候防寒'),
  ('吳郭魚水質管理要記錄哪些資訊？', '吳郭魚', '水質環境'),
  ('石斑魚攝食減少，提問時要補充什麼？', '石斑魚', '養殖管理'),
];

enum AnswerStatus { grounded, partial, insufficient, invalid }

enum DemoScenario {
  grounded,
  partial,
  insufficient,
  invalid,
  offline,
  busy,
  failed,
}

enum JobStatus { running, done, failed }

String scenarioLabel(DemoScenario value) => const {
  DemoScenario.grounded: '有據回答',
  DemoScenario.partial: '部分資訊',
  DemoScenario.insufficient: '證據不足',
  DemoScenario.invalid: '驗證未通過',
  DemoScenario.offline: '服務離線',
  DemoScenario.busy: '服務忙碌',
  DemoScenario.failed: '任務失敗',
}[value]!;
String answerLabel(AnswerStatus value) => const {
  AnswerStatus.grounded: '有據回答',
  AnswerStatus.partial: '部分資訊',
  AnswerStatus.insufficient: '證據不足',
  AnswerStatus.invalid: '回答待核對',
}[value]!;
String? validateQuestion(String text) {
  if (text.trim().isEmpty) return '請先輸入問題。';
  if (text.runes.length > 2000 || text.contains('\u0000')) {
    return '請輸入 2,000 字以內的有效問題。';
  }
  return null;
}

class SourceEvidence {
  const SourceEvidence({
    required this.title,
    required this.quote,
    required this.locator,
  });
  final String title, quote, locator;
}

class Answer {
  const Answer({
    required this.status,
    required this.text,
    this.sources = const [],
    this.missing = const [],
  });
  final AnswerStatus status;
  final String text;
  final List<SourceEvidence> sources;
  final List<String> missing;
}

// Never substitute raw_model_answer for a guarded answer.
Answer presentAnswer(Map<String, dynamic> result) {
  const statuses = {
    'ANSWERED_GROUNDED': AnswerStatus.grounded,
    'ANSWERED_PARTIAL': AnswerStatus.partial,
    'INSUFFICIENT_EVIDENCE': AnswerStatus.insufficient,
  };
  final status = statuses[result['answer_status']];
  final text = result['final_answer'];
  if (status == null || text is! String || text.trim().isEmpty) {
    return const Answer(
      status: AnswerStatus.invalid,
      text: '本次回答未通過檢查，暫不顯示內容。請補充條件後重新提問。',
    );
  }
  return Answer(status: status, text: text);
}

class QuestionJob {
  QuestionJob({
    required this.id,
    required this.question,
    required this.species,
    required this.at,
  });
  final String id, question, species;
  final DateTime at;
  JobStatus status = JobStatus.running;
  Answer? answer;
  String? error;
}

class SavedAnswer {
  SavedAnswer(this.job);
  final QuestionJob job;
  String note = '';
}

abstract interface class QuestionService {
  Future<Answer> complete(QuestionJob job, DemoScenario scenario);
}

class DemoQuestionService implements QuestionService {
  const DemoQuestionService({this.delay = const Duration(seconds: 1)});
  final Duration delay;
  @override
  Future<Answer> complete(QuestionJob job, DemoScenario scenario) async {
    await Future<void>.delayed(delay);
    switch (scenario) {
      case DemoScenario.offline:
        throw StateError('暫時連不上知識服務。此為離線示範，問題尚未送出。');
      case DemoScenario.busy:
        throw StateError('目前有其他問答進行中，問題尚未加入排程，請稍後再試。');
      case DemoScenario.failed:
        throw StateError('這次問答未完成，請建立新的嘗試。');
      case DemoScenario.invalid:
        return presentAnswer({'answer_status': 'VALIDATION_FAILED'});
      case DemoScenario.insufficient:
        return const Answer(
          status: AnswerStatus.insufficient,
          text: '目前沒有足夠證據回答。請補充魚種、環境與觀察紀錄。',
          missing: ['具體養殖條件', '觀察時間與紀錄'],
        );
      case DemoScenario.grounded:
      case DemoScenario.partial:
        return Answer(
          status: scenario == DemoScenario.partial
              ? AnswerStatus.partial
              : AnswerStatus.grounded,
          text: '這裡將呈現由既有問答引擎產生、經引用檢查後的回答。此為畫面占位，未呼叫模型，也未提供實際養殖建議。',
          sources: const [
            SourceEvidence(
              title: '示範文件名稱（非真實來源）',
              quote: '這裡顯示引用原文摘錄。此段為版型占位，不能作為養殖依據。',
              locator: '頁碼與章節位置占位',
            ),
          ],
          missing: scenario == DemoScenario.partial
              ? ['實際養殖環境與觀察紀錄']
              : const [],
        );
    }
  }
}

class AppStore extends ChangeNotifier {
  AppStore({this.service = const DemoQuestionService()});
  final QuestionService service;
  final List<QuestionJob> _jobs = [];
  final List<SavedAnswer> _saved = [];
  List<QuestionJob> get jobs => List.unmodifiable(_jobs);
  List<SavedAnswer> get saved => List.unmodifiable(_saved);
  bool signedIn = false;
  DemoScenario scenario = DemoScenario.grounded;
  bool _busy = false, _disposed = false;
  int _epoch = 0, _serial = 0;
  void login() {
    signedIn = true;
    notifyListeners();
  }

  void setScenario(DemoScenario value) {
    scenario = value;
    notifyListeners();
  }

  String submit(String question, String species) {
    final invalid = validateQuestion(question);
    if (invalid != null) throw StateError(invalid);
    if (!['全部魚種', ...fishSpecies].contains(species)) {
      throw StateError('請選擇有效魚種。');
    }
    if (_busy) throw StateError('已有一筆示範問答處理中，請先查看紀錄。');
    _busy = true;
    final epoch = _epoch;
    final job = QuestionJob(
      id: 'demo-${++_serial}',
      question: question.trim(),
      species: species,
      at: DateTime.now(),
    );
    _jobs.insert(0, job);
    notifyListeners();
    _complete(job, scenario, epoch);
    return job.id;
  }

  Future<void> _complete(
    QuestionJob job,
    DemoScenario scenario,
    int epoch,
  ) async {
    try {
      final answer = await service.complete(job, scenario);
      if (_disposed || epoch != _epoch) return;
      job.answer = answer;
      job.status = JobStatus.done;
    } catch (error) {
      if (_disposed || epoch != _epoch) return;
      job.error = error is StateError ? error.message.toString() : '本次問答未完成。';
      job.status = JobStatus.failed;
    } finally {
      if (!_disposed && epoch == _epoch) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  QuestionJob? findJob(String id) {
    for (final job in _jobs) {
      if (job.id == id) return job;
    }
    for (final item in _saved) {
      if (item.job.id == id) return item.job;
    }
    return null;
  }

  SavedAnswer? findSaved(String id) {
    for (final item in _saved) {
      if (item.job.id == id) return item;
    }
    return null;
  }

  void save(QuestionJob job) {
    if (job.status != JobStatus.done ||
        (job.answer?.sources.isEmpty ?? true) ||
        findSaved(job.id) != null) {
      return;
    }
    _saved.insert(0, SavedAnswer(job));
    notifyListeners();
  }

  void updateNote(String id, String note) {
    final item = findSaved(id);
    if (item == null) return;
    item.note = note;
    notifyListeners();
  }

  void removeSaved(String id) {
    _saved.removeWhere((s) => s.job.id == id);
    notifyListeners();
  }

  void clear() {
    _epoch++;
    _busy = false;
    _jobs.clear();
    _saved.clear();
    notifyListeners();
  }

  void logout() {
    signedIn = false;
    clear();
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
