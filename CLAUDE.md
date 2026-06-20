# CodexVault 项目规范(给 Claude / Codex)

## Skill 存放约定
- 所有生成/安装的 skill **统一放在 `.claude/skills/` 下**,每个 skill 一个**命名清晰的独立子文件夹**。
- 命名示例:视频转字幕总结 skill = `.claude/skills/sp-skill`。
- 每个 skill 自带 `SKILL.md`;密钥写在该 skill 目录的 `.env`。

## 密钥安全
- 任何 `.env`、token、API Key **绝不提交进 git**。
- `.gitignore` 已用 `.claude/skills/**/.env` 通配忽略所有 skill 的密钥文件。
- 不在笔记、回复、日志里输出真实密钥。

## 自动备份(已配置)
- 每次文件改动由 Claude hook + 计划任务自动 `git commit`。
- 计划任务:`CodexVault-AutoCommit`(每2分钟)、`CodexVault-WeChatFetch`(每30分钟)。
- 共用脚本:`.claude/hooks/auto-commit.ps1`。

## 内容归类规则(游戏猎头)
- **岗位mapping**(`游戏行业日报/岗位mapping.md`):具体公司/工作室/项目/岗位动态(如某项目上线时间、在招方向、制作人变动)。
- **行业mapping**(`游戏行业日报/行业mapping.md`):行业格局/公司重组/市场趋势/薪资。
- 信息进库前先给用户看,确认再写。

## 环境备注
- 系统:Windows + PowerShell 5.1(读无 BOM 的 UTF-8 会乱码,写 .ps1 含中文时要加 BOM)。
- git:`C:\个人\ai文件\Git`;Python 3.13;FFmpeg 已在 PATH。
