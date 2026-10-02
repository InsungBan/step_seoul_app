class HqRecord {
  HqRecord(
    this.id,
    this.name,
    this.partner,
    this.quantity,
    this.amount,
    this.status, {
    this.ratio = 72,
  });
  final String id;
  String name, partner, status;
  int quantity, amount, ratio;
}

abstract final class HqDemoData {
  static List<HqRecord> products() => [
    HqRecord('SH-AR01', '에어 러너 01', '나이키', 24, 139000, '부족', ratio: 24),
    HqRecord('SH-CL02', '클래식 로퍼', '닥터마틴', 28, 119000, '주의', ratio: 35),
    HqRecord('SH-KD03', '키즈 워커', '휠라', 15, 89000, '부족', ratio: 21),
    HqRecord('SH-SN04', '스니커즈 Pro', '아디다스', 86, 129000, '정상'),
    HqRecord('SH-BT05', '하이탑 부츠', '팀버랜드', 18, 149000, '부족', ratio: 30),
    HqRecord('SH-RN06', '트레일 이지', '뉴발란스', 64, 159000, '정상', ratio: 80),
    HqRecord('SH-SD07', '컴포트 샌들', '크록스', 55, 69000, '정상', ratio: 92),
    HqRecord('SH-SP08', '스피드 러너', '아식스', 18, 179000, '부족', ratio: 23),
    HqRecord('SH-CV09', '척 70 하이', '컨버스', 42, 99000, '주의', ratio: 52),
  ];
  static List<HqRecord> orders() => List.generate(
    18,
    (i) => HqRecord(
      'ORD-202610-${(142 - i).toString().padLeft(4, '0')}',
      ['에어 러너 01', '클래식 로퍼', '키즈 워커', '스니커즈 Pro'][i % 4],
      ['서울 강남점', '부산 해운대점', '대구 수성점', '인천 송도점'][i % 4],
      i % 3 + 1,
      [278000, 119000, 267000, 129000][i % 4],
      ['배송중', '대리점 도착', '수령완료', '반품요청'][i % 4],
    ),
  );
  static List<HqRecord> proposals() => List.generate(
    9,
    (i) => HqRecord(
      'PR-202610-${(24 - i).toString().padLeft(3, '0')}',
      ['러닝화 재고 확보 요청', '스니커즈 추가 발주 건', '부츠 재고 확보 요청', '로퍼 재고 확보 요청'][i % 4],
      ['김사원 · 구매팀', '이사원 · 구매팀', '박사원 · 구매팀'][i % 3],
      120,
      [5800000, 7200000, 9450000, 6780000][i % 4],
      ['결재대기', '결재대기', '승인완료', '반려'][i % 4],
      ratio: 24 + i,
    ),
  );
  static List<HqRecord> purchasing() => List.generate(
    12,
    (i) => HqRecord(
      'PO-202610-${(28 - i).toString().padLeft(3, '0')}',
      ['에어포스 1 로우 화이트', '삼바 OG 블랙', '574 그레이', '스웨이드 클래식'][i % 4],
      ['나이키 코리아', '아디다스 코리아', '뉴발란스 코리아', '푸마 코리아'][i % 4],
      300 - i * 10,
      39000000 - i * 1800000,
      ['수주확인', '수주확인', '수주대기', '입고완료'][i % 4],
    ),
  );
  static List<HqRecord> stores() => List.generate(
    12,
    (i) => HqRecord(
      'DR-2025${(i + 1).toString().padLeft(3, '0')}',
      ['강남점', '서초점', '송파점', '마포점', '종로점', '영등포점', '용산점', '성동점'][i % 8],
      '서울시 ${['강남구', '서초구', '송파구', '마포구', '종로구', '영등포구', '용산구', '성동구'][i % 8]}',
      10 + i,
      0,
      i == 5 ? '휴업중' : '영업중',
    ),
  );
}

String hqNumber(num value) => value
    .toStringAsFixed(0)
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
