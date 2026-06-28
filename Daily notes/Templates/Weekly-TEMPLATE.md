<%*
const weekIndexFor = (m) => String(Math.ceil(m.date() / 7)).padStart(2, "0");
let d = moment(tp.file.title, "YYYY-MM-[W]WW");
if (!d.isValid()) { d = moment(tp.file.creation_date("YYYY-MM-DD"), "YYYY-MM-DD"); }
const canonical = `${d.format("YYYY-MM")}-W${weekIndexFor(d)}`;
if (tp.file.title !== canonical) { try { await tp.file.rename(canonical); } catch (e) {} }
const year = d.format("YYYY");
const month = d.format("YYYY-MM");
const q = "Q" + Math.ceil((d.month() + 1) / 3);
const startOfWeek = d.clone().startOf("isoWeek");
const endOfWeek = d.clone().endOf("isoWeek");
const prevWeek = d.clone().subtract(7, "days");
const nextWeek = d.clone().add(7, "days");
const prevTitle = `${prevWeek.format("YYYY-MM")}-W${weekIndexFor(prevWeek)}`;
const nextTitle = `${nextWeek.format("YYYY-MM")}-W${weekIndexFor(nextWeek)}`;
const days = [];
for (let i = 0; i < 7; i++) days.push(startOfWeek.clone().add(i, "days").format("YYYY-MM-DD"));
const daysLiteral = days.map(x => '"' + x + '"').join(",");
const labels = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"];
const dayLinks = days.map((x, i) => `[[${x}|${labels[i]}]]`).join(" · ");
-%>
---
cssclasses:
  - hide-properties
  - weekly
---

## [[<% year %>]] / [[<% year %>-<% q %>|<% q %>]] / [[<% month %>|<% d.clone().locale("en").format("MMMM") %>]] / <% canonical %>
# 💪WEEKLY NOTE
##### ❮ [[<% prevTitle %>]] | <% canonical %> | [[<% nextTitle %>]] ❯ **<% startOfWeek.format("YYYY-MM-DD") %>** — **<% endOfWeek.format("YYYY-MM-DD") %>**

---
### This Week's Days
<% dayLinks %>

---
### Goals



---
### Weekly Review
#### Wins


#### To Improve

#### Key Takeaways


---
### Habit Stats
```dataviewjs
const days = [<% daysLiteral %>];
const pages = dv.pages('"Daily notes/Calendar/Journal/Daily"').where(p => days.includes(p.file.name));
const habits = [{k:'meditation',e:'🧘'},{k:'workout',e:'💪'},{k:'reading',e:'📚'},{k:'exercise',e:'🏃'},{k:'report',e:'📝'}];
let md = '| | ' + days.map(d => '**' + d.slice(5) + '**').join(' | ') + ' |\n';
md += '|:---|' + days.map(() => ':---:').join('|') + '|\n';
for (const h of habits) {
  const row = days.map(d => { const p = pages.find(pg => pg.file.name === d); return (p && p[h.k]) ? '✅' : '⬜'; });
  md += '| ' + h.e + ' ' + h.k + ' | ' + row.join(' | ') + ' |\n';
}
dv.paragraph(md);
```
