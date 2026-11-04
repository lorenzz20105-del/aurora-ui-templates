/* Layout sanity for the generated previews.
 *
 * The engine positions every node absolutely from the dump's offsets. A stray
 * `position: relative` on any node re-flows it and shoves whole clusters
 * diagonally, which is invisible to an error console and only shows up in a
 * screenshot. This walks every rendered style and asserts the geometry.
 */
const { chromium } = require('playwright');
const path = require('path');

const STYLES = ['midnight','daylight','neon-grid','terminal','brutalist','frost','material','arcade','executive','solar'];

/* The gallery picks a template from location.hash, and `mount`/`STYLES` are
   top-level consts so they are not reachable from page.evaluate. */
async function inspect(page, file, slug) {
  await page.goto('file://' + file + (slug ? '#' + slug : ''), { waitUntil: 'load' });
  await page.waitForTimeout(900);
  return page.evaluate((slug) => {
    const problems = [];
    const stage = document.querySelector('.stage');
    const win = stage.querySelector('[data-name="Main"]') || stage.firstElementChild;
    if (!win) return { slug, problems: ['no window node'], nodes: 0 };
    const nodes = Array.from(win.querySelectorAll('.n'));
    const box = win.getBoundingClientRect();

    // 1. every node must be absolutely positioned
    for (const n of nodes) {
      const pos = getComputedStyle(n).position;
      if (pos !== 'absolute') problems.push(`position:${pos} on ${n.dataset.name || n.className}`);
    }

    // 2. sibling overlap inside the title bar (the classic re-flow symptom)
    const tb = win.querySelector('[data-name="TitleBar"]');
    if (tb) {
      const kids = Array.from(tb.querySelectorAll(':scope > .n')).map(k => [k.dataset.name, k.getBoundingClientRect()])
        .filter(([, r]) => r.width > 4 && r.height > 4);
      for (let i = 0; i < kids.length; i++) for (let j = i + 1; j < kids.length; j++) {
        const [an, a] = kids[i], [bn, b] = kids[j];
        const ox = Math.min(a.right, b.right) - Math.max(a.left, b.left);
        const oy = Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top);
        if (ox > 2 && oy > 2) {
          if (an === 'Title' && bn === 'Subtitle') continue; // stacked by design in some styles
          problems.push(`titlebar overlap ${an} / ${bn} (${Math.round(ox)}x${Math.round(oy)}px)`);
        }
      }
      // and they must all sit on the title bar's line
      for (const [n, r] of kids) {
        if (r.top > tb.getBoundingClientRect().bottom + 2) problems.push(`titlebar child ${n} below the bar`);
      }
    }

    // 3. nothing may sit outside the window by more than a hair
    for (const n of nodes) {
      const r = n.getBoundingClientRect();
      if (r.width < 2 || r.height < 2) continue;
      const outR = r.right - box.right, outL = box.left - r.left, outB = r.bottom - box.bottom;
      if (outR > 4) problems.push(`${n.dataset.name || '?'} overflows right by ${Math.round(outR)}px`);
      if (outL > 4) problems.push(`${n.dataset.name || '?'} overflows left by ${Math.round(outL)}px`);
      if (outB > 40) problems.push(`${n.dataset.name || '?'} overflows bottom by ${Math.round(outB)}px`);
    }
    return { slug, problems, nodes: nodes.length };
  }, slug || null);
}

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
  let bad = 0;
  const gallery = path.resolve(__dirname, '../docs/index.html');
  for (const slug of STYLES) {
    const r = await inspect(page, gallery, slug);
    const tag = r.problems.length ? 'FAIL' : ' ok ';
    console.log(`[${tag}] ${slug.padEnd(9)} ${String(r.nodes).padStart(4)} nodes`);
    for (const p of r.problems.slice(0, 6)) console.log('        ' + p);
    if (r.problems.length) bad++;
  }
  const single = await inspect(page, path.resolve(__dirname, '../docs/real-ui.html'), null);
  console.log(`[${single.problems.length ? 'FAIL' : ' ok '}] real-ui   ${single.nodes} nodes`);
  for (const p of single.problems.slice(0, 6)) console.log('        ' + p);
  if (single.problems.length) bad++;
  await browser.close();
  if (bad) { console.error(`\n${bad} view(s) with geometry problems`); process.exit(1); }
  console.log('\ngeometry ok in every view');
})();
