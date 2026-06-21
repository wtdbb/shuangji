
**Good Habits**
```dataviewjs
const trackerData = {
    year: 2026,
    entries: [],
    heatmapTitle: "🧘Meditation Tracker",
    colorScheme: {
        paletteName: "default"
    }
}

for(let page of dv.pages('"Calendar/Journal/Daily"').where(p => p.meditation)) {
    trackerData.entries.push({
        date: page.file.name,
        intensity: 1
    })
}

renderHeatmapTracker(this.container, trackerData)
```

```dataviewjs
const trackerData = {
    year: 2026,
    entries: [],
    heatmapTitle: "💪Workout Tracker",
    colorScheme: {
        paletteName: "default",
        customColors: ["#FF8C00"]
    }
}

for(let page of dv.pages('"Calendar/Journal/Daily"').where(p => p.workout)) {
    trackerData.entries.push({
        date: page.file.name,
        intensity: 1
    })
}

renderHeatmapTracker(this.container, trackerData)
```

```dataviewjs
const trackerData = {
    year: 2026,
    entries: [],
    heatmapTitle: "📖Reading Tracker",
    colorScheme: {
        paletteName: "default",
        customColors: ["#6495ED"]
    }
}

for(let page of dv.pages('"Calendar/Journal/Daily"').where(p => p.reading)) {
    trackerData.entries.push({
        date: page.file.name,
        intensity: 1
    })
}

renderHeatmapTracker(this.container, trackerData)
```