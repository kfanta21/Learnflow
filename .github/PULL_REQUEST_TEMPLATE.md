## What does this PR do?
<!-- 1-2 sentences. What is the user-facing or system-level change? -->

## Why?
<!-- Link to issue: Closes #XX — or explain the motivation if no issue -->

## How to test?
<!-- Step by step. What endpoint, what payload, what should happen -->

## Checklist
- [ ] Tests added or updated
- [ ] Flyway migration included (if schema changed)
- [ ] No hardcoded credentials or secrets anywhere
- [ ] `ddl-auto` is still `validate` (not `create` or `update`)
- [ ] Cache eviction handled (if cached data changed) — Phase 5+
- [ ] Kafka event published (if state-changing operation) — Phase 7+
- [ ] README updated (if local setup changed)
- [ ] ADR written (if this was a major architectural decision)