#!/usr/bin/env bash
# 스테이징 트리에서 금지 토큰을 검사한다. 0건이어야 통과.
set -e
ROOT="C:/Great_Journey/claude-agent-engineering"
PATTERN='bagja|kkk273|2ad9625c-9a67-8108-bb63-000be1b2e742|BEGIN [A-Z]*PRIVATE KEY'
if grep -rniE "$PATTERN" "$ROOT" --include='*.md'; then
  echo "FAIL: 금지 토큰 발견"; exit 1
else
  echo "PASS: 금지 토큰 0건"; fi
