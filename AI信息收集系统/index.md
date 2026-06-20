# AI信息收集系统

标签: #AI #Horizon #猎头 #游戏行业 #信息搜集

## 项目概述

这个项目用于为游戏产研猎头构建一套可持续运行的 AI 信息搜集系统，当前基于 `Thysrael/Horizon` 搭建。

目标重点：

- 跟踪游戏行业公司动态
- 跟踪游戏程序与策划相关研发趋势
- 跟踪引擎、工具链、技术栈变化
- 辅助判断团队扩张、岗位变化、人才流动与行业热点

## 当前落地位置

- Horizon 项目目录：`C:\Users\EDY\Documents\开始\Horizon`
- Obsidian 项目索引：`C:\Users\EDY\Documents\CodexVault\AI信息收集系统\index.md`
- Obsidian 运行日志：`C:\Users\EDY\Documents\CodexVault\AI信息收集系统\log.md`

## 已完成

- 已克隆 Horizon 仓库
- 已创建 Python 虚拟环境 `.venv`
- 已安装依赖
- 已生成 `.env`
- 已生成 `data/config.json`
- 已生成适合“游戏程序 + 游戏策划猎头”的初始信息源配置
- 已修复 Windows GBK 编码导致的 Horizon 启动报错
- 已完成首轮运行
- 已根据首轮结果收紧配置，减少泛技术噪音

## 当前信息源方向

### 行业资讯

- GamesIndustry.biz
- Game Developer
- PocketGamer.biz

### 引擎与工具链

- Unity Blog
- Godot RSS
- Godot / Cocos / ImGui / SDL GitHub Release

### 设计与职业内容

- Designer Notes
- Lost Garden

### 暂时受限或待优化

- GitHub Release
  - 当前缺少 `GITHUB_TOKEN`，容易被限流
- Reddit
  - 当前抓取稳定性一般，已暂时关闭
- Ask a Game Dev
  - 当前返回 `403`

## 当前判断

这套系统已经从“不能跑”推进到“可以运行并产出摘要”，但还没有完全达到“稳定可用的猎头情报雷达”状态。

下一步最关键的是：

1. 补 `GITHUB_TOKEN`
2. 继续替换或补充更偏招聘、团队和人才流动的信息源
3. 再跑几轮，观察摘要是否持续贴近游戏程序 / 策划猎头需求

## 待补信息

推荐优先补：

```text
GITHUB_TOKEN=你的值
```

可选：

```text
HORIZON_WEBHOOK_URL=你的值
APIFY_TOKEN=你的值
```

## 相关文件

- 项目说明：`C:\Users\EDY\Documents\开始\Horizon\docs\game-recruiter-setup-zh.md`
- 配置文件：`C:\Users\EDY\Documents\开始\Horizon\data\config.json`
- 启动脚本：`C:\Users\EDY\Documents\开始\Horizon\run-horizon.ps1`
- 飞书岗位同步：[[飞书岗位同步系统]]
- Claude 接力说明：[[Claude 接力说明]]

## 备注

旧的同步笔记 `Horizon 游戏猎头 AI 信息系统搭建.md` 仍然保留；后续以这个 `index.md` 作为项目主入口更合适。
