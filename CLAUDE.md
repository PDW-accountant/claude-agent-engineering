# CLAUDE.md — claude-agent-engineering (project)

이 repo에서 코드를 생성·수정할 때의 프로젝트 계약. 전역 CLAUDE.md와 병합된다.

## Evaluate 단계: codex 교차검증 필수

비자명한 코드 변경(로직 추가·수정, 버그 픽스, 리팩터)을 마치면, "완료" 선언 전에 **`/codex-review`** 를 실행한다.

- **트리거**: 코드 변경이 diff에 있고 사소하지 않을 때. 문서·주석·오탈자 등 trivial 변경은 건너뛴다(전역 CLAUDE.md의 escape hatch와 동일).
- **절차**: `/codex-review` 커맨드를 따른다 — codex read-only 리뷰 → findings를 `valid/invalid+근거`로 triage → valid만 반영 → 재검증. 라운드 상한 3.
- **판단 주체**: 반영의 최종 판단은 Claude에 있다. Codex는 조언자다. 근거 없이 반영하지 않고, 반려 시 근거를 남긴다.
- **선행조건**: `codex` CLI 로그인이 안 돼 있으면 리뷰가 실패한다. 그 경우 조용히 통과시키지 말고 사용자에게 로그인이 필요함을 알린다(`codex login`).
