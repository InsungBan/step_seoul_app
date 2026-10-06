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

  Future<void> createProposal(
    String title,
    String content, {
    required String employeeId,
    required String requestedAmount,
  }) async {
    final response = await _client
        .post(
          Uri.parse(
            '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/approval/submit',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'approval_name': title,
            'approval_content': content,
            'employee_employee_id': employeeId,
            'requested_amount': requestedAmount,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Proposal save failed');
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['result'] != 'CREATE OK') {
      throw const FormatException('Invalid save response');
    }
  }

  Future<void> approveFinal(HqRow row) async {
    final keys = [
      'employee_employee_id',
      'approval_approval_id',
      'approval_process_id',
    ];
    if (keys.any((key) => row[key] == null || row[key].toString().isEmpty)) {
      throw const FormatException('결재 처리 식별 정보가 없습니다.');
    }
    final path = keys
        .map((key) => Uri.encodeComponent(row[key].toString()))
        .join('/');
    final response = await _client
        .put(
          Uri.parse(
            '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/approval_process/update/$path',
          ),
          body: {
            'director_approval': '승인',
            'approval_status': '승인완료',
            'processed_at': DateTime.now()
                .toUtc()
                .add(const Duration(hours: 9))
                .toIso8601String()
                .replaceAll('Z', ''),
          },
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Final approval failed (HTTP ${response.statusCode})');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['result'] != 'UPDATE OK') {
      throw const FormatException('Invalid approval response');
    }
  }

  Future<void> approveProposal(String approvalId, String employeeId) async {
    final response = await _client
        .post(
          Uri.parse(
            '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/approval_process/approve/${Uri.encodeComponent(approvalId)}',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'employee_id': employeeId}),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Approval failed (${response.statusCode})');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['result'] != 'UPDATE OK') {
      throw const FormatException('Invalid approval response');
    }
  }

  void close() => _client.close();

  Future<void> dispatchShipments(List<HqRow> shipments) async {
    final response = await _client
        .put(
          Uri.parse(
            '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/shipment/dispatch',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'shipments': shipments
                .map(
                  (row) => {
                    for (final key in [
                      'shoe_shoe_id',
                      'employee_employee_id',
                      'shipment_id',
                      'store_store_id',
                    ])
                      key: row[key],
                  },
                )
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Dispatch failed (${response.statusCode})');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['result'] != 'UPDATE OK') {
      throw const FormatException('Invalid dispatch response');
    }
  }

  Future<void> createMasterRecord(
    String type,
    Map<String, String> fields,
  ) async {
    if (!['employee', 'store'].contains(type)) {
      throw ArgumentError('Invalid record type');
    }
    final response = await _client
        .post(
          Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/$type/upload'),
          body: fields,
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 409) {
      throw Exception(
        type == 'store'
            ? '이미 등록된 자치구 또는 대리점 ID입니다. 목록을 새로고침해 주세요.'
            : '이미 등록된 직원 ID입니다.',
      );
    }
    if (response.statusCode != 200) {
      throw Exception('저장에 실패했습니다. 입력 정보와 서버 연결을 확인해 주세요.');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['result'] != 'CREATE OK') {
      throw const FormatException('Invalid creation response');
    }
  }
}

String hqNumber(num value) => value
    .toStringAsFixed(0)
    .replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
