/**
 * Zettelkasten 核心功能 Smoke Tests
 *
 * 覆盖核心链路（对应 standalone 仓库的最小测试子集）：
 * 1. create note  —— 创建笔记并落库
 * 2. get note     —— 按 ID 读取笔记
 * 3. search note  —— 全文搜索命中
 * 4. create link  —— 创建双向链接并统计
 * 5. health check —— 系统统计指标一致
 *
 * 说明：standalone 仓库（~/.openclaw/project/zettelkasten）的完整 __tests__
 * 已随源码同步到本包。本文件作为兜底 smoke 层，专门覆盖 ZettelkastenClient
 * 门面（index.ts）的核心链路，保证最小可用性验证独立存在。
 */

import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { DatabaseSync } from "node:sqlite";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { ZettelkastenClient } from "../index.js";

describe("Zettelkasten smoke tests", () => {
  let dir: string;
  let db: DatabaseSync;
  let client: ZettelkastenClient;

  beforeEach(async () => {
    dir = mkdtempSync(join(tmpdir(), "zk-smoke-"));
    db = new DatabaseSync(join(dir, "test.db"));
    client = new ZettelkastenClient(db, join(dir, "notes"));
    await client.initialize();
  });

  afterEach(() => {
    db.close();
    rmSync(dir, { recursive: true, force: true });
  });

  it("create note: 创建笔记并持久化", async () => {
    const note = await client.createNote({
      title: "Smoke Test Note",
      content: "This is a smoke test note about zettelkasten.",
      tags: ["smoke", "test"],
    });

    expect(note.id).toBeTruthy();
    expect(note.title).toBe("Smoke Test Note");
    expect(note.tags).toContain("smoke");

    const stats = client.getStats();
    expect(stats.notes).toBe(1);
  });

  it("get note: 按 ID 读取，未知 ID 返回 null", async () => {
    const created = await client.createNote({
      title: "Get Me",
      content: "note to be fetched by id",
    });

    const fetched = client.getNote(created.id);
    expect(fetched).not.toBeNull();
    expect(fetched!.id).toBe(created.id);
    expect(fetched!.title).toBe("Get Me");

    expect(client.getNote("non-existent-id")).toBeNull();
  });

  it("search note: 全文搜索能命中关键词", async () => {
    await client.createNote({
      title: "Ephemeral Ports",
      content: "ephemeralization means doing more with less",
    });
    await client.createNote({
      title: "Unrelated",
      content: "completely different content here",
    });

    const results = client.searchNotes("ephemeralization");
    expect(results.length).toBeGreaterThan(0);
    expect(results[0].note.title).toBe("Ephemeral Ports");
  });

  it("create link: 创建链接并反映到统计", async () => {
    const a = await client.createNote({ title: "Note A", content: "content a" });
    const b = await client.createNote({ title: "Note B", content: "content b" });

    client.createLink(a.id, b.id, "related", "smoke link");

    const linkStats = client.getLinkStats();
    expect(linkStats.total).toBe(1);
    expect(linkStats.byType.related).toBe(1);
  });

  it("health check: 统计接口返回一致的系统指标", async () => {
    // 空库健康检查
    const empty = client.getStats();
    expect(empty.notes).toBe(0);
    expect(empty.links).toBe(0);
    expect(empty.linkStats.total).toBe(0);

    // 写入数据后指标一致
    const a = await client.createNote({
      title: "Health A",
      content: "health check content a",
      tags: ["health"],
    });
    const b = await client.createNote({
      title: "Health B",
      content: "health check content b",
    });
    client.createLink(a.id, b.id, "supports");

    const stats = client.getStats();
    expect(stats.notes).toBe(2);
    expect(stats.links).toBe(1);
    expect(stats.linkStats.total).toBe(1);
    expect(Array.isArray(stats.tagStats)).toBe(true);
  });

  it("update/delete note: 更新后生效，删除后不可读", async () => {
    const note = await client.createNote({
      title: "To Update",
      content: "original content",
    });

    const updated = await client.updateNote(note.id, { title: "Updated Title" });
    expect(updated).not.toBeNull();
    expect(client.getNote(note.id)!.title).toBe("Updated Title");

    expect(await client.deleteNote(note.id)).toBe(true);
    expect(client.getNote(note.id)).toBeNull();
    expect(client.getStats().notes).toBe(0);
  });

  it("query notes: 按文件夹过滤查询", async () => {
    await client.createNote({
      title: "Inbox Note",
      content: "stays in inbox",
      folder: "inbox",
    });
    await client.createNote({
      title: "Zettel Note",
      content: "goes to zettels",
      folder: "zettels",
    });

    const inbox = client.queryNotes({ folder: "inbox" });
    expect(inbox.length).toBe(1);
    expect(inbox[0].title).toBe("Inbox Note");

    const zettels = client.queryNotes({ folder: "zettels" });
    expect(zettels.length).toBe(1);
    expect(zettels[0].title).toBe("Zettel Note");
  });
});
