---
layout: kaizenly-post
title: "Every element a Markdown post can produce"
description: "Layout fixture. Never published — flip published to true to re-run the responsive audit against every element a Markdown post can emit."
published: false
---

Intro paragraph with a [link](https://getkaizenly.com/), some **bold**, some *italic*,
and `inline code` in the middle of a sentence that runs long enough to wrap on a phone.

## A second-level heading

Another paragraph. Below is an unordered list:

- First item
- Second item with a nested list
  - Nested one
  - Nested two
- Third item

### A third-level heading

1. Ordered first
2. Ordered second
3. Ordered third

> A blockquote, which should sit inside an accent rule.
>
> With a second paragraph in it.

#### A fourth-level heading

A code block with a deliberately long line that cannot wrap:

```
adb -s <serial> shell cmd locale set-app-locales kaizenly.daily.habit.tracker --locales de-DE
```

A table, which kramdown emits with no wrapper:

| Widget | Shows | Closest Loop widget |
|---|---|---|
| Progress plant | All of today at once | No equivalent |
| Single habit | Tick it, or start its stopwatch | Checkmark / Target |
| Habit heatmap | A year of consistency | History |

---

An image:

![Kaizenly home screen](/assets/img/screens/01-home-720.webp)

A very long unbroken token to try to break the layout:
`Loop-Habits-Backup-2026-08-16-verylongfilename-that-cannot-wrap-anywhere.db`

Final paragraph.
