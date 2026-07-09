---
name: pr-code-review
description: Use when asked to review a specific Python module from a GitHub Pull Request, generating a structured Korean-language analysis report with every function in source order, input/output types, and business-logic-level step-by-step explanations.
---

# PR Code Review

## Overview

GitHub PR에서 지정한 Python 모듈의 전체 소스 코드를 가져와, 모든 함수·메서드를 소스 순서대로 빠짐없이 분석한 한국어 리포트를 생성한다. **diff가 아닌 full source**를 기반으로 한다.

## Prerequisites

```powershell
gh --version          # gh CLI 설치 확인 (미설치 시: winget install GitHub.cli)
gh auth login         # 인증
gh auth status        # 확인
```

## Process

### Step 1: 레포지토리 및 PR 정보 확인

```powershell
gh repo view --json nameWithOwner --jq '.nameWithOwner'
gh pr view <PR_NUMBER> --json headRefName,files --jq '{branch: .headRefName, files: [.files[].path]}'
```

### Step 2: 대상 모듈의 전체 소스 코드 가져오기

**반드시 diff가 아닌 파일 전체 소스를 사용한다.**

```powershell
# 방법 A: gh API (체크아웃 없이)
$content = gh api repos/<OWNER>/<REPO>/contents/<FILE_PATH>?ref=<BRANCH> --jq '.content'
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($content.Replace("`n","")))

# 방법 B: PR 브랜치 체크아웃 후 Read 툴 사용 (권장)
gh pr checkout <PR_NUMBER>
```

### Step 3: 분석 대상 모듈 결정

- 사용자가 파일을 명시했으면 → 해당 파일 사용
- 명시하지 않았으면 → PR 변경 `.py` 파일 목록을 보여주고 선택 요청

### Step 4: 리포트 생성

아래 Output Format을 파일 끝까지 엄격히 반복한다. **함수 하나도 건너뛰지 않는다.**

## Output Format

```markdown
### 📄 [모듈명 또는 파일명] 분석 리포트

---

#### [N]. `함수명` (클래스 내부인 경우 `클래스명.메서드명`)
* **Input:**
  - `인자명`: 타입 (설명)
* **Output:**
  - 타입 (설명)
* **상세 수행 과정:**

```python
[설명 대상 코드 블록을 여기에 인용한다]
```
[이 코드가 무엇을 하는지 한글로 설명한다]

---

```python
[다음 코드 블록]
```
[설명. 핵심 표현식(SQL, 수식, 조건 분기 등)은 줄 단위로 분해해서 각각 설명한다]

- `표현식A` — 이 표현식이 하는 일
- `표현식B` — 이 표현식이 하는 일

복잡한 파라미터 순서나 여러 값이 얽히는 구조는 표로 시각화한다:

| 위치 | 채워지는 값 | 이유 |
|------|------------|------|
| 첫 번째 `%s` | `변수명` | 설명 |
| 두 번째 `%s` | `변수명` | 설명 |

---

> **[의견]** — `파일경로:L시작줄–L끝줄` (예: `src/workflow.py:L42–L55`)
> 오류·중복·불필요한 코드가 있을 때만 이 블록을 추가한다. 없으면 생략.
> 중요도 순으로 작성하며, 각 항목 앞에 중요도 태그를 붙인다.
> - **[상]** 치명적 문제 (런타임 오류, 데이터 오염, 무한 루프 등)
> - **[중]** 직접적 오류는 아니나 복잡도·가독성·유지보수성을 해치는 문제 (중복 로직, 설계 결함 등)
> - **[하]** 기능에 영향 없는 사소한 문제 (오탈자, 주석 문구, 변수명 등)

---

### 🔍 모듈 전체 의견

수정이 필요한 사항만 항목별로 정리한다. 문제가 없으면 이 섹션을 생략한다.
**[상] → [중] → [하]** 순서로 작성한다.

- **[상] [함수명 또는 영역]** (`파일경로:L줄번호`): [수정이 필요한 이유와 권장 방향]
- **[중] [함수명 또는 영역]** (`파일경로:L줄번호`): [수정이 필요한 이유와 권장 방향]
- **[하] [함수명 또는 영역]** (`파일경로:L줄번호`): [수정이 필요한 이유와 권장 방향]
```

- 기본 출력: `.md` 파일, 저장 위치는 프로젝트 루트의 `reviews/` 디렉토리
  - 파일명 규칙: `pr{번호}_{모듈명}_review.md` (예: `pr23_test_workflow_review.md`)
- 사용자가 명시적으로 요청한 경우에만 `.html`로 저장

## Strict Rules

1. **생략·축약 금지** — 모든 함수와 메서드를 원본 형식 그대로, 하나도 빠짐없이.
2. **소스 순서 엄수** — 파일 위에서 아래로, 리뷰어가 실제 코드와 1:1 대응 가능하게.
3. **Input/Output 타입 명시** — 타입 힌트 없으면 추론 후 명시(`Any` 또는 추론 타입).
4. **코드 단위 설명** — 단계마다 대상 코드 스니펫을 인용하고, 핵심 표현식(SQL·수식·복잡한 조건)은 줄 단위로 분해. 파라미터 바인딩처럼 여러 값이 얽히는 구조는 표로 시각화. "왜 이렇게 작성됐는지" 설계 의도까지 포함.
5. **Full source 사용** — diff 기반 분석 절대 금지.
6. **함수별 의견 조건부** — 오류·중복·불필요가 있을 때만 `[의견]` 블록 추가, 없으면 생략.
7. **모듈 전체 의견** — 모든 함수 분석 후 수정 필요 항목만 `🔍 모듈 전체 의견`으로 정리, 없으면 섹션 생략.
8. **비판적 시각** — 문제를 명확히 지적. 칭찬·완곡 표현 없이 짧고 직접적으로.
9. **위치 정보 필수** — `[의견]`·`🔍 모듈 전체 의견` 모든 항목에 `파일경로:L시작–L끝` 기재.
10. **중요도 태그·정렬** — 각 의견에 `[상]`/`[중]`/`[하]` 태그를 붙이고 `[상] → [중] → [하]` 순서로.

## Common Mistakes

| 실수 | 올바른 방법 |
|------|------------|
| PR diff만 분석 | `gh api` 또는 체크아웃으로 전체 파일 내용 가져오기 |
| "비슷한 함수들" 그룹화 | 각 함수마다 독립 섹션 |
| Input/Output 생략 | 어렵더라도 타입 추론해서 명시 |
| 클래스 메서드 순서 변경 | 클래스 내부도 소스 순서 그대로 |
| 요약으로 대체 | 상세 수행 과정은 항상 단계별로 |
| 설명만 쓰고 코드 미인용 | 각 단계마다 대상 코드 스니펫 인용 |
| 복잡한 표현식을 뭉뚱그림 | SQL·수식·조건은 줄 단위로 분해 |
| 파라미터 순서를 문장으로 나열 | 여러 값이 얽히면 표로 시각화 |
| 문제 없어도 `[의견]` 추가 | 오류·중복·불필요 없으면 블록 생략 |
| 위치 정보·중요도 태그 생략 | `파일경로:L줄`과 `[상]/[중]/[하]`를 항상 기재·정렬 |
