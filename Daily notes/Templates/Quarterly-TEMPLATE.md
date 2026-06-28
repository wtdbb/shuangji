<%*
let d = moment(tp.file.title, "YYYY-[Q]Q");
if (!d.isValid()) { d = moment(tp.file.creation_date("YYYY-MM-DD"), "YYYY-MM-DD"); }
const canonical = d.format("YYYY-[Q]Q");
if (tp.file.title !== canonical) { try { await tp.file.rename(canonical); } catch (e) {} }
const year = d.format("YYYY");
const qNum = d.quarter();
const prevQ = d.clone().subtract(1, "quarter").format("YYYY-[Q]Q");
const nextQ = d.clone().add(1, "quarter").format("YYYY-[Q]Q");
const months = [];
for (let i = 0; i < 3; i++) { const m = d.clone().startOf("quarter").add(i, "month"); months.push({ k: m.format("YYYY-MM"), n: m.clone().locale("en").format("MMMM") }); }
const monthLinks = months.map(m => "[[" + m.k + "|" + m.n + "]]").join(" · ");
const qStart = d.clone().startOf("quarter").format("YYYY-MM-DD");
const qEnd = d.clone().endOf("quarter").format("YYYY-MM-DD");
-%>
---
cssclasses:
  - hide-properties
  - quarterly
---

## [[<% year %>]] / [[<% canonical %>|Q<% qNum %>]]
# QUARTERLY REVIEW
##### ❮ [[<% prevQ %>]] | <% canonical %> | [[<% nextQ %>]] ❯

---
### 📅 本季各月
<% monthLinks %>

---
### 🎯 季度目标



---
### 📝 季度回顾
#### 🌟 季度成就


#### 🔄 待改进


#### 💡 季度主题


---
### 📊 季度统计
```dataviewjs
const s = "<% qStart %>", e = "<% qEnd %>";
const pages = dv.pages('"Daily notes/Calendar/Journal/Daily"').where(p => p.file.name >= s && p.file.name <= e);
dv.paragraph("📅 本季共 **" + pages.length + "** 篇日记");
const habits = ['meditation','workout','reading','exercise','report'];
const emoji = {meditation:'🧘',workout:'💪',reading:'📖',exercise:'🏃',report:'📰'};
for (const h of habits) { const c = pages.where(p => p[h]).length; if (c > 0) dv.paragraph(emoji[h] + " " + h + "：**" + c + "** 天"); }
```
