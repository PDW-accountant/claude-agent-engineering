---
description: Codex(독립 모델)로 현재 diff를 교차 리뷰하고, valid한 지적만 triage해 반영하는 Evaluate 서브루프
argument-hint: "[git diff range] (생략 시 작업트리 미스테이징 변경)"
allowed-tools: Bash(git diff:*), Bash(codex exec:*), Read, Edit, Write
---

## /codex-review — 교차모델 검증 루프

Claude가 작성한 코드를 **다른 모델(Codex)** 에게 독립 리뷰시켜 자기검증의 맹점을 보완한다. 아래 절차를 순서대로 수행한다.

### 절차

**1. 스냅샷**
- `DIFF = git diff $ARGUMENTS` (인자 없으면 미스테이징 작업트리 변경, 스테이징만 볼 땐 `--cached`).
- diff가 비어 있으면 "리뷰할 변경 없음"으로 중단.
- `CONTEXT` = 이번 작업의 한 줄 목표 + Plan의 성공기준.

**2. Codex 호출 (read-only)**
- 아래 리뷰 계약 프롬프트의 `<CONTEXT>` / `<DIFF>`를 채워 실행: `codex exec --sandbox read-only "<프롬프트>"`
- read-only 이유: 리뷰어는 코드를 못 고친다. 수정은 Claude만 — triage 게이트를 물리적으로 강제한다.

리뷰 계약 프롬프트:

```
You are an INDEPENDENT, adversarial code reviewer. A different AI wrote the change below.
Assume it contains at least one real defect, but maintain a strict burden of proof:
do not report a defect unless you can provide a concrete, logical proof of failure.

TASK: <CONTEXT>
DIFF UNDER REVIEW:
<DIFF>

INSTRUCTIONS:
1. Review ONLY the lines introduced or modified in this diff.
2. Report correctness defects only: logic errors, edge cases, wrong API usage,
   broken invariants, race conditions, or security vulnerabilities.
3. Consider side-effects: assess if the changes in this diff break existing
   invariants or callers outside the diff.
4. Do NOT suggest style, refactoring, documentation, or personal preference changes.
5. Do NOT output any conversational text, intro, or outro. Output strictly valid JSON.

OUTPUT FORMAT:
Return a valid JSON array of objects. If there are no verifiable defects, return exactly [].
Each object has fields: id, severity, location, claim, why, suggestion.
- id: F1, F2, F3... incrementing per finding.
- severity: one of critical | high | medium | low.
- location: filename.ext:line_number, using the line number in the NEW/MODIFIED
  file, not the diff hunk line.
- claim: one-sentence summary of the defect.
- why: concrete failing input or execution sequence -> exact wrong result or crash.
- suggestion: exact replacement code snippet, or empty string if a fix is unclear.

Example element:
{"id":"F1","severity":"high","location":"parser.py:42","claim":"...","why":"...","suggestion":"..."}

CRITICAL: Do not wrap the JSON in markdown code blocks. Output raw JSON text only.
```

**3. 파싱**
- codex stdout에서 JSON 배열 추출: 응답의 첫 `[`부터 마지막 `]`까지 슬라이스 후 파싱.
- 실패 시 codex를 1회 재호출("Output raw JSON array only. No comments, no markdown fences.").
- 그래도 실패하면 이 라운드를 **"리뷰 파싱 실패"** 로 사용자에게 보고하고 중단 — 조용히 통과시키지 않는다.
- 파싱 결과를 `scratchpad/codex-review.json` 에 저장.

**4. Triage**
- finding마다 판정하고 표로 기록:

  | id | severity | verdict | 근거 | 조치 |
  |----|----------|---------|------|------|

- verdict ∈ `valid` / `invalid` / `deferred`(범위 밖). **근거 없이 반영 금지** — invalid면 왜 틀린 지적인지 한 줄로 남긴다.

**5. 반영 & 재검증**
- `valid`만 코드 수정 → Plan의 자체 체크(테스트/빌드) 재실행. 깨지면 통과할 때까지 고친다.

**6. 재리뷰 루프**
- `valid` 수정이 하나라도 있었으면 2번으로 되돌린다(라운드 +1).
- 종료조건(하나라도 충족): 살아남는 critical/high finding 0건 · 라운드 == 3 · 남은 finding 전부 invalid.
- 진동 방지: invalid로 근거 기록된 finding이 재등장하면 재심하지 않고 기존 근거를 유지한다.

**7. 보고**
- 라운드별 finding 수, 반영 목록, 반려 목록(근거 포함)을 요약 출력한다.

### 계약

- 모든 코드 변경은 **valid finding**으로 추적된다 — 리뷰 빌미 없는 즉흥 수정 금지.
- Codex는 조언자다. 반영 여부의 최종 판단과 책임은 Claude가 근거와 함께 진다.
