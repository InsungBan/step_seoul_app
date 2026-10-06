import 'package:flutter/material.dart';
import 'hq_repository.dart';

class HqCreateRecordDialog extends StatefulWidget {
  const HqCreateRecordDialog({
    super.key,
    required this.repository,
    required this.type,
    required this.occupiedDistricts,
  });
  final HqRepository repository;
  final String type;
  final Set<String> occupiedDistricts;

  @override
  State<HqCreateRecordDialog> createState() => _HqCreateRecordDialogState();
}

class _HqCreateRecordDialogState extends State<HqCreateRecordDialog> {
  static const districts = [
    '종로구',
    '중구',
    '용산구',
    '성동구',
    '광진구',
    '동대문구',
    '중랑구',
    '성북구',
    '강북구',
    '도봉구',
    '노원구',
    '은평구',
    '서대문구',
    '마포구',
    '양천구',
    '강서구',
    '구로구',
    '금천구',
    '영등포구',
    '동작구',
    '관악구',
    '서초구',
    '강남구',
    '송파구',
    '강동구',
  ];
  final form = GlobalKey<FormState>();
  final id = TextEditingController();
  final name = TextEditingController();
  final department = TextEditingController();
  final password = TextEditingController();
  final phone = TextEditingController();
  String? position, district, error;
  bool saving = false;
  bool get employee => widget.type == 'employee';

  @override
  void dispose() {
    for (final controller in [id, name, department, password, phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget input(
    TextEditingController controller,
    String label,
    int max, {
    bool required = true,
    bool secret = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      maxLength: max,
      obscureText: secret,
      enabled: !saving,
      decoration: InputDecoration(labelText: '$label${required ? ' *' : ''}'),
      validator: (value) => required && (value == null || value.trim().isEmpty)
          ? '$label을 입력해 주세요.'
          : null,
    ),
  );

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.repository.createMasterRecord(
        widget.type,
        employee
            ? {
                'employee_id': id.text.trim(),
                'employee_name': name.text.trim(),
                'employee_position': position!,
                'employee_department': department.text.trim(),
                if (password.text.isNotEmpty) 'employee_pw': password.text,
              }
            : {
                'store_id': 'ST${DateTime.now().microsecondsSinceEpoch}',
                'agency_name': name.text.trim(),
                'district_name': district!,
                if (phone.text.trim().isNotEmpty) 'phone': phone.text.trim(),
              },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          saving = false;
          error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AlertDialog(
      title: Text(employee ? '직원 추가' : '대리점 추가'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (employee) input(id, '직원 ID', 20),
                input(name, employee ? '직원 이름' : '대리점명', 45),
                if (employee) ...[
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: '직급 *'),
                    items: ['사원', '대리', '과장', '차장', '부장', '팀장', '이사']
                        .map(
                          (role) =>
                              DropdownMenuItem(value: role, child: Text(role)),
                        )
                        .toList(),
                    onChanged: saving ? null : (value) => position = value,
                    validator: (value) => value == null ? '직급을 선택해 주세요.' : null,
                  ),
                  const SizedBox(height: 16),
                  input(department, '부서', 45),
                  input(password, '초기 비밀번호', 45, required: false, secret: true),
                ] else ...[
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '자치구 *'),
                    items: districts.map((item) {
                      final occupied = widget.occupiedDistricts.contains(item);
                      return DropdownMenuItem(
                        value: item,
                        enabled: !occupied,
                        child: Text(
                          occupied ? '$item (등록됨)' : item,
                          style: TextStyle(
                            color: occupied ? Colors.grey : null,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: saving ? null : (value) => district = value,
                    validator: (value) =>
                        value == null ||
                            widget.occupiedDistricts.contains(value)
                        ? '등록되지 않은 자치구를 선택해 주세요.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('등록된 자치구는 선택할 수 없습니다.'),
                  const SizedBox(height: 16),
                  input(phone, '연락처', 12, required: false),
                ],
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed:
              saving ||
                  (!employee &&
                      districts.every(widget.occupiedDistricts.contains))
              ? null
              : save,
          child: Text(saving ? '저장 중...' : '추가'),
        ),
      ],
    ),
  );
}
