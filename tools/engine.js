/* ------------------------------------------------------------------
   Aurora UI — layout engine.

   Takes the JSON produced by tools/dump.py (a serialised Roblox GUI
   tree) and lays it out in the DOM: automatic sizing, list/grid
   layout, padding, anchors, rotation, gradients, strokes, text.

   Used by both docs/real-ui.html (one window) and docs/templates.html
   (ten windows, one at a time).
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
    pages[key].style.display = key === name ? '' : 'none';
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
  wrap.style.transform = 'scale(' + safe + ')';
  wrap.style.height = winH * safe + 'px';
  wrap.style.width = winW * safe + 'px';
}
window.addEventListener('resize', fit);
fit();

return { selectTab, fit, root, report, tabs, pages };

}
