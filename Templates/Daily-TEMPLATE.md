<%*
let d = moment(tp.file.title, "YYYY-MM-DD");
let q = "Q" + (Math.floor(d.month() / 3) + 1);
let w = d.isoWeek().toString().padStart(2, '0');
-%>
---
week: '[[<% d.format("YYYY") %>-W<% w %>]]'
date: '<% tp.file.title %>'
cssclasses:
  - hide-properties
  - daily
  <% "- " + tp.date.now("dddd", 0, tp.file.title, "YYYYMMDD").toLowerCase() %>
---

## [[<% d.format("YYYY")%>]] / [[<%d.format("YYYY")%>-<% q %>|<% q %>]] / [[<% d.format("YYYY-MM") %>|<% d.clone().locale("en").format("MMMM") %>]] / [[<% d.format("YYYY") %>-W<% w %>|Week <% d.isoWeek() %>]]
# DAILY NOTE
##### ❮ [[<% d.clone().subtract(1, 'days').format("YYYY-MM-DD") %>]] | <% tp.file.title %> | [[<% d.clone().add(1, 'days').format("YYYY-MM-DD") %>]] ❯
---
### 📕Freewrite




---
### ⚛️Habits
#### ☀️Morning
- [ ] Drink Water
- [ ] Stretch
- 🧘🏻[meditation::]
- [ ] Plan the day
- [ ] Check Email

#### Habits
- 📖[reading::]
- 🏃‍♀️[running::]
#### 🥦Health
- [ ] 鱼油
- [ ] 维生素D
- [ ] 肌酸

#### 💪Body
- 🏋🏻‍♂️[workout::]
	- [ ] Protein

#### End-of-Day Checklist
- [ ] Backup Vault
---

<%*
let birth = "2006-06-16";
let death = moment(birth).add(80, 'years');
let daysLeft = death.diff(moment(tp.file.title, "YYYY-MM-DD"), 'days');
%>
> [!error] 死亡倒计时：**<% daysLeft %> 天**

![[Bases/On This Day.base]] 

