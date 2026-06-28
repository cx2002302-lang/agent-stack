<p align="center">
  <img src="docs/assets/agent-stack-hero.png" alt="Agent Stack" width="100%">
</p>

<h1 align="center">🛠️ Agent Stack</h1>

<p align="center">
  <strong>OpenClaw AI Agent 全家桶</strong><br>
  人格 · 记忆 · 知识 — 三位一体的 AI Agent 基础设施
</p>

<p align="center">
  <a href="README.en.md">🇺🇸 English</a> ·
  <strong>简体中文</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-v0.1.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">
  <img src="https://img.shields.io/badge/OpenClaw-%3E%3D2026.4.23-lightgrey.svg" alt="OpenClaw">
  <img src="https://img.shields.io/badge/Python-%3E%3D3.10-blue.svg" alt="Python">
  <img src="https://img.shields.io/badge/Node.js-%3E%3D22.0.0-brightgreen.svg" alt="Node.js">
</p>

---

## 📦 组件

Agent Stack 由三个独立项目组成，分别对应 AI Agent 的三个核心能力：

| 层级 | 项目 | 版本 | 语言 | 功能 |
|------|------|------|------|------|
| 🧬 **人格** | [open-upsp](packages/open-upsp/) | v0.3.4 | TypeScript | 7 文件身份系统、会话蒸馏、状态演化 |
| 🧠 **记忆** | [memory-plus (SVM)](packages/memory-plus/) | v0.2.0 | Python | LRU 缓存、关键词检索、双向 ZK 同步 |
| 📚 **知识** | [Zettelkasten](packages/zettelkasten/) | beta.8.1 | TypeScript | 原子笔记、语义链接、FTS5 全文搜索、CEQRC 蒸馏 |

---

## 🏗️ 架构

```
┌─────────────────────────────────────────┐
│            AI Agent (LLM)               │
│    OpenClaw / Hermes Agent              │
└──────┬──────────┬──────────────┬────────┘
       │ MCP      │ MCP / exec   │ MCP
       ▼          ▼              ▼
┌──────────┐ ┌──────────┐ ┌──────────────┐
│ open-upsp│ │memory-plus│ │ Zettelkasten │
│  人格层   │ │  记忆层   │ │   知识层      │
│          │ │          │ │              │
│ 7文件系统 │ │ SVM 内存  │ │ 原子笔记 + FTS│
│ 会话蒸馏  │ │ LRU+SQLite│ │ 语义链接 + 图谱│
│ 状态演化  │ │ ZK 双向   │ │ CEQRC 知识蒸馏│
│          │ │ 同步  │   │ │ 34+ MCP 工具  │
└────┬─────┘ └─────┬────┘ └──────┬───────┘
     │             │             │
     └──────┬──────┘             │
            ▼                    ▼
     ┌──────────────────────────────────┐
     │         Zettelkasten DB          │
     │    (SQLite + Markdown + FTS5)    │
     └──────────────────────────────────┘
```

### 数据流

1. **Zettelkasten** 作为核心知识库，存储所有原子笔记、链接关系和元数据
2. **memory-plus** 通过双向同步引擎与 ZK 数据库交互：冷数据备份到 ZK，ZK 中的重要/近期笔记热加载到 SVM 缓存
3. **open-upsp** 读取 ZK 数据库作为深度记忆，通过 SQLite 桥接器实现知识增强的人格上下文

---

## 🚀 快速安装

### AI Agent 一句话安装

让 AI Agent 执行以下命令即可完整安装所有组件：

```bash
curl -fsSL https://raw.githubusercontent.com/cx2002302-lang/agent-stack/main/scripts/quick-install.sh | bash
```

脚本会自动：
1. 克隆 agent-stack 到 `~/.openclaw/agent-stack/`
2. 安装三个子项目（Zettelkasten + memory-plus + open-upsp）
3. 检测已有 ZK 数据库，跳过危险操作

### 手动安装（开发用）

```bash
git clone https://github.com/cx2002302-lang/agent-stack.git
cd agent-stack
chmod +x scripts/install.sh
./scripts/install.sh
```

安装脚本会依次安装：
1. `packages/zettelkasten/` — `npm install`
2. `packages/memory-plus/` — `pip install -e ".[test]"`
3. `packages/open-upsp/` — `npm install && npm run build`

### 单独安装

每个组件也可以单独安装，详见各组件目录下的 README：

- [Zettelkasten 安装说明](packages/zettelkasten/README.md)（英文）/[README.zh.md](packages/zettelkasten/README.zh.md)（中文）
- [Memory Plus 安装说明](packages/memory-plus/README.md)
- [open-upsp 安装说明](packages/open-upsp/README.md)（英文）/[README.zh.md](packages/open-upsp/README.zh.md)（中文）

---

## 📁 项目结构

```
agent-stack/
├── packages/
│   ├── zettelkasten/       # 知识库插件 (TypeScript)
│   ├── memory-plus/        # 记忆管理 (Python)
│   └── open-upsp/          # 人格协议 (TypeScript)
├── scripts/
│   ├── quick-install.sh    # curl|bash 一句话安装
│   ├── install.sh          # 完整安装脚本
│   └── deploy.sh           # Docker 部署脚本
├── docs/
│   ├── architecture.md     # 架构详解
│   └── assets/             # 配图资源
├── .gitignore
├── CHANGELOG.md
├── LICENSE
├── README.md               # 本文（中文）
└── README.en.md            # English
```

---

## 🧪 测试状态

| 项目 | 测试数 | 覆盖 |
|------|--------|------|
| Zettelkasten | 1,724 | — |
| Memory Plus | 80 | — |
| open-upsp | 199 | 94.39% |

---

## 📜 许可证

[MIT](LICENSE) © Agent Stack Contributors

## 🙏 致谢

- 基于 [OpenClaw](https://github.com/openclaw) Agent 框架构建
- 受 Niklas Luhmann 的 Zettelkasten 方法启发
- 使用 SQLite FTS5 提供全文搜索
