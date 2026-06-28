---
cssclasses:
  - hide-properties
---
# ⚛️ Habits Tracker · 2026

> **如何点亮**
> - ☑️ **复选框习惯**：将 `- [ ]` 改为 `- [x]` 即自动点亮
> - ✏️ **内联字段习惯**：在 `[字段::]` 的 `::` 后填入任意内容（如 `1`、书名、距离）即可点亮

---

## ☀️ 早晨打卡

### 💧 Drink Water
```dataviewjs
const trackerData = {
    year: 2026,
    entries: [],
    heatmapTitle: "💧 Drink Water",
    intensityScaleStart: 0,
    intensityScaleEnd: 1,
    colorScheme: {
        customColors: ["#daeeff", "#96d0f5", "#4daee8", "#1a88d0", "#0a63a8"]
    }
}
for (let page of dv.pages('"Daily notes/Calendar/Journal/Daily"')) {
    const done = page.file.tasks.where(t => t.completed && t.text.includes("Drink Water"));
    if (done.length > 0) trackerData.entries.push({ date: page.file.name, intensity: 1 });
}
window.renderHeatmapTracker(this.container, trackerData);
```

### 🤸 Stretch
```dataviewjs
const trackerData = {
    year: 2026,
    entries: [],
    heatmapTitle: "🤸 Stretch",
    intensityScaleStart: 0,
    intensityScaleEnd: 1,
    colorScheme: {
        customColors: ["#fce4ff", "#e9aaff", "#d070f5", "#b040e0", "#8a18b8"]
    }
}
for (let page of dv.pages('"Daily notes/Calendar/Journal/Daily"')) {
    const done = page.file.tasks.where(t => t.completed && t.text.includes("Stretch"));
    if (done.length > 0) trackerData.entries.push({ date: page.file.name, intensity: 1 });
}
window.renderHeatmapTracker(this.container, trackerData);
```

### 📋 Plan the Day
```dataviewjs
const trackerData = {
    year: 2026,
    entries: [],
    heatmapTitle: "📋 Plan the Day",
    intensityScaleStart: 0,
    intensityScaleEnd: 1,
    colorScheme: {
        customColors: ["#fdf4d8", "#f8e08a", "#f0c030", "#d89c10", "#a87000"]
    }
}
for (let page of dv.pages('"Daily notes/Calendar/Journal/Daily"')) {
    const done = page.file.tasks.where(t => t.completed && t.text.includes("Plan the day"));
    if (done.length > 0) trackerData.entries.push({ date: page.file.name, intensity: 1 });
}
window.renderHeatmapTracker(this.container, trackerData);
```

### 🗂️ Backup Vault
```dataviewjs
const trackerData = {
    year: 2026,
    entries: [],
    heatmapTitle: "🗂️ Backup Vault",
    intensityScaleStart: 0,
    intensityScaleEnd: 1,
    colorScheme: {
        customColors: ["#e8e8e8", "#c0c0c0", "#909090", "#606060", "#303030"]
    }
}
for (let page of dv.pages('"Daily notes/Calendar/Journal/Daily"')) {
    const done = page.file.tasks.where(t => t.completed && t.text.includes("Backup Vault"));
    if (done.length > 0) trackerData.entries.push({ date: page.file.name, intensity: 1 });
}
window.renderHeatmapTracker(this.container, trackerData);
```

---

## ⚛️ 主要习惯

### 🧘 Meditation
```dataviewjs
const trackerData = {
    year: 2026,
    entries: [],
    heatmapTitle: "🧘 Meditation",
    intensityScaleStart: 0,
    intensityScaleEnd: 1,
    colorScheme: {
        customColors: ["#dff3e6", "#a8dcc0", "#6cc28f", "#3a9d62", "#1d7a40"]
    }
}
for (let page of dv.pages('"Daily notes/Calendar/Journal/Daily"').where(p => p.meditation)) {
    trackerData.entries.push({ date: page.file.name, intensity: 1 });
}
window.renderHeatmapTracker(this.container, trackerData);
```

### 💪 Workout
```dataviewjs
const trackerData = {
    year: 2026,
    entries: [],
    heatmapTitle: "💪 Workout",
    intensityScaleStart: 0,
    intensityScaleEnd: 1,
    colorScheme: {
        customColors: ["#ffe3d6", "#ffb38f", "#ff8a5c", "#f25f2e", "#c43c12"]
    }
}
for (let page of dv.pages('"Daily notes/Calendar/Journal/Daily"').where(p => p.workout)) {
    trackerData.entries.push({ date: page.file.name, intensity: 1 });
}
window.renderHeatmapTracker(this.container, trackerData);
```

### 📖 Reading
```dataviewjs
const trackerData = {
    year: 2026,
    entries: [],
    heatmapTitle: "📖 Reading",
    intensityScaleStart: 0,
    intensityScaleEnd: 1,
    colorScheme: {
        customColors: ["#dceaff", "#a9c8f5", "#6fa0e6", "#3f78d6", "#2056b3"]
    }
}
for (let page of dv.pages('"Daily notes/Calendar/Journal/Daily"').where(p => p.reading)) {
    trackerData.entries.push({ date: page.file.name, intensity: 1 });
}
window.renderHeatmapTracker(this.container, trackerData);
```

### 🏃 Exercise
```dataviewjs
const trackerData = {
    year: 2026,
    entries: [],
    heatmapTitle: "🏃 Exercise",
    intensityScaleStart: 0,
    intensityScaleEnd: 1,
    colorScheme: {
        customColors: ["#ece0fb", "#c9a8f0", "#a674e0", "#8147c9", "#5f29a3"]
    }
}
for (let page of dv.pages('"Daily notes/Calendar/Journal/Daily"').where(p => p.exercise)) {
    trackerData.entries.push({ date: page.file.name, intensity: 1 });
}
window.renderHeatmapTracker(this.container, trackerData);
```

### 📰 Report
```dataviewjs
const trackerData = {
    year: 2026,
    entries: [],
    heatmapTitle: "📰 Report",
    intensityScaleStart: 0,
    intensityScaleEnd: 1,
    colorScheme: {
        customColors: ["#fdeecb", "#f6d488", "#eeb84a", "#d99421", "#b06f0c"]
    }
}
for (let page of dv.pages('"Daily notes/Calendar/Journal/Daily"').where(p => p.report)) {
    trackerData.entries.push({ date: page.file.name, intensity: 1 });
}
window.renderHeatmapTracker(this.container, trackerData);
```
