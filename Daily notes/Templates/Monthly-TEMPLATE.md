<%*
let d = moment(tp.file.title, "YYYY-MM");
if (!d.isValid()) { d = moment(tp.file.creation_date("YYYY-MM-DD"), "YYYY-MM-DD"); }
const canonical = d.format("YYYY-MM");
if (tp.file.title !== canonical) { try { await tp.file.rename(canonical); } catch (e) {} }
const year = d.format("YYYY");
const monthName = d.clone().locale("en").format("MMMM");
const q = "Q" + Math.ceil((d.month() + 1) / 3);
const prevMonth = d.clone().subtract(1, "month").format("YYYY-MM");
const nextMonth = d.clone().add(1, "month").format("YYYY-MM");
const weekCount = Math.ceil(d.daysInMonth() / 7);
const weekLinks = Array.from({ length: weekCount }, (_, i) => {
  const idx = String(i + 1).padStart(2, "0");
  return `[[${canonical}-W${idx}|W${idx}]]`;
}).join(" · ");
-%>
---
cssclasses:
  - hide-properties
  - monthly
---

## [[<% year %>]] / [[<% year %>-<% q %>|<% q %>]] / [[<% canonical %>|<% monthName %>]]
# MONTHLY NOTE
##### ❮ [[<% prevMonth %>]] | <% canonical %> | [[<% nextMonth %>]] ❯

---
### Weeks of this Month
<% weekLinks %>

---
### Goals



---
### Monthly Review
#### Wins


#### To Improve

#### Key Themes


---
### Daily Note Stats
```dataviewjs
const ym = "<% canonical %>";
const pages = dv.pages('"Daily notes/Calendar/Journal/Daily"').where(p => p.file.name.startsWith(ym)).sort(p => p.file.name, 'asc');
dv.paragraph("This month has **" + pages.length + "** daily notes.");
const habits = ['meditation','workout','reading','exercise','report'];
const emoji = {meditation:'🧘',workout:'💪',reading:'📚',exercise:'🏃',report:'📝'};
for (const h of habits) { const c = pages.where(p => p[h]).length; if (c > 0) dv.paragraph(emoji[h] + " " + h + ": **" + c + "**"); }
```
