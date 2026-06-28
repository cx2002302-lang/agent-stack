# Changelog

## [0.1.3] - 2026-06-28

### Fixed

- **Restored systemPromptOverride design** — ZK Brain's PROMPT.md is the primary agent instructions for 2026.4.x (systemPromptOverride). Appended b2s/upsp/svm tool usage to both PROMPT.md and SKILL.md for consistent cross-version behavior.

## [0.1.2] - 2026-06-28

### Fixed

- **ZK Brain systemPromptOverride bug** — Replaced `systemPromptOverride` pattern (which hid all other skills) with native SKILL.md injection. SKILL.md now contains PROMPT.md content (agent behavior instructions); INSTALL.md and setup-skill-prompt.sh updated to not use systemPromptOverride on OpenClaw >= 2026.6.x

## [0.1.1] - 2026-06-28

### Added
- `scripts/quick-install.sh` — curl|bash one-command install for AI Agent
- Zettelkasten standalone `packages/zettelkasten/scripts/quick-install.sh`
- Architecture docs: Schema compatibility table, data safety guarantees
- `docs/assets/agent-stack-hero.png` — architecture infographic (1280×714, 894KB)

### Changed
- Updated open-upsp subpackage to v0.3.5 (safety default 60→63, SKILL.md CLI instructions)
- Updated agent-stack README with one-command install examples for all 3 components

## [0.1.0] - 2026-06-28

### Added
- Initial release: Agent Stack monorepo integrating three AI Agent infrastructure projects
- **Zettelkasten** (v1.0.0-beta.8.1): Knowledge base plugin with atomic notes, semantic links, FTS5 search, CEQRC distillation, 34+ MCP tools
- **Memory Plus / SVM** (v0.2.0): Structured memory management with LRU cache, SQLite persistence, Aho-Corasick keyword recall, bidirectional ZK sync
- **open-upsp** (v0.3.4): Universal Persona Substrate Protocol with 7-file identity system, session distillation, state evolution
- One-click install script for all three components
- Architecture documentation with data flow diagrams
- Bilingual README (Chinese default + English switch)
