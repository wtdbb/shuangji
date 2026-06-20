# CodexVault 项目规范(给 Claude / Codex)

## Skill 存放约定
- 真实文件统一放在 **vault 根目录的 `skill/`** 文件夹,每个 skill 一个命名清晰的独立子文件夹。
- `.claude/skills` 是指向 `skill/` 的**目录联接(junction)**,Claude 靠它加载 skill;两者内容相同。
- 命名示例:视频转字幕总结 skill = `skill/sp-skill`(经 junction 映射为 `.claude/skills/sp-skill`)。
- **新增 skill 放进 `skill/<名字>/`** 即可,会自动通过 junction 被 Claude 识别。
- 每个 skill 自带 `SKILL.md`;密钥写在该 skill 目录的 `.env`。
- git 只跟踪 `skill/`;`.gitignore` 忽略 junction 视图 `/.claude/skills/`,并以 `/skill/**/.env` 屏蔽所有密钥。
- 注意:junction 不随 git clone 复制;换机器后需重新执行 `mklink /J .claude\skills skill`。

## 密钥安全
- 任何 `.env`、token、API Key **绝不提交进 git**。
- `.gitignore` 已用 `.claude/skills/**/.env` 通配忽略所有 skill 的密钥文件。
- 不在笔记、回复、日志里输出真实密钥。

## 自动备份(已配置)
- 每次文件改动由 Claude hook + 计划任务自动 `git commit`。
- 计划任务:`CodexVault-AutoCommit`(每2分钟)、`CodexVault-WeChatFetch`(每30分钟)。
- 共用脚本:`.claude/hooks/auto-commit.ps1`。

## 内容归类规则(游戏猎头)
- **公众号原文**: 先入 `行业报告/公众号原内容/`。
- **日报**: 原文归档后,再参考 `行业报告/日报输出/` 生成日报。
- **岗位mapping**(`岗位mapping/index.md`):具体公司/工作室/项目/岗位动态(如某项目上线时间、在招方向、制作人变动)。只写精简要点,优先写入现有城市/补充记录文件。
- **行业mapping**(`行业mapping/index.md`):行业格局/公司重组/市场趋势/薪资。只写精简要点,优先写入现有主题文件。
- 公众号内容若只出现游戏名/项目名而未直接出现公司名,允许反推公司,并标注 `（推断）`。
- 信息进库前先给用户看,确认再写。

## 环境备注
- 系统:Windows + PowerShell 5.1(读无 BOM 的 UTF-8 会乱码,写 .ps1 含中文时要加 BOM)。
- git:`C:\个人\ai文件\Git`;Python 3.13;FFmpeg 已在 PATH。
