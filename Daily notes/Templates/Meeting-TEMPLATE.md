<%*
// 新增会议：自动命名（日期-时分）并移动到 Meetings 文件夹
const name = tp.date.now("YYYY-MM-DD-HHmm");
await tp.file.move("Daily notes/Calendar/Meetings/" + name);
-%>
---
type: meeting
date: <% tp.date.now("YYYY-MM-DD") %>
time: <% tp.date.now("HH:mm") %>
attendees: 
tags:
  - meeting
---
# ☎️ 会议 · <% tp.date.now("YYYY-MM-DD HH:mm") %>

## 议题
- 

## 记录


## 待办
- [ ] 
