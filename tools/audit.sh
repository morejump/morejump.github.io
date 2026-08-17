#!/usr/bin/env bash
# Responsive audit. Builds the site, loads every page in an iframe at thirteen
# widths from 320 to 1920, and fails on two things a screenshot review misses:
#
#   1. horizontal overflow — any element escaping the viewport, which on a phone
#      means the whole page can be dragged sideways
#   2. distorted images — rendered aspect ratio not matching the file's own
#
# Both have shipped here before. Run it after any layout change.
#
#   ./tools/audit.sh
#
# Needs Chrome and the pinned Jekyll from the README.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

CHROME="${CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
[ -x "$CHROME" ] || { echo "Chrome not found. Set CHROME_BIN."; exit 1; }

export GEM_HOME="${GEM_HOME:-$HOME/.gem-jekyll}"
export PATH="$GEM_HOME/bin:$PATH"

echo "Building…"
(cd "$ROOT" && jekyll build --quiet)
cp -R "$ROOT/_site" "$WORK/site"

# The built pages use absolute https:// URLs. An iframe pointed at the live origin
# is cross-origin and its document cannot be read, so rewrite to relative paths.
python3 - "$WORK/site" <<'PY'
import os, sys
root = sys.argv[1]
for dirpath, _, files in os.walk(root):
    for f in files:
        if not f.endswith('.html'):
            continue
        p = os.path.join(dirpath, f)
        rel = os.path.relpath(dirpath, root)
        up = '../' * len(rel.split(os.sep)) if rel != '.' else './'
        s = open(p, encoding='utf-8').read()
        open(p, 'w', encoding='utf-8').write(s.replace('https://getkaizenly.com/', up))
PY

# Every built page, so a page added later is covered without editing this script.
python3 - "$WORK/site" > "$WORK/site/_audit.html" <<'PY'
import os, sys, json
root = sys.argv[1]
pages = sorted(
    os.path.relpath(os.path.join(d, f), root)
    for d, _, fs in os.walk(root) for f in fs
    if f.endswith('.html') and not f.startswith('_') and not f.startswith('google')
)
print('''<!doctype html><meta charset=utf-8><body><pre id=out>running…</pre><script>
const PAGES=''' + json.dumps(pages) + ''';
const WIDTHS=[320,360,390,412,480,600,768,860,900,1024,1280,1440,1920];
const out=document.getElementById('out'), fails=[]; let n=0;
function check(page,w){return new Promise(res=>{
  const f=document.createElement('iframe');
  f.style.cssText=`width:${w}px;height:900px;border:0;position:absolute;left:-9999px`;
  f.src=page; document.body.appendChild(f);
  f.onload=()=>setTimeout(()=>{
    try{
      const d=f.contentDocument, de=d.documentElement, W=de.clientWidth, win=f.contentWindow;
      if(de.scrollWidth>W+0.5){
        const bad=[];
        d.querySelectorAll('body *').forEach(e=>{
          const r=e.getBoundingClientRect(); if(!r.width&&!r.height) return;
          if(r.right>W+0.5||r.left<-0.5){
            const cs=win.getComputedStyle(e);
            if(cs.overflowX==='auto'||cs.overflowX==='scroll') return;
            let p=e.parentElement;
            while(p){const pc=win.getComputedStyle(p);
              if(pc.overflowX==='auto'||pc.overflowX==='scroll') return; p=p.parentElement;}
            bad.push(e.tagName+(e.className?'.'+String(e.className).split(' ')[0]:''));
          }});
        fails.push(`OVERFLOW ${page} @${w}px  viewport=${W} content=${de.scrollWidth}  ${[...new Set(bad)].slice(0,3).join(', ')}`);
      }
      d.querySelectorAll('img').forEach(i=>{
        if(!i.naturalWidth||!i.complete) return;
        const r=i.getBoundingClientRect(); if(!r.width||!r.height) return;
        const drawn=r.width/r.height, real=i.naturalWidth/i.naturalHeight;
        const fit=win.getComputedStyle(i).objectFit;
        if(fit!=='cover'&&fit!=='contain'&&Math.abs(drawn-real)/real>0.02)
          fails.push(`DISTORTED ${page} @${w}px  ${i.getAttribute('src').split('/').pop()}`
            +`  drawn=${r.width.toFixed(0)}x${r.height.toFixed(0)} (${drawn.toFixed(3)})`
            +` file=${i.naturalWidth}x${i.naturalHeight} (${real.toFixed(3)})`);
      });
    }catch(e){fails.push(`ERROR ${page} @${w}px  ${e}`);}
    n++; f.remove(); res();
  },140);});}
(async()=>{
  for(const p of PAGES) for(const w of WIDTHS) await check(p,w);
  const seen=[...new Set(fails)];
  out.textContent=(seen.length?'FAIL':'PASS')+`  ${n} combos (${PAGES.length} pages x ${WIDTHS.length} widths)\\n`
    +(seen.length?seen.map(s=>'  '+s).join('\\n'):'  no overflow, no distorted images');
  document.title='DONE';
})();
</script>''')
PY

echo "Auditing…"
RESULT=$("$CHROME" --headless=new --disable-gpu --allow-file-access-from-files \
  --virtual-time-budget=90000 --dump-dom "file://$WORK/site/_audit.html" 2>/dev/null \
  | python3 -c "
import sys, re, html
t = sys.stdin.read()
m = re.search(r'<pre id=\"out\">(.*?)</pre>', t, re.S)
print(html.unescape(m.group(1)) if m else t[:1000])")

echo "$RESULT"
case "$RESULT" in FAIL*) exit 1 ;; esac
