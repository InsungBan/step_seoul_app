# Firebase 이미지 URL을 MySQL에 동기화

Firebase Firestore의 `shoe/{문서 ID}`에서 문자열 `shoeImage`를 읽고,
MySQL `shoe.shoe_id`에서 상품 부분을 추출해 일치하는 문서의 값을 `shoe_img_url`에 저장합니다.
기존 화면 및 API와 호환되도록 `shoe_image_url`에도 같은 값을 저장합니다.
이미지 파일이나 Firebase 문서는 변경하지 않습니다.

예를 들어 `airforce_black_m_280_00`은 뒤의 `_m_280_00`을 제외하고,
Firebase `shoe/airforce_black`의 `shoeImage`를 읽습니다. MySQL 조회와 갱신에는
전체 ID인 `airforce_black_m_280_00`을 사용합니다.

뒤의 세 부분이 성별(`m`, `f`, `u`, 대소문자 허용), 숫자 사이즈, 숫자 번호일 때만
제외합니다. 상품 부분에 밑줄이 여러 개 있어도 보존하며, 이 형식이 아닌 ID는
전체 ID를 그대로 비교합니다. 같은 상품의 다른 사이즈도 같은 이미지 문서를 사용합니다.

## 요청한 테스트 데이터 생성

```powershell
python scripts/sync_shoe_images.py --create-test-shoe --dry-run
python scripts/sync_shoe_images.py --create-test-shoe
```

`airforce_black_m_280_00` 행이 없을 때만 생성합니다. Firebase `shoe/airforce_black`에
비어 있지 않은 문자열 `shoeImage`가 있어야 생성되며, 다른 상품 정보는 NULL입니다.
이미 행이 있으면 이미지 필드만 동기화합니다.

실제 실행은 필요한 이미지·상품명 컬럼을 추가하고 `shoe_id` 및 해당 외래키 컬럼의
길이를 `VARCHAR(45)`로 확장합니다. `--dry-run`은 스키마와 데이터를 변경하지 않습니다.

현재 테스트 상품의 MySQL ID는 `airforce_black_m_280_00`입니다.
현재 상품명(`shoe_name`)은 `에어포스 블랙`, 카테고리는 `러닝`입니다.

## 이후 동기화

```powershell
# 특정 상품
python scripts/sync_shoe_images.py --shoe-id airforce_black_m_280_00

# MySQL의 모든 상품에 대해 일치하는 Firebase 문서 확인
python scripts/sync_shoe_images.py
```

Firebase 문서가 없거나 `shoeImage`가 문자열이 아니거나 비어 있으면 기존 값을
유지하고 `skipped`에 표시합니다. 두 이미지 컬럼이 이미 같은 값이면 `unchanged`로
표시합니다. 연결 또는 DB 오류가 발생하면 해당 실행의 행 변경을 롤백합니다.
스키마 변경은 MySQL DDL 특성상 행 변경과 별도로 반영됩니다.

이 작업은 명령을 실행할 때 동기화합니다. Firebase 변경을 실시간으로 구독하지 않습니다.

## 연결 설정과 확인

MySQL은 기존 `db/database.py` 설정을 사용합니다. Firebase 프로젝트 기본값은
앱과 같은 `stepseoulapp`이며, `--project-id` 또는 `FIREBASE_PROJECT_ID`로 바꿀 수 있습니다.
Firestore의 [공식 REST API](https://firebase.google.com/docs/firestore/use-rest-api)를 사용하며
현재 보안 규칙에 따라 읽습니다. 인증이 필요한 경우 권한이 있는 Firebase ID 토큰
또는 Google OAuth 액세스 토큰을 `FIREBASE_AUTH_TOKEN` 환경변수로 전달합니다.

```sql
SELECT shoe_id, shoe_img_url, shoe_image_url
FROM shoe
WHERE shoe_id = 'airforce_black_m_280_00';
```
