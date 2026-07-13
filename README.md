# claude-agent-engineering

Claude Code를 **어떻게 길들여 쓰는가**에 대한 쇼케이스. 실제 프로젝트(한국 회계기준 RAG)를 진행하며 만든 하네스·자율 루틴 산출물을, 각 산출물이 **어떤 설계 판단을 담고 있는지**와 함께 정리했다.

핵심 주장: 에이전트를 잘 쓰는 것은 "좋은 프롬프트를 던지는 것"이 아니라, **행동 계약을 고정하고(harness), 반복·자율 작업을 안전하게 위임하도록 설계하는 것(loop)** 이다.

## harness engineering vs loop engineering

| | harness engineering | loop engineering |
|---|---|---|
| 무엇 | 에이전트의 **행동·컨텍스트·출력**을 계약으로 고정 | 반복·판단 작업을 **자율·스케줄**로 위임 |
| 질문 | "어떻게 일하게 만들 것인가" | "사람 없이 안전하게 돌게 만들 것인가" |
| 이 repo | 전역 CLAUDE.md, 커스텀 스킬 2종 | hankyung 스케줄 루틴, codex 교차검증 루프 |

## 산출물

| 경로 | 무엇을 증명하나 | 핵심 설계 포인트 |
|------|----------------|------------------|
| [`harness/`](harness/) | 전역 행동 계약 설계 | 코딩을 Plan→Execute→Evaluate→Commit 4단계로 계약화, 각 단계를 "막는 실패 모드"로 프레이밍 + 2개 제어 게이트(no plan·commit approval) |
| [`skills/heading-correction/`](skills/heading-correction/) | 정밀 반복작업의 안정화 | 텍스트로 못 푸는 판단을 **PDF 시각 검증 루프**로 확정 + 상태 추적 |
| [`skills/pr-code-review/`](skills/pr-code-review/) | LLM 출력의 결정론화 | 리뷰를 "부탁"이 아니라 **출력 계약(스키마)**으로 강제 |
| [`loop/hankyung/`](loop/hankyung/) | 자율 루틴 설계 | 스케줄·기준 위임·**멱등성**·출력 스키마 |
| [`loop/codex-review/`](loop/codex-review/) | 교차모델 검증 루프 | 자기검증의 맹점을 **독립 모델(Codex) 리뷰**로 보완, 지적을 valid/invalid로 **triage**해 맹목 반영 방지 + 라운드 상한으로 무한루프 차단 |

## 읽는 법

각 폴더의 `README.md`(설계 노트)를 먼저 보면 "왜 이렇게 설계했는지"가 담겨 있고, 같은 폴더의 `SKILL.md` / `CLAUDE.md`가 실제 산출물이다. 폴더별 README → 산출물 순서를 권한다.

## 주의

- 이 repo는 실제 라이브 Claude Code 설정(`~/.claude`)에서 **개인정보를 제거한 showcase 사본**이다. 인증정보·대화 이력·개인 식별자는 포함하지 않는다.
- Notion `data_source_id` 등 개인 인프라 식별자는 `<YOUR_...>` 플레이스홀더로 치환했다.
- 도메인(한국 회계기준, 프로젝트 경로)은 작업 난이도의 맥락으로 일부 유지했다.
