import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'domain.dart';

const discoveryAddress =
    'https://raw.githubusercontent.com/ethanworkspace/hybrid-rag-aquaculture-knowledge-platform/main/streamlit_cloud/backend_endpoint.json';

class GatewayService implements AuthenticatedQuestionService {
  GatewayService({
    http.Client? client,
    this.pollInterval = const Duration(seconds: 2),
    this.maxPolls = 300,
  }) : _client = client ?? http.Client();
  final http.Client _client;
  final Duration pollInterval;
  final int maxPolls;
  Uri? _base;
  String? _token, _digest;
  @override
  String? corpusVersion;

  static Uri validateBase(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        !RegExp(r'^[a-z0-9-]+\.trycloudflare\.com$').hasMatch(uri.host) ||
        uri.userInfo.isNotEmpty ||
        uri.port != 443 ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const QuestionFailure('知識服務連線位置未通過檢查。');
    }
    return uri.replace(path: '');
  }

  Future<Map<String, dynamic>> _exchange(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final request = http.Request(method, uri)..followRedirects = false;
      request.headers['Accept'] = 'application/json';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 25));
      final bytes = BytesBuilder();
      await for (final part in response.stream.timeout(
        const Duration(seconds: 25),
      )) {
        bytes.add(part);
        if (bytes.length > 2 * 1024 * 1024) {
          throw const QuestionFailure('知識服務回應過大，已停止讀取。');
        }
      }
      dynamic data;
      try {
        data = jsonDecode(utf8.decode(bytes.takeBytes()));
      } on FormatException {
        throw const QuestionFailure('暫時無法讀取知識服務回應，請稍後接續原請求。', canResume: true);
      }
      if (data is! Map<String, dynamic>) {
        throw const QuestionFailure('知識服務回傳格式不完整。');
      }
      if (response.statusCode != 200 && response.statusCode != 202) {
        final error = data['error'];
        final code = error is Map ? error['code'] : null;
        final message = error is Map && error['message'] is String
            ? error['message'] as String
            : '知識服務暫時無法完成請求。';
        throw QuestionFailure(
          message,
          canResume: [
            'SERVICE_BUSY',
            'RATE_LIMIT',
            'JOB_NOT_FOUND',
            'SERVICE_UNAVAILABLE',
          ].contains(code),
        );
      }
      return data;
    } on http.ClientException {
      throw const QuestionFailure('暫時連不上知識服務，請確認網路後接續原請求。', canResume: true);
    } on TimeoutException {
      throw const QuestionFailure('連線等待較久，請稍後接續原請求。', canResume: true);
    }
  }

  @override
  Future<void> signIn(String accessCode) async {
    if (accessCode.isEmpty || accessCode.length > 128) {
      throw const QuestionFailure('請輸入工作區存取碼。');
    }
    final discovery = await _exchange('GET', Uri.parse(discoveryAddress));
    if (discovery['service'] != 'marine-knowledge-api' ||
        discovery['backend_url'] is! String) {
      throw const QuestionFailure('知識服務連線清單格式不正確。');
    }
    final base = validateBase(discovery['backend_url'] as String);
    final session = await _exchange(
      'POST',
      base.resolve('/app/v1/session'),
      body: {'access_code': accessCode},
    );
    if (session['model_id'] != 'M2' ||
        session['session_token'] is! String ||
        session['model_digest'] is! String ||
        session['corpus_version'] is! String) {
      throw const QuestionFailure('連線未取得已核實的 M2 模型與知識庫版本。');
    }
    _base = base;
    _token = session['session_token'] as String;
    _digest = session['model_digest'] as String;
    corpusVersion = session['corpus_version'] as String;
  }

  @override
  Future<Answer> complete(QuestionJob job, DemoScenario scenario) async {
    final base = _base, token = _token;
    if (base == null || token == null) {
      throw const QuestionFailure('連線已到期，請重新登入工作區。');
    }
    final body = {
      'request_id': job.id,
      'question': job.question,
      'selected_species': job.species,
    };
    void checkSession() {
      if (_token != token) throw const QuestionFailure('工作區連線已結束，請重新登入。');
    }

    checkSession();
    // A stable request ID is retained for ambiguous network errors and explicit resume.
    var result = await _exchange(
      'POST',
      base.resolve('/app/v1/jobs'),
      body: body,
      token: token,
    );
    for (var count = 0; count <= maxPolls; count++) {
      checkSession();
      final status = result['status'];
      if (result['request_id'] != job.id) {
        throw const QuestionFailure('問答請求識別碼未通過核對。');
      }
      if (status == 'DONE') return _answer(result['record']);
      if (status == 'FAILED') {
        final error = result['error'];
        throw QuestionFailure(
          error is Map && error['message'] is String
              ? error['message'] as String
              : '問答未完成，請重新提問。',
        );
      }
      if (status != 'RUNNING') {
        throw const QuestionFailure('問答服務回傳未知狀態，暫不顯示內容。');
      }
      if (count == maxPolls) break;
      await Future<void>.delayed(pollInterval);
      checkSession();
      result = await _exchange(
        'GET',
        base.resolve('/app/v1/jobs/${job.id}'),
        token: token,
      );
    }
    throw const QuestionFailure('問題仍在處理中，可稍後接續原請求。', canResume: true);
  }

  Answer _answer(dynamic record) {
    if (record is! Map<String, dynamic> ||
        record['model_id'] != 'M2' ||
        record['model_digest'] != _digest ||
        record['corpus_version'] != corpusVersion) {
      throw const QuestionFailure('回答模型或知識庫版本未通過核對，暫不顯示內容。');
    }
    final safe = presentAnswer(record);
    final sources = <SourceEvidence>[];
    if (safe.status == AnswerStatus.grounded ||
        safe.status == AnswerStatus.partial) {
      if (record['evidence'] is List) {
        for (final source in record['evidence'] as List) {
          if (source is! Map ||
              source['title'] is! String ||
              source['quote'] is! String ||
              source['locator'] is! String) {
            continue;
          }
          sources.add(
            SourceEvidence(
              title: source['title'] as String,
              quote: source['quote'] as String,
              locator: source['locator'] as String,
            ),
          );
        }
      }
    }
    return Answer(
      status: safe.status,
      text: safe.text,
      sources: sources,
      missing: record['missing_information'] is List
          ? (record['missing_information'] as List).whereType<String>().toList()
          : [],
      origin: record['answer_origin'] is String
          ? record['answer_origin'] as String
          : '',
      corpusVersion: corpusVersion ?? '',
      modelDigest: _digest ?? '',
    );
  }

  @override
  Future<void> signOut() async {
    final token = _token, base = _base;
    _token = null;
    _digest = null;
    corpusVersion = null;
    if (token != null && base != null) {
      try {
        await _exchange(
          'DELETE',
          base.resolve('/app/v1/session'),
          token: token,
        );
      } on QuestionFailure {
        /* Local logout remains effective when offline. */
      }
    }
  }

  @override
  void dispose() {
    _token = null;
    _client.close();
  }
}
