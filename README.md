# getkaizenly.com

Source for **getkaizenly.com**, the product site for [Kaizenly](https://play.google.com/store/apps/details?id=kaizenly.daily.habit.tracker),
an Android habit tracker. Static Jekyll, served by GitHub Pages from `master`.

This is a **user site** (`morejump.github.io`) with a custom domain, so the repo name does not match
the domain and cannot be changed without breaking that.

> **The privacy policy is not in this repo.** `getkaizenly.com/habit-tracker-privacy/` is served
> from the separate [`habit-tracker-privacy`](https://github.com/morejump/habit-tracker-privacy)
> repo, as a project page under this user site's domain. Look there, not here, when it needs
> editing.

## Pages

| URL | File |
|---|---|
| `/` | `index.html` |
| `/loop-habit-tracker-import/` | `loop-habit-tracker-import.html` |
| `/loop-habit-tracker-sync/` | `loop-habit-tracker-sync.html` |
| `/loop-habit-tracker-widgets/` | `loop-habit-tracker-widgets.html` |
| `/404.html` | `404.html` |

The three `loop-*` pages target search queries people actually type when they are looking to move
off Loop Habit Tracker. Why those three and not others is written up in the app repo, in
`docs/marketing-plan.md` — read that before rewriting them, and keep them honest. They deliberately
admit where Loop is better, because the audience checks.

## Local preview

macOS ships Ruby 2.6, which is too old for current gems. Getting Jekyll 3.10.0 — the version GitHub
Pages actually runs — installed means pinning five dependencies:

```sh
export GEM_HOME="$HOME/.gem-jekyll" PATH="$HOME/.gem-jekyll/bin:$PATH"
gem install --no-document 'json:2.7.6' 'ffi:1.15.5' 'i18n:1.14.8' 'public_suffix:5.1.1'
gem install --no-document 'jekyll:3.10.0' 'jekyll-sitemap:1.4.0'
```

Then, from this directory:

```sh
export GEM_HOME="$HOME/.gem-jekyll" PATH="$HOME/.gem-jekyll/bin:$PATH"
jekyll serve      # http://127.0.0.1:4000
```

A plain `gem install jekyll` fails on `ffi` requiring Ruby >= 3.0. Don't retry it — either use the
pins above or install a modern Ruby first.

## The layout system

Sizes are `clamp()`ed between a phone value and a desktop value and interpolate with the viewport,
so there is no width at which the page is between designs. Only two breakpoints remain, and both
switch layout *mode* rather than size:

| | |
|---|---|
| **860px** | one column becomes two, and the screenshot scroller becomes a grid |
| **520px** | touch affordances — stacked footer links, breakable filenames |

Two container widths, because they answer different questions. `.wrap` is a 760px reading column
for long-form pages. `.wrap.wide` is 1160px for pages that should use the screen — set `wide: true`
in front matter. `--gutter` is the single source of truth for side padding; anything that bleeds to
the viewport edge must offset by exactly that, or the whole page scrolls sideways.

### Auditing it

```sh
./tools/audit.sh
```

Builds the site, loads every page in an iframe at 320, 360, 390, 412, 480, 600, 768, 860, 900,
1024, 1280, 1440 and 1920px, and fails on two things a screenshot review misses:

- **Horizontal overflow** — any element escaping the viewport, which on a phone means the page can
  be dragged sideways. Scroll containers are excluded, since they are meant to be wider.
- **Distorted images** — rendered aspect ratio not matching the file's own.

It discovers pages from the build, so a new page is covered without touching the script. **Run it
after any layout change.** All three bugs it checks for have shipped here at least once:

| Shipped bug | Caught by |
|---|---|
| Screenshot strip bled `-24px` against 18px mobile padding → 6px of page scroll | overflow |
| Global `table{min-width:420px}` applied to Markdown tables, which are their own scroll container → every blog post scrolled sideways on phones | overflow |
| `<img height="112">` beat a fluid CSS width, and `aspect-ratio` is ignored when both dimensions are definite → app icon rendered 84×112 | distortion |
| A `max-width` percentage capping an image whose height was fixed → 3% horizontal squash at three widths, invisible by eye | distortion |

The lesson in the last two: **never constrain both dimensions of an image.** Fix one, let the other follow.

To include a blog post in the run, flip `published` on the kitchen-sink fixture (below) to `true`
temporarily.

## Adding a blog post

Drop a Markdown file in `_posts/` named `YYYY-MM-DD-slug.md`:

```yaml
---
layout: kaizenly-post
title: "Under 60 characters, keyword first"
description: "One or two sentences — this is the search snippet."
---
```

Posts publish to `/blog/<slug>/` and get `BlogPosting` structured data, an `article` Open Graph
type and a reading time automatically. The body is plain Markdown — the `.prose` block in
`assets/css/kaizenly.css` typesets the bare `h2`/`p`/`ul`/`blockquote`/`pre`/`table` kramdown emits,
so a post never carries layout classes of its own.

`blog.html` is the index and is `published: false` until the first real post exists — an index
listing nothing is a thin page competing for crawl attention. Delete that line to switch it on.

`_posts/2026-08-17-kitchen-sink.md` is a fixture, not content. It contains every element Markdown
can produce and is `published: false`; flip it to `true` to re-run the responsive audit against a
realistic post, then flip it back.

**Pagination**, when there are enough posts to need it: `jekyll-paginate` is on GitHub Pages'
allowlist, but under Jekyll 3 it can only paginate a file named `index.html`. Below roughly forty
posts a single list is fine and faster to read. Past that, move the index to `/blog/index.html` and
switch the plugin on, or split by tag.

## Adding a page

Front matter, then plain HTML. No Markdown needed, no layout boilerplate:

```yaml
---
layout: kaizenly
permalink: /some-page/
title: "Under 60 characters, keyword first"
description: "One or two sentences. This is the search snippet, so write it for a human."
---
```

`_layouts/kaizenly.html` supplies the head — title, description, canonical, Open Graph, Twitter
card — all from that front matter. `assets/css/kaizenly.css` holds every style the product pages
use. New pages land in `sitemap.xml` automatically.

Install links go through the include, never hand-written:

```liquid
{% include play-button.html campaign="some-page" %}
```

The `campaign` becomes a `utm_campaign` on the Play URL, which is the only way Play Console can tell
which page actually produced an install. A hand-written link throws that away.

## Theme leftovers

This started as the [Space Jekyll](https://github.com/victorvoid/space-jekyll-template) blog
template and a lot of it is still on disk. The blog machinery — `about.html`, `posts.html`,
`series.html`, `tags.html`, `search.json`, `feed.xml` — is listed under `exclude:` in `_config.yml`
so Jekyll doesn't build it. Each one it built was another thin URL competing with the real pages.
Delete a line from `exclude:` to bring one back.

Still live but unused by the product pages: `_layouts/default.html`, `_layouts/post.html`,
`_includes/head.html` (its favicon paths point at a directory that doesn't exist),
`assets/css/main.css`, and the Gulp/Stylus pipeline in `src/` with `gulpfile.js`. Left in place
rather than deleted, so the theme pages still work if any are ever re-enabled.

## Things worth knowing before changing something

- **Don't put a payment flow or a web version of the app on this domain.** GitHub Pages' terms
  forbid using it for a site "primarily directed at either facilitating commercial transactions or
  providing commercial software as a service". A marketing page linking to Play is fine; a
  subscription checkout is the line. Move hosting *before* that ships.
- **Google Pages can't do server-side 301s.** Changing a published URL means it just breaks unless
  you add `jekyll-redirect-from`, which only manages a meta refresh. Pick permalinks you can live
  with.
- **Only allowlisted Jekyll plugins run** unless the build moves to GitHub Actions. `jekyll-polyglot`
  is not on the list, so multi-language would mean manual `/vi/` folders plus hreflang.
- **`CNAME` must stay.** Deleting it drops the custom domain and sends everything back to
  `morejump.github.io`.

## Credits and licence

Built on [Space Jekyll](https://github.com/victorvoid/space-jekyll-template) by Victor Igor, MIT
licensed — see [LICENSE](LICENSE). The layouts, includes, `assets/css/main.css` and `src/` are still
his work. Kaizenly's own pages, `_layouts/kaizenly.html` and `assets/css/kaizenly.css` are not.
