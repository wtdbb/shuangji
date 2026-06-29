<%*
let d = moment(tp.file.title, "YYYY-MM-DD");
let q = "Q" + (Math.floor(d.month() / 3) + 1);
const weekOfMonth = String(Math.ceil(d.date() / 7)).padStart(2, "0");
const weekTitle = `${d.format("YYYY-MM")}-W${weekOfMonth}`;
-%>
---
week: '[[<% weekTitle %>]]'
date: '<% tp.file.title %>'
cssclasses:
  - hide-properties
  - daily
  <% "- " + tp.date.now("dddd", 0, tp.file.title, "YYYYMMDD").toLowerCase() %>
---

## [[<% d.format("YYYY")%>]] / [[<%d.format("YYYY")%>-<% q %>|<% q %>]] / [[<% d.format("YYYY-MM") %>|<% d.clone().locale("en").format("MMMM") %>]] / [[<% weekTitle %>|Week <% weekOfMonth %>]]
# 📚DAILY NOTE
##### ❮ [[<% d.clone().subtract(1, 'days').format("YYYY-MM-DD") %>]] | <% tp.file.title %> | [[<% d.clone().add(1, 'days').format("YYYY-MM-DD") %>]] ❯
---
### 📖Freewrite




---
### ⭐Habits
#### Morning
- [ ] Drink Water：two cups
- [ ] Stretch
- 🧘🏻[meditation::]
- [ ] Plan the day：一个推荐ur20个备选
#### Habits
- 📚[reading::]：one city
- 🏃‍♀️[exercise::]
- 📝[report::]

#### End-of-Day Checklist
- [ ] Backup Vault
---

<%*
let birth = "2006-06-16";
let death = moment(birth).add(80, 'years');
let daysLeft = death.diff(moment(tp.file.title, "YYYY-MM-DD"), 'days');
%>
> [!error] 死亡倒计时：**<% daysLeft %> 天**

![[Daily notes/Bases/On This Day.base]]

