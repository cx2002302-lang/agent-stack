# Agent Stack 架构详解

## 整体架构

Agent Stack 采用三层架构，将 AI Agent 的认知能力拆分为三个独立但协作的子系统：

```
┌──────────────────────────────────────────────────────┐
│                     AI Agent                         │
│               OpenClaw / Hermes                      │
└──────┬───────────────────┬─────────────────┬─────────┘
       │ MCP Tools         │ svm exec / CLI  │ MCP Tools
       ▼                   ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────────┐
│  open-upsp   │  │ memory-plus  │  │   Zettelkasten   │
│  人格层       │  │  记忆层       │  │   知识层          │
│              │  │              │  │                  │
│ 7 文件身份    │  │ SVM 内存缓存  │  │ 原子笔记 + FTS5   │
│ 会话蒸馏      │  │ LRU 淘汰     │  │ 11 种语义链接     │
│ 6 轴状态演化  │  │ Aho-Corasick │  │ CEQRC 知识蒸馏   │
│ SQLite 桥接   │  │ 双向 ZK 同步  │  │ Glow 热度排序    │
└──────┬───────┘  └──────┬───────┘  └────────┬─────────┘
       │                 │                   │
       └────────┬────────┘                   │
                │                            │
                ▼                            ▼
        ┌──────────────────────────────────────────┐
        │          Zettelkasten Database           │
        │  SQLite + Markdown + FTS5 + WAL          │
        │  ~/.openclaw/zettelkasten/               │
        └──────────────────────────────────────────┘
```

## 数据流

### 1. 知识入库 (Zettelkasten → 所有)
- AI Agent 通过 MCP 工具 `zk_create_note` 创建原子笔记
- 笔记自动建立语义链接（supports / refines / extends / contradicts 等 11 种）
- CEQRC 管道自动将碎片信息精炼为永久知识
- Glow Ranking 通过 PageRank + 引用数 + 新鲜度衰减计算知识重要性

### 2. 记忆同步 (memory-plus ↔ Zettelkasten)
- **SVM → ZK**: 冷数据备份。MemoryStore 中 hot_score < 0.3 的内存块自动同步到 ZK 创建新笔记
- **ZK → SVM**: 热加载。ZK 中的重要笔记（svm:hot 标签 / confidence ≥ 0.9 / zettels 文件夹）和近期笔记（7天内）加载到 SVM 内存缓存
- **淘汰保护**: LRU 淘汰前先同步到 ZK，防止数据丢失
- **准入控制**: 当内存使用率 ≥ 80% 时，低权重（< 0.1）块被拒绝写入

### 3. 人格上下文 (open-upsp → Zettelkasten)
- open-upsp 通过 SQLite 桥接器只读访问 ZK 数据库
- 构建 Agent 上下文时，同时加载人格文件和 ZK 知识
- 会话结束后，distill 引擎将对话内容蒸馏为 STM 条目
- 达到阈值（10 轮对话 + 0.3 workhood）后自动同步到 ZK

## 存储位置

所有数据存储在 `~/.openclaw/` 目录下：

```
~/.openclaw/
├── zettelkasten/
│   ├── zettelkasten.db    # ZK 主数据库 (SQLite + FTS5)
│   └── notes/             # Markdown 笔记原文
├── svm/
│   └── memory.db          # SVM 持久化存储 (SQLite, WAL)
├── openupsp/
│   └── config.json        # open-upsp 配置
└── openupsp-persona/      # 人格文件 (7 个 Markdown 文件)
    ├── core.md
    ├── state.md
    ├── STM.md
    ├── LTM.md
    ├── relation.md
    ├── rules.md
    └── docs.md
```

## 通信方式

| 组件 | 与 Agent 通信 | 组件间通信 |
|------|---------------|-----------|
| Zettelkasten | MCP 协议 (stdio/HTTP) | SQLite 数据库共享 |
| memory-plus | CLI (svm exec) + MCP Server (stdio) | 通过 ZK 数据库双向同步 |
| open-upsp | CLI (upsp exec) + SQLite Bridge | SQLite 只读访问 ZK 数据库 |

---

# Agent Stack Architecture (English)

## Overview

Agent Stack uses a three-layer architecture that splits AI Agent cognitive capabilities into three independent but cooperative subsystems:

### Data Flow

1. **Knowledge Ingestion** (Zettelkasten → All): AI Agent creates atomic notes via MCP tools, CEQRC pipeline refines fragmented information, Glow Ranking scores importance
2. **Memory Sync** (memory-plus ↔ Zettelkasten): Cold SVM data backs up to ZK, hot ZK notes load into SVM cache, eviction-sync protection prevents data loss
3. **Persona Context** (open-upsp → Zettelkasten): Read-only SQLite bridge to ZK DB, session distillation into STM, threshold-based sync to ZK

### Storage

All data under `~/.openclaw/`: ZK database + Markdown notes, SVM SQLite persistence, open-upsp config and 7-file persona.

### Communication

- Zettelkasten: MCP (stdio/HTTP)
- memory-plus: CLI exec + MCP Server (stdio), bidirectional sync via ZK DB
- open-upsp: CLI exec + SQLite Bridge, read-only ZK DB access
