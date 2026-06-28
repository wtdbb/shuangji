# 🤖 跨 Agent 共享上下文 (Sync Context)

此文件用于在 **Claudian (Obsidian插件/OpenCode)**、**Codex (OpenCode终端)** 与 **Claude Code (Anthropic CLI)** 三者之间同步项目进度与上下文。

### 🔄 当前同步状态 (2026-06-28)
- **OpenCode/Claudian 上下文已获取**：我们刚刚完成了针对 OpenCode 客户端的模型配置更新，移除了失效的模型，并成功切换到了最新、最强大的 `google/gemini-3.1-pro-preview` 与快速的 `google/gemini-3.1-flash-lite` 模型，测试均已跑通。
- **Claude Code 上下文对接**：Claude Code 的本地历史位于其私有缓存目录。为实现真正的三方数据打通，建议您在启动 Claude Code 或使用其他 CLI 时，发送：`读取并更新项目根目录下的 CONTEXT.md`。

### 📝 当前工作焦点 (TODO)
- [x] 排查与更新 OpenCode / Claudian 的可用 Gemini 模型配置（已切至 Gemini 3.1 Pro 预览版）。
- [x] 已将乐元素 VP、网易世界之外、B站二合的岗位需求批量打入飞书 Bitable 表格。
- **【全局生效新规则】**：凡是用户提到“xxx公司招xxxx”等字眼，**统一全自动写入到飞书的岗位多维表格中**。
   - 策划表 Token: `Wku3bvj9tavorOsQFklcZxB4n6g` (Table: `tbl1cBjF71hyh7Y1`)
   - 程序表 Token: `RhSebw9EraPrETsKVXyctJ8Gn4e` (Table: `tbl2AmTJTTsBnVE6`)

---
> **⚡ 对后续 Agent 的工作约定**：
> 任何智能体（Claudian、Codex、Claude Code）在结束一次完整的需求处理后，**必须**将最新进展和下一阶段 TODO 简明扼要地更新至本文件，以保证下一个接手的 Agent 拥有最新的全局上下文。
