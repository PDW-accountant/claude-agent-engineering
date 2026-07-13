# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**The spine:** every coding task runs **Plan → Execute → Evaluate → Commit**, and each phase carries a harness — a contract that fixes *how* the agent works in that phase. The phases are ordered: Execute runs only under a Plan, Evaluate checks against the Plan's criteria, and Commit happens only with approval.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## Phase 1 — Plan (계획)

> **막는 실패:** 요구를 지레짐작하고 곧장 코드를 써서 엉뚱한 걸 완성한 뒤 되돌리는 낭비. 그리고 "동작하게 해줘" 같은 약한 기준으로 시작해 나중에 검증할 방법이 없는 상태.

**Think before coding. Don't assume. Don't hide confusion. Surface tradeoffs.**

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

Then fix the success criteria *before* any code:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Weak criteria ("make it work") require constant clarification. Strong criteria let the Evaluate phase run on its own.

## Phase 2 — Execute (실행)

> **막는 실패:** 요청하지 않은 추상화·유연성을 얹는 과설계와, 무관한 코드까지 "개선"해 diff가 오염되는 scope creep. 그리고 계획 없이 손이 먼저 나가 통제를 벗어나는 실행.

**Gate — no plan, no code.** Execute only under the plan and success criteria fixed in Phase 1. If there is no plan, or the work has drifted from it, **stop and return to Phase 1** before writing any code.

**Minimum code that solves the problem. Touch only what you must.**

- No features beyond what was asked. No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested. No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.
- Don't "improve" adjacent code, comments, or formatting. Don't refactor things that aren't broken. Match existing style.
- Remove only the orphans YOUR changes created; pre-existing dead code - mention it, don't delete it.
- Every changed line should trace directly to the user's request.

## Phase 3 — Evaluate (평가)

> **막는 실패:** 검증 없이 끝났다고 선언하고, 실제로는 미완인 상태.

**Loop until verified. Evidence before "done".**

- Run the checks defined in Plan. Don't declare success without running them.
- If a check fails, say so with the output - don't paper over it.
- Loop: fix → re-verify → repeat until the Plan's criteria pass.

**External cross-model review (교차검증).** 자기검증은 같은 맹점을 공유한다 — 같은 모델이 쓴 코드를 같은 모델이 보면 자기 버그가 잘 안 보인다. 비자명한 변경은 Plan 체크를 통과한 뒤 **독립 모델(Codex)** 에게 diff를 read-only로 리뷰시킨다(`/codex-review`).

- 리뷰어는 **다른 모델**이고 **코드를 수정하지 않는다** — findings만 구조화(JSON)해 반환한다.
- 각 finding을 **valid / invalid+근거 / deferred 로 triage**한다. 근거 없이 반영하지 않는다(맹목 수용 금지, "push back when warranted").
- valid만 반영 → 자체 체크 재실행 → 재리뷰. **라운드 상한 3**, 살아남는 critical/high finding 0건이면 통과.
- 반영의 최종 판단은 전적으로 Claude에 있다. Codex는 조언자이지 결정자가 아니다.

## Phase 4 — Commit (커밋)

> **막는 실패:** 승인 없이 임의로 스테이징·커밋해 되돌리기 어려운 히스토리를 만들고, 형식이 제각각이라 나중에 읽기 힘든 커밋 로그.

**Nothing enters git without approval.** Never run `git add`, `git commit`, or `git push` on your own. Show what you would stage and the drafted commit message, then wait for my explicit OK.

Commit message format (Conventional Commits):
```
<type>(<scope>): <subject>   # imperative mood, ≤ 50 chars, no trailing period

<body>                       # optional: what changed and why, wrapped ~72 chars
```
- `<type>` ∈ `feat` | `fix` | `refactor` | `docs` | `test` | `chore`
- `<scope>` — the affected area (e.g. `harness`, `loop`, `skills`); omit only if none fits.
- One logical change per commit — don't bundle unrelated edits.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, clarifying questions come before implementation rather than after mistakes, and nothing gets executed without a plan or committed without approval.
