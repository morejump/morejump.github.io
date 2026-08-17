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
