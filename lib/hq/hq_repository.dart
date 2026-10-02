import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

typedef HqRow = Map<String, dynamic>;

class HqRepository {
  HqRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? _defaultBaseUrl();

  static String _defaultBaseUrl() {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.trim().isNotEmpty) return configured.trim();
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }

  final http.Client _client;
  final String baseUrl;

  Future<Map<String, List<HqRow>>> load({
    DateTime? start,
    DateTime? end,
  }) async {
    String day(DateTime d) => d.toIso8601String().substring(0, 10);
    final url =
        Uri.parse(
          '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/hq/snapshot',
        ).replace(
          queryParameters: {
            if (start != null) 'start': day(start),
            if (end != null) 'end': day(end),
          },
        );
    final response = await _client
        .get(url)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('데이터 조회 실패 (HTTP ${response.statusCode})');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['result'] is! Map) {
      throw const FormatException('잘못된 서버 응답');
    }
    final result = <String, List<HqRow>>{};
    for (final entry in (decoded['result'] as Map).entries) {
      if (entry.value is! List) throw const FormatException('잘못된 목록 응답');
      result[entry.key.toString()] = (entry.value as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    }
    for (final table in [
      'shoe',
      'purchase',
      'shipment',
      'receive',
      'return_record',
      'approval',
      'approval_process',
      'purchase_order',
      'get_order',
      'payment',
      'user',
      'employee',
      'store',
      'shoe_manufacturer',
    ]) {
      if (!result.containsKey(table)) {
        throw FormatException('서버 응답에 $table 목록이 없습니다.');
      }
    }
    return result;
  }

  Future<void> createProposal(String title, String content) async {
    final id = 'PR${DateTime.now().microsecondsSinceEpoch}';
    final response = await _client
        .post(
          Uri.parse(
            '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/approval/upload',
          ),
          body: {
            'approval_id': id,
            'approval_name': title,
            'approval_content': content,
          },
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Proposal save failed');
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['result'] != 'CREATE OK') {
      throw const FormatException('Invalid save response');
    }
  }

  void close() => _client.close();
}

String hqNumber(num value) => value
    .toStringAsFixed(0)
    .replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
