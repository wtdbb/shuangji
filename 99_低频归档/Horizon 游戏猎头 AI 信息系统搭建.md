# Horizon 游戏猎头 AI 信息系统搭建

标签: #AI #Horizon #猎头 #游戏行业 #信息搜集

## 当前状态

已经完成 Horizon 本地基础搭建，但这些文件是创建在项目目录里，不是在当前 Obsidian 库里自动生成的。

项目路径：

`C:\Users\EDY\Documents\开始\Horizon`

## 已完成内容

- 已克隆 Horizon 仓库
- 已创建 Python 虚拟环境 `.venv`
- 已安装项目依赖
- 已生成 `.env` 占位文件
- 已生成 `data/config.json`
- 已生成适合“游戏程序 + 游戏策划猎头”的初始信息源配置
- 已生成启动脚本 `run-horizon.ps1`
- 已写入 AI 密钥并完成首轮运行调试
- 已修复 Windows GBK 编码导致的 Horizon 启动报错
- 已按首跑结果收紧配置，减少泛技术噪音

## 关键文件

- 项目目录：`C:\Users\EDY\Documents\开始\Horizon`
- 配置文件：`C:\Users\EDY\Documents\开始\Horizon\data\config.json`
- 密钥文件：`C:\Users\EDY\Documents\开始\Horizon\.env`
- 中文说明：`C:\Users\EDY\Documents\开始\Horizon\docs\game-recruiter-setup-zh.md`

## 默认监控方向

- 游戏行业资讯
  - GamesIndustry.biz
  - Game Developer
  - PocketGamer.biz
- 引擎与工具链
  - Unity Blog
  - Godot RSS
  - Godot / Cocos / ImGui / SDL GitHub Release
- 社区讨论
  - Reddit: `gamedev`
  - Reddit: `gamedesign`
  - Reddit: `unrealengine`
  - Reddit: `Unity3D`
  - Reddit: `godot`
  - Reddit: `gameDevClassifieds`
- 开源趋势
  - OSS Insight 游戏/图形/引擎关键词趋势

## 最近调试结果

### 第一轮运行结果

- 系统可以启动
- 但 Windows 终端默认编码导致 Rich 输出 emoji 时崩溃
- 修复后可正常运行
- 首轮摘要被 `Hacker News` 泛技术内容带偏，不够适合猎头使用

### 第二轮运行结果

- 已关闭 `Hacker News`
- 已暂时关闭 `Reddit`
  - 原因：当前抓取不稳定，容易遇到反爬或限流
- 已补充更偏游戏职业与设计方向的 RSS
- 当前摘要已经能筛出更相关的内容
  - `Unreal Engine 6 / UE 5.8`
  - `Godot 4.7`

### 当前仍存在的问题

- GitHub Release 抓取被限流
  - 需要补 `GITHUB_TOKEN`
- `Ask a Game Dev` 这个源当前返回 `403`
  - 后续可以换源或禁用
- 现在的摘要更偏“行业 + 引擎”
  - 如果你希望更偏“招聘/人才流动”，还需要继续补定向信息源

## 还需要补充

AI 密钥已经配置。

接下来最推荐补的是：

```text
GITHUB_TOKEN=你的值
```

可选：

```text
HORIZON_WEBHOOK_URL=你的值
APIFY_TOKEN=你的值
```

## 下一步

把密钥发给 Codex 后，可以继续完成：

- 写入 `.env`
- 继续提高 GitHub 抓取稳定性
- 继续调整成更偏程序岗或策划岗的人才雷达
- 如果你要，我可以继续把结果同步成 Obsidian 日报笔记模板
