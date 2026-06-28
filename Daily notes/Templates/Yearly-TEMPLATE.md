<%*
let d = moment(tp.file.title, "YYYY");
if (!d.isValid()) { d = moment(tp.file.creation_date("YYYY-MM-DD"), "YYYY-MM-DD"); }
const canonical = d.format("YYYY");
if (tp.file.title !== canonical) { try { await tp.file.rename(canonical); } catch (e) {} }
const prevYear = d.clone().subtract(1, "year").format("YYYY");
const nextYear = d.clone().add(1, "year").format("YYYY");
const quarters = ["Q1", "Q2", "Q3", "Q4"];
const qLinks = quarters.map(qq => "[[" + canonical + "-" + qq + "|" + qq + "]]").join(" · ");
const monthAbbr = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
const mLinks = monthAbbr.map((n, i) => "[[" + canonical + "-" + String(i + 1).padStart(2, "0") + "|" + n + "]]").join(" · ");
-%>
---
cssclasses:
  - hide-properties
  - yearly
---

## [[<% canonical %>]]
# YEARLY REVIEW
##### ❮ [[<% prevYear %>]] | <% canonical %> | [[<% nextYear %>]] ❯

---
### 📅 本年各季
<% qLinks %>

---
### 📅 本年各月
<% mLinks %>

---
### 🎯 年度目标



---
### 📝 年度回顾
#### 🌟 年度成就


#### 🔄 待改进


#### 💡 年度主题


---
### 📊 年度统计
```dataviewjs
const y = "<% canonical %>";
const pages = dv.pages('"Daily notes/Calendar/Journal/Daily"').where(p => p.file.name.startsWith(y));
dv.paragraph("📅 全年共 **" + pages.length + "** 篇日记");
const habits = ['meditation','workout','reading','exercise','report'];
const emoji = {meditation:'🧘',workout:'💪',reading:'📖',exercise:'🏃',report:'📰'};
for (const h of habits) { const c = pages.where(p => p[h]).length; if (c > 0) dv.paragraph(emoji[h] + " " + h + "：全年 **" + c + "** 天"); }
```
