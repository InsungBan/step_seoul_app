# 테이블별 CRUD 사용법

프로젝트 루트에서 `python main.py`를 실행하고
`http://192.168.10.39:8000/docs`를 연다.

모든 테이블은 동일한 API 패턴을 사용한다.

| 작업 | 메서드 | 주소 |
| --- | --- | --- |
| 생성 | POST | `/{테이블}/upload` |
| 전체 조회 | GET | `/{테이블}/select` |
| 수정 | PUT | `/{테이블}/update/{기본키}` |
| 삭제 | DELETE | `/{테이블}/delete/{기본키}` |

생성·수정 데이터는 Form으로 전송한다. 생성 시 기본키는 필수이고,
NULL을 허용하는 컬럼은 선택 사항이다. 수정은 입력한 일반 컬럼만 변경한다.
기본키 자체의 변경과 컬럼 값을 NULL로 초기화하는 기능은 제공하지 않는다.
기존 사용자 API의 `join_date`는 생성 시 query parameter이며,
생략하면 서버의 현재 시각으로 저장한다.

복합 기본키 테이블은 기본키를 모두 주소에 넣는다. 예를 들어 cart는
`/cart/update/{user_user_id}/{shoe_shoe_id}/{cart_id}` 형식이다.
실제 기본키 이름과 순서는 Swagger에서 확인한다. recall은 `recall_id`가
기본키가 아니므로 매장·사용자·직원 키로 행을 식별한다.

외래키 값은 참조 테이블에 먼저 존재해야 한다. 부모 행 삭제 시에도
외래키 제약이 적용된다. 생성·수정·삭제 성공 응답은 각각
`{"result": "CREATE OK"}`, `{"result": "UPDATE OK"}`,
`{"result": "DELETE OK"}`이며 조회는 `{"result": [...]}`이다.

없는 행은 404, 중복 키·외래키 위반은 409, 잘못된 입력은 422를 반환한다.
DB 처리 실패는 500을 반환하며 상세 원인은 FastAPI 터미널에 기록된다.

`routers/{테이블}.py`는 HTTP 입력을 받고,
`services/{테이블}_service.py`는 SQL과 처리 로직을 담당한다.
`services/_database.py`는 연결 종료, 트랜잭션, 오류 처리를 공통으로 담당한다.
`main.py`는 19개 라우터를 등록한다.

`db/schema.json`은 구현 당시 읽은 DB 구조이며 실행 중 DB 설정으로 사용하지 않는다.
DB 컬럼이나 기본키를 바꾸면 해당 라우터·서비스와 이 구조 기록을 함께 갱신한다.

검증: `python -m unittest discover -s tests -v`
테스트는 DB 연결을 대체하여 76개 API와 SQL 매개변수, 입력 검증,
오류 처리 및 트랜잭션을 확인한다. 실제 DB 데이터를 변경하지 않는다.
