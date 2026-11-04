/* ------------------------------------------------------------------
   Aurora UI — layout engine.

   Takes the JSON produced by tools/dump.py (a serialised Roblox GUI
   tree) and lays it out in the DOM: automatic sizing, list/grid
   layout, padding, anchors, rotation, gradients, strokes, text.

   Used by both docs/real-ui.html (one window) and docs/index.html
   (the gallery: ten windows, one at a time).
   ------------------------------------------------------------------ */
function mountAuroraWindow(data, stage, options) {
  options = options || {};

/* ---------------------------------------------------------------- fonts */
const FONT_STACK = 'system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif';
const MONO_STACK = 'ui-monospace, SFMono-Regular, Menlo, Consolas, monospace';

const canvas = document.createElement('canvas');
const ctx = canvas.getContext('2d');

function fontOf(node) {
  const size = node.TextSize || 14;
  const name = String(node.Font || 'Gotham');
  let weight = 500;
  if (/Black/.test(name)) weight = 800;
  else if (/Bold/.test(name)) weight = 700;
  else if (/Semi/.test(name)) weight = 600;
  else if (/Medium/.test(name)) weight = 500;
  const family = /Code/.test(name) ? MONO_STACK : FONT_STACK;
  return { size, weight, family, css: weight + ' ' + size + 'px ' + family };
}

function lineHeight(size) {
  return Math.round(size * 1.2 * 100) / 100;
}

function wrapLines(text, maxWidth, font) {
  ctx.font = font.css;
  const lines = [];
  String(text).split('\n').forEach((paragraph) => {
    if (!maxWidth || maxWidth <= 0) {
      lines.push(paragraph);
      return;
    }
    let line = '';
    paragraph.split(' ').forEach((word) => {
      const candidate = line ? line + ' ' + word : word;
      if (!line || ctx.measureText(candidate).width <= maxWidth) {
        line = candidate;
      } else {
        lines.push(line);
        line = word;
      }
    });
    lines.push(line);
  });
  return lines.length ? lines : [''];
}

/* ------------------------------------------------------------- geometry */
function udim2(value) {
  return value || { x: [0, 0], y: [0, 0] };
}

function resolveUdim(pair, base) {
  if (!pair) return 0;
  return pair[0] * base + pair[1];
}

function resolvePadding(node, width, height) {
  const pad = node.padding;
  if (!pad) return { t: 0, r: 0, b: 0, l: 0 };
  return {
    t: resolveUdim(pad.t, height),
    r: resolveUdim(pad.r, width),
    b: resolveUdim(pad.b, height),
    l: resolveUdim(pad.l, width),
  };
}

function autoFlags(node) {
  const value = node.AutomaticSize || '';
  return { x: value.indexOf('X') >= 0, y: value.indexOf('Y') >= 0 };
}

function textLines(node, width) {
  const font = fontOf(node);
  return wrapLines(node.Text || '', width, font);
}

/* -------------------------------------------------------------- measure */
function measure(node, availW, availH) {
  const size = udim2(node.Size);
  let w = size.x[0] * availW + size.x[1];
  let h = size.y[0] * availH + size.y[1];
  const auto = autoFlags(node);

  const pad = resolvePadding(node, w, h);
  const innerW = Math.max(0, w - pad.l - pad.r);
  const innerH = Math.max(0, h - pad.t - pad.b);

  const isText = node.Text !== null && node.Text !== undefined;
  if (isText && auto.x && !node.TextWrapped) {
    const font = fontOf(node);
    ctx.font = font.css;
    w = Math.max(w, ctx.measureText(String(node.Text)).width + pad.l + pad.r);
  }
  if (isText && auto.y) {
    const font = fontOf(node);
    const lines = wrapLines(node.Text, node.TextWrapped ? Math.max(1, innerW || w) : 0, font);
    h = Math.max(lineHeight(font.size), lines.length * lineHeight(font.size)) + pad.t + pad.b;
  }

  const children = node.children || [];
  node._children = children.map((child, index) => ({ node: child, index }));

  if (node.grid) {
    // UIGridLayout decides the size of every cell
    const cell = udim2(node.grid.cellSize);
    const cellPad = udim2(node.grid.padding);
    const cellW = cell.x[0] * innerW + cell.x[1];
    const cellH = cell.y[0] * innerH + cell.y[1];
    const padX = cellPad.x[0] * innerW + cellPad.x[1];
    const padY = cellPad.y[0] * innerH + cellPad.y[1];
    const columns = Math.max(1, Math.floor((innerW + padX) / Math.max(1, cellW + padX)));
    const rows = Math.ceil(node._children.length / columns);

    node._children.forEach((entry) => {
      measure(entry.node, cellW, cellH);
      entry.node._w = cellW;
      entry.node._h = cellH;
      entry.node._pad = resolvePadding(entry.node, cellW, cellH);
    });

    node._grid = { cellW, cellH, padX, padY, columns, rows };
    if (auto.y) h = Math.max(h, rows * cellH + Math.max(0, rows - 1) * padY + pad.t + pad.b);
    if (auto.x) w = Math.max(w, columns * cellW + Math.max(0, columns - 1) * padX + pad.l + pad.r);
  } else if (node.list) {
    const horizontal = node.list.direction === 'Horizontal';
    const gap = resolveUdim(node.list.padding, horizontal ? w : h);
    let main = 0;
    let cross = 0;
    node._children.forEach((entry) => {
      measure(entry.node, horizontal ? innerW : innerW, horizontal ? innerH : innerH);
      const childW = entry.node._w;
      const childH = entry.node._h;
      entry.size = horizontal ? childW : childH;
      entry.cross = horizontal ? childH : childW;
      main += entry.size;
      cross = Math.max(cross, entry.cross);
    });
    if (node._children.length > 1) main += gap * (node._children.length - 1);

    // UIFlexItem(Fill) children absorb the leftover space
    const flexChildren = node._children.filter((entry) => entry.node.flex === 'Fill');
    if (flexChildren.length) {
      const available = (horizontal ? innerW : innerH) - main;
      if (available > 0) {
        const share = available / flexChildren.length;
        flexChildren.forEach((entry) => {
          if (horizontal) {
            entry.node._w += share;
          } else {
            entry.node._h += share;
          }
          entry.size += share;
        });
        main += available;
      }
    }

    if (horizontal && auto.x) w = main + pad.l + pad.r;
    if (!horizontal && auto.y) h = main + pad.t + pad.b;
    if (horizontal && auto.y) h = Math.max(h, cross + pad.t + pad.b);
    if (!horizontal && auto.x) w = Math.max(w, cross + pad.l + pad.r);
    node._mainSize = main;
    node._gap = gap;
  } else {
    node._children.forEach((entry) => {
      measure(entry.node, innerW, innerH);
    });

    // Roblox sizes AutomaticSize containers to the bounding box of their
    // freely-positioned children, so mirror that here.
    if ((auto.x || auto.y) && node._children.length) {
      let maxX = 0;
      let maxY = 0;
      node._children.forEach((entry) => {
        const child = entry.node;
        const position = udim2(child.Position);
        const anchor = child.AnchorPoint || [0, 0];
        const offsetX = position.x[0] * innerW + position.x[1];
        const offsetY = position.y[0] * innerH + position.y[1];
        maxX = Math.max(maxX, offsetX + child._w * (1 - anchor[0]));
        maxY = Math.max(maxY, offsetY + child._h * (1 - anchor[1]));
      });
      if (auto.x) w = Math.max(w, maxX + pad.l + pad.r);
      if (auto.y) h = Math.max(h, maxY + pad.t + pad.b);
    }
  }

  node._w = Math.max(0, w);
  node._h = Math.max(0, h);
  node._pad = resolvePadding(node, node._w, node._h);
  return node;
}

/* ---------------------------------------------------------------- place */
function place(node, x, y) {
  node._x = x;
  node._y = y;
  const pad = node._pad || { t: 0, r: 0, b: 0, l: 0 };
  const innerW = Math.max(0, node._w - pad.l - pad.r);
  const innerH = Math.max(0, node._h - pad.t - pad.b);

  let contentBottom = 0;
  let contentRight = 0;

  if (node.grid && node._grid && node._children) {
    const { cellW, cellH, padX, padY, columns } = node._grid;
    node._children.forEach((entry, index) => {
      const column = index % columns;
      const row = Math.floor(index / columns);
      place(
        entry.node,
        node._x + pad.l + column * (cellW + padX),
        node._y + pad.t + row * (cellH + padY)
      );
      contentBottom = Math.max(contentBottom, pad.t + (row + 1) * cellH + row * padY);
    });
  } else if (node.list && node._children) {
    const horizontal = node.list.direction === 'Horizontal';
    const gap = node._gap || 0;
    const total = node._mainSize || 0;
    const crossSpace = horizontal ? innerH : innerW;

    let cursor = horizontal ? pad.l : pad.t;
    if (horizontal) {
      const align = node.list.vAlign || 'Top';
      if (align === 'Center') cursor += (crossSpace - (node._children.reduce((m, e) => Math.max(m, e.cross), 0))) / 2;
      if (align === 'Bottom') cursor += crossSpace - (node._children.reduce((m, e) => Math.max(m, e.cross), 0));
    } else {
      const align = node.list.hAlign || 'Left';
      if (align === 'Center') cursor += (crossSpace - (node._children.reduce((m, e) => Math.max(m, e.cross), 0))) / 2;
      if (align === 'Right') cursor += crossSpace - (node._children.reduce((m, e) => Math.max(m, e.cross), 0));
    }

    node._children.forEach((entry) => {
      if (horizontal) {
        place(entry.node, node._x + cursor, node._y + pad.t);
        cursor += entry.node._w + gap;
        contentRight = cursor - gap - pad.l;
        contentBottom = Math.max(contentBottom, entry.node._h);
      } else {
        // vertical: the cursor is the running y inside the padding box
        place(entry.node, node._x + cursorX(node, entry, pad, innerW), node._y + cursor);
        cursor += entry.node._h + gap;
        contentBottom = cursor - gap - pad.t;
      }
    });
  } else if (node._children) {
    node._children.forEach((entry) => {
      const child = entry.node;
      const position = udim2(child.Position);
      const anchor = child.AnchorPoint || [0, 0];
      const offsetX = position.x[0] * innerW + position.x[1];
      const offsetY = position.y[0] * innerH + position.y[1];
      place(child, node._x + pad.l + offsetX - child._w * anchor[0], node._y + pad.t + offsetY - child._h * anchor[1]);
      contentRight = Math.max(contentRight, offsetX + child._w);
      contentBottom = Math.max(contentBottom, offsetY + child._h);
    });
  }

  node._contentBottom = contentBottom;
  node._contentRight = contentRight;
}

function cursorX(node, entry, pad, innerW) {
  const align = (node.list && node.list.hAlign) || 'Left';
  const childW = entry.node._w;
  if (align === 'Center') return pad.l + (innerW - childW) / 2;
  if (align === 'Right') return pad.l + innerW - childW;
  return pad.l;
}

/* ---------------------------------------------------------------- paint */
function rgba(value, alpha) {
  if (!value) return 'transparent';
  const parts = String(value).split(',');
  return 'rgba(' + parts[0] + ',' + parts[1] + ',' + parts[2] + ',' + alpha + ')';
}

function sampleTransparency(points, time) {
  if (!points || !points.length) return 0;
  if (time <= points[0][0]) return points[0][1];
  for (let index = 1; index < points.length; index += 1) {
    const [t1, v1] = points[index];
    const [t0, v0] = points[index - 1];
    if (time <= t1) {
      const span = t1 - t0 || 1;
      return v0 + (v1 - v0) * ((time - t0) / span);
    }
  }
  return points[points.length - 1][1];
}

function gradientCss(gradient, alpha) {
  if (!gradient || !gradient.colors || !gradient.colors.length) return null;
  const stops = gradient.colors.map((stop) => {
    const fade = sampleTransparency(gradient.transparency, stop[0]);
    const value = Math.max(0, alpha * (1 - fade));
    const colour = 'rgba(' + stop[1] + ',' + stop[2] + ',' + stop[3] + ',' + value.toFixed(3) + ')';
    return colour + ' ' + Math.round(stop[0] * 1000) / 10 + '%';
  });
  const angle = 90 + (gradient.rotation || 0);
  return 'linear-gradient(' + angle + 'deg, ' + stops.join(', ') + ')';
}

function styleOf(node, originX, originY) {
  const w = node._w;
  const h = node._h;
  const style = [];
  // children are nested in the DOM, so their box is relative to the parent
  style.push('left:' + (node._x - originX).toFixed(2) + 'px');
  style.push('top:' + (node._y - originY).toFixed(2) + 'px');
  style.push('width:' + w.toFixed(2) + 'px');
  style.push('height:' + h.toFixed(2) + 'px');
  style.push('z-index:' + (node.ZIndex || 1));

  const transparency = node.BackgroundTransparency === undefined ? 1 : node.BackgroundTransparency;
  const alpha = 1 - transparency;
  let background = null;
  if (node.gradient) background = gradientCss(node.gradient, Math.max(alpha, 0));
  if (!background && alpha > 0.001) background = rgba(node.BackgroundColor3, alpha);
  if (background) style.push('background:' + background);

  const radius = node.radius;
  if (radius) {
    const value = Math.min(w, h) * radius[0] + radius[1];
    if (value > 0) style.push('border-radius:' + Math.min(value, Math.min(w, h) / 2).toFixed(2) + 'px');
  }

  const stroke = node.stroke;
  if (stroke && stroke.color && stroke.thickness > 0) {
    const strokeAlpha = 1 - (stroke.transparency || 0);
    if (strokeAlpha > 0.001) {
      style.push('box-shadow:inset 0 0 0 ' + stroke.thickness + 'px ' + rgba(stroke.color, strokeAlpha));
    }
  }

  if (node.ClipsDescendants) style.push('overflow:hidden');
  if (node.Rotation) style.push('transform:rotate(' + node.Rotation + 'deg)');
  if (node.Visible === false) style.push('display:none');

  if (node.Text !== null && node.Text !== undefined) {
    const font = fontOf(node);
    style.push('font:' + font.css);
    style.push('color:' + rgba(node.TextColor3 || '255,255,255', 1 - (node.TextTransparency || 0)));
    style.push('line-height:' + lineHeight(font.size) + 'px');
    style.push('align-items:' + alignY(node.TextYAlignment));
    style.push('justify-content:' + alignX(node.TextXAlignment));
    if (node.TextWrapped) style.push('white-space:pre-wrap', 'word-break:break-word');
    else if (node.TextTruncate && node.TextTruncate !== 'None') style.push('white-space:nowrap');
  }

  return style.join(';');
}

function alignX(value) {
  if (value === 'Center') return 'center';
  if (value === 'Right') return 'flex-end';
  return 'flex-start';
}

function alignY(value) {
  if (value === 'Center') return 'center';
  if (value === 'Bottom') return 'flex-end';
  return 'flex-start';
}

/* ----------------------------------------------------------------- tree */
// stage is supplied by the caller
const pages = {};
const tabs = [];

function render(node, parentElement, parentNode) {
  const element = document.createElement('div');
  element.className = 'n';
  if (node.Text !== null && node.Text !== undefined) element.classList.add('text');
  if (node.TextTruncate && node.TextTruncate !== 'None' && !node.TextWrapped) element.classList.add('nowrap');
  if (node.class === 'ScrollingFrame') element.classList.add('scroller');
  element.style.cssText = styleOf(node, parentNode ? parentNode._x : 0, parentNode ? parentNode._y : 0);
  if (node.Name) element.dataset.name = node.Name;

  if (node.Text !== null && node.Text !== undefined) {
    element.textContent = node.Text;
    if (node.class === 'TextBox' && !node.Text && node.PlaceholderText) {
      // an empty TextBox shows its placeholder, not its (empty) value
      element.textContent = node.PlaceholderText;
      if (node.PlaceholderColor3) element.style.color = rgba(node.PlaceholderColor3, 1 - (node.TextTransparency || 0));
    }
  }

  const pageHit = /^Page_(.+)$/.exec(node.Name || '');
  if (pageHit) {
    pages[pageHit[1]] = element;
    element.dataset.page = pageHit[1];
  }

  if (node.Text === null || node.Text === undefined) {
    (node._children || []).forEach((entry) => render(entry.node, element, node));
  }

  if (node.class === 'ScrollingFrame' && node._contentBottom > 0) {
    const spacer = document.createElement('div');
    spacer.className = 'spacer';
    spacer.style.top = '0px';
    spacer.style.height = node._contentBottom + 'px';
    element.appendChild(spacer);
  }

  parentElement.appendChild(element);

  const tabMatch = /^Tab_(.+)$/.exec(node.Name || '');
  if (tabMatch) {
    element.dataset.tab = tabMatch[1];
    tabs.push(element);
  }

  return element;
}

const root = data.window;
measure(root, 900, 580);
place(root, 0, 0);
render(root, stage, null);

/* ------------------------------------------------------------- motion
   Every style ships a motion profile with its dump. The preview replays
   it in CSS: the same entrance, the same hover, the same idle loop the
   Luau runs through TweenService -- so the page moves like the game
   does, no screenshots involved. */
const META = data.meta || {};
const MOTION = META.motion || {};
const LAYOUT = META.layout || {};

function motionCss() {
  const entry = MOTION.Entry || 'rise';
  const seconds = MOTION.Duration || 0.3;
  const stagger = MOTION.Stagger || 0.03;
  const easing = MOTION.Easing || 'Quint';
  return { entry, seconds, stagger, easing };
}

function animateEntrance() {
  const { entry, seconds, stagger } = motionCss();
  // Only the chrome and the cards enter. Animating every leaf would both
  // flicker and push the tail of the queue seconds into the future.
  const pattern = /^(Main|TitleBar|TabBar|Sidebar|Dock|Footer|Section_.+|Tab_.+|Stat.*|Grid|Content)$/;
  const queue = [];
  stage.querySelectorAll('[data-name]').forEach((el) => {
    if (pattern.test(el.dataset.name || '')) queue.push(el);
  });
  queue.forEach((el, index) => {
    const delay = Math.min(index * stagger, 0.55);
    el.classList.add('motion-entry', 'entry-' + entry);
    el.style.animationDuration = seconds + 's';
    el.style.animationTimingFunction = 'cubic-bezier(.22,.9,.28,1)';
    el.style.animationDelay = delay.toFixed(3) + 's';
  });
}

function animateHover() {
  const kind = MOTION.Hover || 'lift';
  if (kind === 'none') return;
  stage.querySelectorAll('[data-name]').forEach((el) => {
    const name = el.dataset.name || '';
    if (/^Tab_|^Stat|^Button|^Quick|^Row|^Section_/.test(name)) {
      el.classList.add('motion-hover', 'hover-' + kind);
    }
  });
}

function animateIdle() {
  const kind = MOTION.Idle || 'none';
  if (kind === 'none') return;
  const targets = {
    shimmer: ['Logo', 'DockAccent', 'Title'],
    pulse: ['Indicator', 'Live', 'Dot'],
    blink: ['Live', 'Dot', 'Badge'],
    scan: ['Main', 'Page_Home'],
  }[kind] || [];
  stage.querySelectorAll('[data-name]').forEach((el) => {
    if (targets.indexOf(el.dataset.name) >= 0) el.classList.add('motion-idle', 'idle-' + kind);
  });
}

// the accent of the active style drives the glow hover + decor
if (META.accent) stage.style.setProperty('--aurora-accent', META.accent);
if (META.accent2) stage.style.setProperty('--aurora-accent2', META.accent2);
if (META.accent) stage.style.setProperty('--aurora-accent-soft', META.accent + '38');
if (META.accent2) stage.style.setProperty('--aurora-accent2-soft', META.accent2 + '30');

if (LAYOUT.Decor && LAYOUT.Decor !== 'none') {
  const decor = document.createElement('div');
  decor.className = 'decor decor-' + LAYOUT.Decor;
  decor.setAttribute('aria-hidden', 'true');
  stage.appendChild(decor);
}
animateEntrance();
animateHover();
animateIdle();

// exposed for tools/debug + the CI smoke check
const report = (limit) => {
  const rows = [];
  const walk = (node, depth) => {
    if (rows.length >= (limit || 80)) return;
    rows.push({
      depth,
      name: node.Name || node.class,
      cls: node.class,
      x: Math.round(node._x || 0),
      y: Math.round(node._y || 0),
      w: Math.round(node._w || 0),
      h: Math.round(node._h || 0),
      auto: node.AutomaticSize || 'None',
      list: node.list ? node.list.direction : '',
    });
    (node._children || []).forEach((entry) => walk(entry.node, depth + 1));
  };
  walk(root, 0);
  return rows;
};

/* ------------------------------------------------------- tab switching */
// The dump captures one tab in its active state and the rest in their idle
// state, so the two looks can be swapped around without re-running Luau.
const snapshot = (el) => (el ? { background: el.style.background, boxShadow: el.style.boxShadow, color: el.style.color } : null);
const activeTab = tabs.find((tab) => tab.style.background && tab.style.background.indexOf('rgba(') === -1);
const idleTab = tabs.find((tab) => tab !== activeTab && tab.style.background);
const activeStyle = snapshot(activeTab);
const idleStyle = snapshot(idleTab);

const indicator = stage.querySelector('[data-name="Indicator"]');
const indicatorBase = indicator ? indicator.offsetTop : 0;

function selectTab(name) {
  Object.keys(pages).forEach((key) => {
    const page = pages[key];
    const showing = key === name;
    page.style.display = showing ? '' : 'none';
    if (showing) {
      page.classList.remove('page-in');
      // restart the entrance so switching tabs feels like the style it is
      void page.offsetWidth;
      page.classList.add('page-in');
    }
  });
  tabs.forEach((tab) => {
    if (!idleStyle) return;
    tab.style.background = idleStyle.background || '';
    tab.style.boxShadow = idleStyle.boxShadow || '';
    tab.style.color = idleStyle.color || '';
  });
  const target = tabs.find((tab) => tab.dataset.tab === name);
  if (target && activeStyle) {
    target.style.background = activeStyle.background || '';
    target.style.boxShadow = activeStyle.boxShadow || '';
    target.style.color = activeStyle.color || '';
  }
  if (indicator && target && tabs[0]) {
    indicator.style.top = (indicatorBase + (target.offsetTop - tabs[0].offsetTop)) + 'px';
  }
}

tabs.forEach((tab) => {
  tab.addEventListener('click', () => selectTab(tab.dataset.tab));
});
selectTab(activeTab ? activeTab.dataset.tab : Object.keys(pages)[0]);

/* ---------------------------------------------------------- interactive
   The dump is a snapshot of a real, working menu. These handlers hand the
   behaviour back: switches flip, sliders drag, sections collapse, buttons
   toast, the search filters the rows, the title bar drags the window. */

const PALETTE = {
  accent: (META.accent || '#7C5CFF'),
  accent2: (META.accent2 || META.accent || '#22D3EE'),
  panel: (META.panel || '#0F121B'),
  surface: (META.surface || '#161A26'),
  text: (META.text || '#EAEEF9'),
  stroke: (META.stroke || '#252C3E'),
};

function withAlpha(hex, alpha) {
  const value = String(hex).replace('#', '');
  const big = parseInt(value.length === 3 ? value.split('').map((c) => c + c).join('') : value, 16);
  return 'rgba(' + ((big >> 16) & 255) + ',' + ((big >> 8) & 255) + ',' + (big & 255) + ',' + alpha + ')';
}

function makeInteractive() {
  const win = stage.querySelector('[data-name="Main"]');
  if (!win) return;
  const nameOf = (el) => (el && el.dataset ? el.dataset.name || '' : '');
  const safe = (fn) => (event) => {
    try {
      fn(event);
    } catch (error) {
      /* one broken control must never take the preview down */
      console.warn('aurora interactive:', error);
    }
  };

  stage.classList.add('interactive');

  // Full-bleed helper frames (click blocker, modal overlay, notification
  // host, resize grip) sit above everything in Roblox but must not eat
  // pointer events in the preview.
  ['Blocker', 'Overlay', 'Notifications', 'Resizer'].forEach((name) => {
    stage.querySelectorAll('[data-name="' + name + '"]').forEach((el) => {
      el.style.pointerEvents = 'none';
    });
  });
  const resizer = stage.querySelector('[data-name="Resizer"]');
  if (resizer) resizer.style.pointerEvents = 'auto';

  /* ------------------------------------------------------------ toasts */
  let toastHost = stage.querySelector('.aurora-toasts');
  if (!toastHost) {
    toastHost = document.createElement('div');
    toastHost.className = 'aurora-toasts';
    stage.appendChild(toastHost);
  }

  function toast(title, body, tone) {
    const el = document.createElement('div');
    el.className = 'aurora-toast';
    const dot = document.createElement('span');
    dot.className = 'dot';
    dot.style.background = tone === 'warn' ? '#FBBF24' : PALETTE.accent;
    const wrapEl = document.createElement('div');
    const strong = document.createElement('b');
    strong.textContent = title;
    const p = document.createElement('span');
    p.textContent = body || '';
    wrapEl.appendChild(strong);
    if (body) wrapEl.appendChild(p);
    el.appendChild(dot);
    el.appendChild(wrapEl);
    toastHost.appendChild(el);
    setTimeout(() => {
      el.classList.add('out');
      setTimeout(() => el.remove(), 320);
    }, 2600);
    while (toastHost.children.length > 3) toastHost.firstChild.remove();
  }

  /* ---------------------------------------------------- window controls */
  const closeBtn = stage.querySelector('[data-name="IconButton_close"]');
  const minBtn = stage.querySelector('[data-name="IconButton_minus"]');
  const moonBtn = stage.querySelector('[data-name="IconButton_moon"]');
  const bellBtn = stage.querySelector('[data-name="IconButton_bell"]');
  const titleBar = stage.querySelector('[data-name="TitleBar"]');
  let reopen = null;

  if (closeBtn) {
    closeBtn.addEventListener('click', safe(() => {
      win.classList.add('is-closing');
      setTimeout(() => {
        win.style.display = 'none';
        win.classList.remove('is-closing');
        reopen = document.createElement('button');
        reopen.className = 'aurora-reopen';
        reopen.type = 'button';
        reopen.textContent = 'Reopen preview';
        reopen.addEventListener('click', () => {
          win.style.display = '';
          win.classList.add('motion-entry', 'entry-' + (MOTION.Entry || 'rise'));
          win.style.animationDuration = '0.32s';
          reopen.remove();
          reopen = null;
        });
        stage.appendChild(reopen);
      }, 220);
    }));
  }

  if (minBtn) {
    minBtn.addEventListener('click', safe(() => {
      win.classList.toggle('is-minimised');
    }));
  }

  if (bellBtn) {
    bellBtn.addEventListener('click', safe(() => {
      toast('Notifications', 'Everything is running smoothly.');
    }));
  }

  if (moonBtn) {
    moonBtn.addEventListener('click', safe(() => {
      if (typeof options.onCycleStyle === 'function') {
        options.onCycleStyle();
      } else {
        toast('Theme', 'Cycle templates from the chips above.');
      }
    }));
  }

  /* ------------------------------------------------------ title bar drag */
  // The stage is exactly the size of the window, so a free drag would clip.
  // The window shoves a little and springs back -- alive, never broken.
  if (titleBar) {
    let start = null;
    titleBar.style.cursor = 'grab';
    titleBar.addEventListener('pointerdown', (event) => {
      if (event.target.closest('[data-name^="IconButton"]') || event.target.closest('[data-name="Search"]')) return;
      start = { x: event.clientX, y: event.clientY };
      win.style.transition = 'none';
      titleBar.style.cursor = 'grabbing';
      try {
        titleBar.setPointerCapture(event.pointerId);
      } catch (error) {
        /* pointer capture is best effort */
      }
    });
    titleBar.addEventListener('pointermove', (event) => {
      if (!start) return;
      const k = scaleOfStage() || 1;
      const dx = Math.max(-26, Math.min(26, (event.clientX - start.x) / k));
      const dy = Math.max(-16, Math.min(16, (event.clientY - start.y) / k));
      win.style.transform = 'translate(' + dx.toFixed(1) + 'px,' + dy.toFixed(1) + 'px)';
    });
    const release = () => {
      if (!start) return;
      start = null;
      win.style.transition = 'transform .26s cubic-bezier(.3,1.3,.5,1)';
      win.style.transform = '';
      titleBar.style.cursor = 'grab';
    };
    titleBar.addEventListener('pointerup', release);
    titleBar.addEventListener('pointercancel', release);
  }

  function scaleOfStage() {
    const value = getComputedStyle(stage).transform;
    const match = /matrix\(([\d.]+)/.exec(value || '');
    return match ? parseFloat(match[1]) : 1;
  }

  /* ------------------------------------------------------------ switches */
  stage.querySelectorAll('[data-name="Track"]').forEach((track) => {
    const knob = track.querySelector('[data-name="Knob"]');
    if (!knob) return;
    const fill = track.querySelector('[data-name="Fill"]');

    if (fill) {
      /* -------------------------------------------------- slider */
      const pill = track.closest('[data-name^="Slider_"]') &&
        track.closest('[data-name^="Slider_"]').querySelector('[data-name="ValuePill"]');
      const label = pill ? pill.querySelector('[data-name="Value"]') : null;
      const original = label ? label.textContent : '';
      const current = parseFloat(original) || 0;
      const startFraction = (parseFloat(knob.style.left) || 0) / 100;
      const max = startFraction > 0.04 ? current / startFraction : current * 2 || 100;
      const unit = (original.match(/[a-z%]+$/i) || [''])[0];

      const apply = (event) => {
        const rect = track.getBoundingClientRect();
        const fraction = Math.max(0, Math.min(1, (event.clientX - rect.left) / Math.max(1, rect.width)));
        knob.style.left = fraction * 100 + '%';
        fill.style.width = fraction * 100 + '%';
        if (label) {
          const step = max > 40 ? 1 : 0.1;
          const value = Math.round(fraction * max / step) * step;
          label.textContent = (step < 1 ? value.toFixed(1) : String(Math.round(value))) + (unit ? ' ' + unit : '');
        }
      };

      track.style.cursor = 'pointer';
      track.classList.add('aurora-slider');
      track.addEventListener('pointerdown', (event) => {
        apply(event);
        track.setPointerCapture(event.pointerId);
        const move = (moveEvent) => apply(moveEvent);
        const up = () => {
          track.removeEventListener('pointermove', move);
          track.removeEventListener('pointerup', up);
        };
        track.addEventListener('pointermove', move);
        track.addEventListener('pointerup', up);
      });
      return;
    }

    /* ------------------------------------------------------ toggle */
    const row = track.closest('[data-name^="Row_"]') || track;
    const trackBg = track.style.background;
    const knobBg = knob.style.background;
    let on = (parseFloat(knob.style.left) || 0) > 0.01;

    const paint = () => {
      track.style.background = on ? PALETTE.accent : trackBg;
      knob.style.background = on ? '#FFFFFF' : knobBg;
      track.style.boxShadow = on ? '0 0 12px -2px ' + withAlpha(PALETTE.accent, 0.75) : '';
    };

    row.style.cursor = 'pointer';
    row.classList.add('aurora-toggle');
    row.addEventListener('click', safe((event) => {
      if (event.target.closest('[data-name="Track"]') || row === track || true) {
        on = !on;
        knob.style.left = on ? 'calc(100% - ' + (knob.offsetWidth || 20) + 'px)' : '0px';
        track.style.transition = 'background .18s ease, box-shadow .18s ease';
        knob.style.transition = 'left .18s cubic-bezier(.3,1.4,.5,1)';
        paint();
      }
    }));
  });

  /* ---------------------------------------------------- section collapse */
  stage.querySelectorAll('[data-name="CollapseHitbox"]').forEach((hit) => {
    hit.style.cursor = 'pointer';
    const header = hit.parentElement;
    const section = header && header.parentElement;
    if (!section) return;
    const body = section.querySelector('[data-name="Body"]');
    const chevron = header.querySelector('[data-name^="Icon_chevron"]');
    if (!body) return;
    hit.addEventListener('click', safe(() => {
      const collapsing = body.style.display !== 'none';
      body.style.display = collapsing ? 'none' : '';
      if (chevron) chevron.style.transform = collapsing ? 'rotate(-90deg)' : '';
      section.classList.toggle('is-collapsed', collapsing);
    }));
  });

  /* ------------------------------------------------------------- buttons */
  stage.querySelectorAll('[data-name="Sheen"]').forEach((sheen) => {
    const button = sheen.parentElement;
    if (!button) return;
    button.style.cursor = 'pointer';
    button.classList.add('aurora-button');
    button.addEventListener('click', safe(() => {
      const label = button.querySelector('[data-name="Label"], [data-name="Text"]');
      const title = label ? label.textContent : (nameOf(button) || 'Action');
      toast(title, 'Handled by the real component — this preview replays it.');
      button.classList.add('pressed');
      setTimeout(() => button.classList.remove('pressed'), 180);
    }));
  });

  /* ------------------------------------------------------------- search */
  const searchInput = stage.querySelector('[data-name="Field"]');
  const placeholderText = searchInput ? (searchInput.textContent || '') : '';
  if (searchInput) {
    searchInput.dataset.placeholder = placeholderText;
    searchInput.setAttribute('contenteditable', 'true');
    searchInput.classList.add('editable');
    searchInput.addEventListener('focus', () => {
      if (searchInput.textContent === placeholderText) searchInput.textContent = '';
      searchInput.classList.add('focused');
    });
    searchInput.addEventListener('blur', () => {
      searchInput.classList.remove('focused');
      if (!searchInput.textContent.trim()) searchInput.textContent = placeholderText;
      filterRows('');
    });
    searchInput.addEventListener('input', () => filterRows(searchInput.textContent));
    searchInput.addEventListener('keydown', (event) => {
      if (event.key === 'Enter') event.preventDefault();
    });
  }

  function filterRows(term) {
    const needle = (term || '').trim().toLowerCase();
    const page = Object.keys(pages).map((key) => pages[key]).find((p) => p.style.display !== 'none');
    if (!page) return;
    page.querySelectorAll('[data-name^="Row_"], [data-name^="Slider_"], [data-name^="Section_"]').forEach((el) => {
      const text = el.textContent.toLowerCase();
      const hit = !needle || text.indexOf(needle) >= 0;
      el.style.opacity = hit ? '' : '0.28';
      el.style.filter = hit ? '' : 'grayscale(1)';
    });
  }

  /* ------------------------------------------------------- color picker */
  const SWATCHES = ['#7C5CFF', '#22D3EE', '#FF2E97', '#34D399', '#FFB020', '#FB7185'];
  stage.querySelectorAll('[data-name="Trigger"]').forEach((trigger) => {
    const swatch = trigger.querySelector('[data-name="Swatch"]');
    const hex = trigger.querySelector('[data-name="Hex"]');
    if (!swatch || !hex) return;
    trigger.style.cursor = 'pointer';
    trigger.addEventListener('click', safe(() => {
      const now = hex.textContent.trim().toUpperCase();
      const next = SWATCHES[(Math.max(0, SWATCHES.indexOf(now)) + 1) % SWATCHES.length];
      hex.textContent = next;
      swatch.style.background = next;
      toast('Accent', next + ' applied to the swatch.');
    }));
  });

  /* ------------------------------------------------------------ dropdown */
  const DROPDOWN_OPTIONS = {
    'camera mode': ['First person', 'Third person', 'Classic'],
    'weather effects': ['Off', 'Fog', 'Rain', 'Snow'],
    'hud style': ['Compact', 'Standard', 'Detailed'],
  };

  stage.querySelectorAll('[data-name="Trigger"]').forEach((trigger) => {
    if (trigger.querySelector('[data-name="Swatch"]')) return; // colour picker
    const value = trigger.querySelector('[data-name="Value"]');
    if (!value) return;
    const row = trigger.closest('[data-name^="Row_"]');
    const label = row && row.querySelector('[data-name="Label"]');
    const key = label ? label.textContent.trim().toLowerCase() : '';
    const options = DROPDOWN_OPTIONS[key] || [value.textContent.trim(), 'Auto', 'Manual'];
    trigger.style.cursor = 'pointer';

    trigger.addEventListener('click', safe((event) => {
      event.stopPropagation();
      const existing = stage.querySelector('.aurora-menu');
      if (existing) existing.remove();

      const menu = document.createElement('div');
      menu.className = 'aurora-menu';
      options.forEach((option) => {
        const item = document.createElement('button');
        item.type = 'button';
        item.className = 'aurora-menu-item' + (option === value.textContent.trim() ? ' active' : '');
        item.textContent = option;
        item.addEventListener('click', (clickEvent) => {
          clickEvent.stopPropagation();
          value.textContent = option;
          menu.remove();
          toast(label ? label.textContent : 'Option', option + ' selected.');
        });
        menu.appendChild(item);
      });

      const scale = scaleOfStage() || 1;
      const stageRect = stage.getBoundingClientRect();
      const rect = trigger.getBoundingClientRect();
      menu.style.left = (rect.left - stageRect.left) / scale + 'px';
      menu.style.top = (rect.bottom - stageRect.top) / scale + 6 + 'px';
      menu.style.minWidth = Math.max(110, rect.width / scale) + 'px';
      stage.appendChild(menu);
      setTimeout(() => {
        const close = () => {
          menu.remove();
          document.removeEventListener('click', close);
        };
        document.addEventListener('click', close);
      }, 0);
    }));
  });

  /* ------------------------------------------------------------- keybind */
  stage.querySelectorAll('[data-name="KeyPill"]').forEach((pill) => {
    const label = pill.querySelector('[data-name="KeyLabel"]');
    if (!label) return;
    const original = label.textContent;
    pill.style.cursor = 'pointer';
    pill.addEventListener('click', safe(() => {
      label.textContent = 'press a key…';
      pill.classList.add('listening');
      const keydown = (event) => {
        event.preventDefault();
        const printable = event.key.length === 1 ? event.key.toUpperCase() : event.key;
        label.textContent = printable;
        pill.classList.remove('listening');
        window.removeEventListener('keydown', keydown, true);
        toast('Keybind', original + ' → ' + printable);
      };
      window.addEventListener('keydown', keydown, true);
      setTimeout(() => {
        if (pill.classList.contains('listening')) {
          pill.classList.remove('listening');
          label.textContent = original;
          window.removeEventListener('keydown', keydown, true);
        }
      }, 4000);
    }));
  });

  /* ------------------------------------------------------------ tooltips */
  const TIPS = {
    IconButton_close: 'Close',
    IconButton_minus: 'Minimise',
    IconButton_bell: 'Notifications',
    IconButton_moon: 'Swap template',
    Search: 'Search settings',
  };
  Object.keys(TIPS).forEach((name) => {
    stage.querySelectorAll('[data-name="' + name + '"]').forEach((el) => {
      el.dataset.tip = TIPS[name];
    });
  });
  tabs.forEach((tab) => {
    tab.dataset.tip = 'Tab · ' + (tab.dataset.tab || '');
  });

  /* --------------------------------------------------- scroll affordance */
  const content = stage.querySelector('[data-name="Content"]');
  if (content) {
    content.classList.add('has-fade');
  }

  /* ------------------------------------------------------------ key hint */
  if (!stage.querySelector('.aurora-hint')) {
    const hint = document.createElement('div');
    hint.className = 'aurora-hint';
    hint.textContent = 'Live preview — tabs, switches, sliders, colour swatches and the search box all respond.';
    stage.appendChild(hint);
  }

  document.addEventListener('keydown', (event) => {
    if (event.key !== 'Escape') return;
    if (win.style.display === 'none' && reopen) reopen.click();
  });
}

makeInteractive();

/* ---------------------------------------------------------------- scale */
const winW = (data.window.Size && data.window.Size.x[1]) || 900;
const winH = (data.window.Size && data.window.Size.y[1]) || 580;

function fit() {
  const wrap = options.wrap;
  if (!wrap) return;
  const available = (options.maxWidth || window.innerWidth) - 48;
  const availableHeight = (options.maxHeight || window.innerHeight) - (options.chrome || 150);
  const auto = Math.min(1.15, available / winW, availableHeight / winH);
  const safe = options.fixedScale || Math.max(options.minScale || 0.42, auto);

  // Scale the fixed-size stage and give the wrapper the *scaled* box.
  // Transforming the wrapper instead leaves a 900px layout box behind, which
  // widens the mobile layout viewport and crops the window.
  stage.style.transformOrigin = 'top left';
  stage.style.transform = 'scale(' + safe + ')';
  wrap.style.transform = 'none';
  wrap.style.overflow = 'hidden';
  wrap.style.width = Math.round(winW * safe) + 'px';
  wrap.style.height = Math.round(winH * safe) + 'px';
}
window.addEventListener('resize', fit);
fit();

return { selectTab, fit, root, report, tabs, pages, select: selectTab };

}
