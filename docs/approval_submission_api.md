# 품의 제출 API

`POST /approval/submit` (JSON)

```json
{
  "approval_name": "재고 보충 품의",
  "approval_content": "신청 사유 및 선택 상품",
  "employee_employee_id": "실제 직원 ID",
  "requested_amount": "120000.50"
}
```

서버는 품의번호와 결재기록 ID, 한국 시간 작성일을 생성한다.
품의와 결재 기록은 한 트랜잭션으로 저장하며, 담당 직원이 없거나
저장 중 오류가 발생하면 전체를 취소한다. 신청금액은 0 이상이고 소수점 두 자리까지 허용한다.

- 작성일: `approval_process.approval_date`
- 신청금액: `approval.requested_amount`
- 결재 담당 직원: `approval_process.employee_employee_id`
- 초기 단계: `team_leader_approval=대기`, `director_approval=대기`
- 초기 결재 상태: `approval_process.approval_status=결재대기`

화면은 초기 단계를 두 승인 상태로 표시한다. 별도 현재 단계 컬럼은 필요하지 않다.
여기서 상태는 결재 상태이며 상품 대금의 결제 상태와는 별개다.
기존 `/approval/upload`는 단순 품의 CRUD용으로 유지한다.

새 DB에 적용할 때 `python -m db.migrate_approval_amount`를 먼저 실행한다.
기존 품의의 누락 정보는 임의로 채우지 않는다.

## 직급별 승인

`POST /approval_process/approve/{approval_id}`

```json
{"employee_id": "현재 로그인한 직원 ID"}
```

API는 직원 테이블의 `employee_position`을 조회한다. `팀장`은 팀장 승인과
`결재중`을 저장하고, `이사`는 팀장 승인 완료 후 이사 승인과 `승인완료`를 저장한다.
클라이언트가 승인 직급을 지정하지 않는다. 승인 대상 기록을 잠그고 중복 승인,
결재 순서 위반, 완료·반려된 건, 모호한 최신 기록은 거절한다.

로그인 연동 화면은 `HqConsole(currentEmployeeId: loggedInEmployeeId)`로 직원 ID를 전달한다.
직원 ID가 없으면 승인 버튼은 비활성화된다.
현재 API의 직원 ID는 로그인 연동용 입력이다. 로그인 도입 시 서버에서도 인증된 세션에서
직원 ID를 얻도록 교체해야 한다. 이 입력 자체가 로그인 인증을 제공하지는 않는다.
