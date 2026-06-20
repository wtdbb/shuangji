# Claude 接力说明

标签: #Claude #Codex #接力 #自动化

## 最推荐的接力方式

不要把完整聊天记录全部复制给 Claude。更稳的方式是让 Claude 读取当前工作目录里的接力文件：

```text
C:\Users\EDY\Documents\开始\CLAUDE.md
```

这个文件已经整理了当前项目状态、关键路径、飞书同步规则、Obsidian 结构和安全边界。

## 使用步骤

1. 打开终端。
2. 进入工作目录：

```powershell
cd C:\Users\EDY\Documents\开始
```

3. 启动 Claude：

```powershell
claude
```

如果 `claude` 命令不可用，用完整路径：

```powershell
C:\Users\EDY\AppData\Roaming\npm\claude.cmd
```

4. 给 Claude 粘贴这句话：

```text
请先阅读当前目录的 CLAUDE.md，按照里面的项目上下文、飞书岗位同步规则和安全规则继续协助我。不要输出或保存任何密钥。当前我要你继续处理：这里写具体任务。
```

## 为什么不直接复制完整聊天

完整聊天通常太长，而且里面有很多过程性内容。Claude 更需要的是：

- 当前目标
- 当前目录
- 已完成什么
- 下一步做什么
- 哪些命令可用
- 哪些内容不能碰

`CLAUDE.md` 就是为这个目的准备的。

## 每次重大变更后要更新

当系统结构、飞书表、Obsidian 目录、自动化规则发生变化时，让 Codex 或 Claude 更新：

```text
C:\Users\EDY\Documents\开始\CLAUDE.md
```

这样两个 AI 才能保持同一套上下文。
