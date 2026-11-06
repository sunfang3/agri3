/* ==========================================================================
   齐鲁农创客 · 设计稿数据层 + 手写 SVG 图表引擎（零外部依赖）
   Brand: #4737CC / #EDB81C / #5FCD96 / #45C4D8
   ========================================================================== */
(function (global) {
  'use strict';

  /* ---------------------------------------------------------------- icons */
  const P = (d, extra) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" ${extra || ''}>${d}</svg>`;
  const I = {
    gauge:   P('<path d="M12 14 16 9"/><circle cx="12" cy="14" r="8"/><path d="M12 6V4"/><path d="M20.5 14H18"/>'),
    users:   P('<circle cx="9" cy="8" r="3.2"/><path d="M3 20c0-3.3 2.7-5 6-5s6 1.7 6 5"/><path d="M17 5.5a3.2 3.2 0 0 1 0 5.5"/><path d="M18 20c0-2.4-.8-4-2.3-4.6"/>'),
    doc:     P('<path d="M6 3h8l5 5v13H6z"/><path d="M14 3v5h5"/><path d="M9 13h7M9 17h5"/>'),
    book:    P('<path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H20v15H6.5A2.5 2.5 0 0 0 4 20.5z"/><path d="M4 18.5A2.5 2.5 0 0 1 6.5 16H20"/>'),
    target:  P('<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="4"/><circle cx="12" cy="12" r="1"/>'),
    tag:     P('<path d="M4 12V5a1 1 0 0 1 1-1h7l8 8-8 8z"/><circle cx="8.5" cy="8.5" r="1.3"/>'),
    chart:   P('<path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/>'),
    spark:   P('<path d="M3 17l5-6 4 3 5-7 4 4"/>'),
    bell:    P('<path d="M18 9a6 6 0 1 0-12 0c0 5-2 6-2 6h16s-2-1-2-6"/><path d="M10.5 20a2 2 0 0 0 3 0"/>'),
    upload:  P('<path d="M12 16V4"/><path d="M7.5 8.5 12 4l4.5 4.5"/><path d="M4 15v4a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-4"/>'),
    down:    P('<path d="M12 4v12"/><path d="M7.5 11.5 12 16l4.5-4.5"/><path d="M4 19h16"/>'),
    check:   P('<path d="M4.5 12.5 9.5 17.5 19.5 6.5"/>'),
    checkc:  P('<circle cx="12" cy="12" r="9"/><path d="M8 12.2l2.7 2.7L16 9.4"/>'),
    alert:   P('<path d="M12 4 2.8 20h18.4z"/><path d="M12 10v4.5M12 17.6v.1"/>'),
    search:  P('<circle cx="11" cy="11" r="6.5"/><path d="M16 16l4.5 4.5"/>'),
    gear:    P('<circle cx="12" cy="12" r="3"/><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.2 5.2l2.1 2.1M16.7 16.7l2.1 2.1M18.8 5.2l-2.1 2.1M7.3 16.7l-2.1 2.1"/>'),
    db:      P('<ellipse cx="12" cy="6" rx="8" ry="3"/><path d="M4 6v12c0 1.7 3.6 3 8 3s8-1.3 8-3V6"/><path d="M4 12c0 1.7 3.6 3 8 3s8-1.3 8-3"/>'),
    layers:  P('<path d="M12 3 3 8l9 5 9-5z"/><path d="M3 13l9 5 9-5"/>'),
    bolt:    P('<path d="M13 2 4 14h7l-1 8 9-12h-7z"/>'),
    clock:   P('<circle cx="12" cy="12" r="8.5"/><path d="M12 7v5.3l3.4 2"/>'),
    pin:     P('<path d="M12 21s7-6.2 7-11a7 7 0 1 0-14 0c0 4.8 7 11 7 11z"/><circle cx="12" cy="10" r="2.5"/>'),
    mic:     P('<rect x="9" y="2.5" width="6" height="11" rx="3"/><path d="M5.5 11a6.5 6.5 0 0 0 13 0"/><path d="M12 17.5V21"/>'),
    cam:     P('<path d="M3 8.5A2 2 0 0 1 5 6.5h2l1.2-2h7.6L17 6.5h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><circle cx="12" cy="13" r="3.4"/>'),
    cal:     P('<rect x="3.5" y="5" width="17" height="16" rx="2"/><path d="M3.5 10h17M8 3v4M16 3v4"/>'),
    qr:      P('<rect x="3.5" y="3.5" width="7" height="7" rx="1"/><rect x="13.5" y="3.5" width="7" height="7" rx="1"/><rect x="3.5" y="13.5" width="7" height="7" rx="1"/><path d="M13.5 13.5h3v3h-3zM20.5 13.5v3M17.5 20.5h3"/>'),
    medal:   P('<circle cx="12" cy="14.5" r="5.5"/><path d="M8.5 9.2 6 3h12l-2.5 6.2"/><path d="M12 12.4l.9 1.9 2 .3-1.5 1.4.4 2-1.8-1-1.8 1 .4-2-1.5-1.4 2-.3z"/>'),
    trend:   P('<path d="M3 17l5.5-6 4 3.5L21 6"/><path d="M16 6h5v5"/>'),
    shield:  P('<path d="M12 3l7.5 3v6c0 4.4-3 7.8-7.5 9.5C7.5 19.8 4.5 16.4 4.5 12V6z"/><path d="M9 12l2.2 2.2L15.4 10"/>'),
    grid:    P('<rect x="3.5" y="3.5" width="7" height="7" rx="1"/><rect x="13.5" y="3.5" width="7" height="7" rx="1"/><rect x="3.5" y="13.5" width="7" height="7" rx="1"/><rect x="13.5" y="13.5" width="7" height="7" rx="1"/>'),
    out:     P('<path d="M15 4h4a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1h-4"/><path d="M10 16l-4-4 4-4M6 12h10"/>'),
    leaf:    P('<path d="M20 4c0 9-5.5 13-11 13a5 5 0 0 1-5-5C4 6 11 4 20 4z"/><path d="M5 20c2-6 6-9 11-11"/>'),
    fire:    P('<path d="M12 3s5 4.2 5 8.6A5 5 0 0 1 7 12c0-1.8 1-3.4 2-4.5C9.4 9 10 10 10 10s-1-3.4 2-7z"/><path d="M6.5 13.5A6 6 0 0 0 12 21a6 6 0 0 0 5.5-7.5"/>'),
    scan:    P('<path d="M3.5 8V5a1.5 1.5 0 0 1 1.5-1.5h3M20.5 8V5A1.5 1.5 0 0 0 19 3.5h-3M3.5 16v3A1.5 1.5 0 0 0 5 20.5h3M20.5 16v3a1.5 1.5 0 0 1-1.5 1.5h-3"/><path d="M3.5 12h17"/>'),
    funnel:  P('<path d="M3 4.5h18l-7 8v6l-4 2v-8z"/>'),
    eye:     P('<path d="M2 12s3.8-6.5 10-6.5S22 12 22 12s-3.8 6.5-10 6.5S2 12 2 12z"/><circle cx="12" cy="12" r="2.8"/>'),
    refresh: P('<path d="M20.5 12a8.5 8.5 0 1 1-2.6-6.1"/><path d="M20.5 4v5h-5"/>'),
    filter:  P('<path d="M3.5 5h17l-6.5 7.5V19l-4 2v-8.5z"/>'),
    edit:    P('<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M14.5 5.5 18.5 9.5"/>'),
    print:   P('<path d="M7 9V3.5h10V9"/><rect x="3.5" y="9" width="17" height="7.5" rx="1.5"/><path d="M7 14h10v6.5H7z"/>'),
    home:    P('<path d="M4 10.5 12 4l8 6.5V20H4z"/><path d="M9.5 20v-6h5v6"/>'),
    plus:    P('<path d="M12 5v14M5 12h14"/>'),
    minus:   P('<path d="M5 12h14"/>'),
    link:    P('<path d="M10 13.5a4 4 0 0 0 5.7 0l2.6-2.6a4 4 0 1 0-5.7-5.7l-1.4 1.4"/><path d="M14 10.5a4 4 0 0 0-5.7 0l-2.6 2.6a4 4 0 1 0 5.7 5.7l1.4-1.4"/>'),
    star:    P('<path d="m12 3.5 2.7 5.6 6.1.8-4.4 4.3 1 6.1-5.4-2.9-5.4 2.9 1-6.1L3.2 9.9l6.1-.8z"/>'),
    trophy:  P('<path d="M8 4h8v5a4 4 0 0 1-8 0z"/><path d="M8 5.5H5.5A2.5 2.5 0 0 0 8 10M16 5.5h2.5A2.5 2.5 0 0 1 16 10"/><path d="M12 13v4M8.5 20.5h7"/>'),
    radar:   P('<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5.5"/><circle cx="12" cy="12" r="2"/><path d="M12 12 19 8"/>'),
  };

  /* --------------------------------------------------------- chart engine */
  const NS = 'http://www.w3.org/2000/svg';
  const el = (n, a) => { const e = document.createElementNS(NS, n); for (const k in a) e.setAttribute(k, a[k]); return e; };
  const uid = () => 'g' + Math.random().toString(36).slice(2, 8);
  const fmt = n => String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ',');

  /** host: selector or element; returns svg */
  function mount(host, w, h) {
    const c = typeof host === 'string' ? document.querySelector(host) : host;
    c.innerHTML = '';
    const svg = el('svg', { viewBox: `0 0 ${w} ${h}`, class: 'chart', preserveAspectRatio: 'xMidYMid meet' });
    svg.style.height = h + 'px';
    c.appendChild(svg);
    return svg;
  }

  const Chart = {
    /** multi-series smooth area/line */
    line(host, opt) {
      const w = opt.w || 720, h = opt.h || 200;
      const p = { l: 34, r: 12, t: 14, b: 24, ...(opt.pad || {}) };
      const iw = w - p.l - p.r, ih = h - p.t - p.b;
      const svg = mount(host, w, h);
      const max = opt.max != null ? opt.max : Math.max(...opt.series.flatMap(s => s.data)) * 1.12;
      const min = opt.min != null ? opt.min : 0;
      const n = opt.labels.length;
      const X = i => p.l + (n === 1 ? iw / 2 : iw * i / (n - 1));
      const Y = v => p.t + ih - ih * (v - min) / (max - min);

      const gid = uid();
      if (opt.area !== false && opt.series.length === 1) {
        const g = el('linearGradient', { id: gid, x1: 0, y1: 0, x2: 0, y2: 1 });
        g.appendChild(el('stop', { offset: '0%', 'stop-color': opt.series[0].color, 'stop-opacity': .34 }));
        g.appendChild(el('stop', { offset: '100%', 'stop-color': opt.series[0].color, 'stop-opacity': 0 }));
        const defs = el('defs'); defs.appendChild(g); svg.appendChild(defs);
      }

      // grid + y labels
      const ticks = opt.ticks || 4;
      for (let i = 0; i <= ticks; i++) {
        const v = min + (max - min) * i / ticks, y = Y(v);
        svg.appendChild(el('line', { x1: p.l, y1: y, x2: w - p.r, y2: y, stroke: 'rgba(124,111,255,.12)', 'stroke-dasharray': i ? '3 4' : '' }));
        const t = el('text', { x: p.l - 6, y: y + 3.5, fill: '#6d669d', 'font-size': 9.5, 'text-anchor': 'end', 'font-family': 'monospace' });
        t.textContent = opt.yfmt ? opt.yfmt(v) : Math.round(v); svg.appendChild(t);
      }
      // x labels
      opt.labels.forEach((l, i) => {
        if (n > 9 && i % 2) return;
        const t = el('text', { x: X(i), y: h - 7, fill: '#6d669d', 'font-size': 9.5, 'text-anchor': 'middle' });
        t.textContent = l; svg.appendChild(t);
      });
      // optional target line
      if (opt.target != null) {
        const y = Y(opt.target);
        svg.appendChild(el('line', { x1: p.l, y1: y, x2: w - p.r, y2: y, stroke: '#edb81c', 'stroke-width': 1, 'stroke-dasharray': '5 4', opacity: .8 }));
        const t = el('text', { x: w - p.r, y: y - 5, fill: '#edb81c', 'font-size': 9, 'text-anchor': 'end' });
        t.textContent = opt.targetLabel || ''; svg.appendChild(t);
      }
      // series
      opt.series.forEach((s, si) => {
        const pts = s.data.map((v, i) => [X(i), Y(v)]);
        let d = `M${pts[0][0]},${pts[0][1]}`;
        for (let i = 1; i < pts.length; i++) {
          const [x0, y0] = pts[i - 1], [x1, y1] = pts[i], cx = (x0 + x1) / 2;
          d += ` C${cx},${y0} ${cx},${y1} ${x1},${y1}`;
        }
        if (opt.area !== false && si === 0) {
          svg.appendChild(el('path', { d: d + ` L${pts[pts.length - 1][0]},${p.t + ih} L${pts[0][0]},${p.t + ih} Z`, fill: `url(#${gid})` }));
        }
        svg.appendChild(el('path', { d, fill: 'none', stroke: s.color, 'stroke-width': s.w || 2, 'stroke-linecap': 'round', 'stroke-linejoin': 'round', opacity: s.o || 1 }));
        if (s.dash) svg.lastChild.setAttribute('stroke-dasharray', s.dash);
        if (opt.dots !== false) s.data.forEach((v, i) => {
          const c = el('circle', { cx: X(i), cy: Y(v), r: si === 0 ? 3 : 2.4, fill: '#0d0a28', stroke: s.color, 'stroke-width': 1.8 });
          svg.appendChild(c);
          const ttl = el('title'); ttl.textContent = `${opt.labels[i]} · ${s.name} ${v}${opt.unit || ''}`; c.appendChild(ttl);
        });
      });
      return svg;
    },

    /** vertical bars, optional stacked + avg line */
    bar(host, opt) {
      const w = opt.w || 420, h = opt.h || 190;
      const p = { l: 30, r: 10, t: 14, b: 26, ...(opt.pad || {}) };
      const iw = w - p.l - p.r, ih = h - p.t - p.b;
      const svg = mount(host, w, h);
      const n = opt.labels.length;
      const totals = opt.labels.map((_, i) => opt.series.reduce((a, s) => a + (s.data[i] || 0), 0));
      const max = opt.max != null ? opt.max : Math.max(...totals) * 1.16;
      const bw = iw / n;
      const Y = v => p.t + ih - ih * v / max;

      for (let i = 0; i <= 3; i++) {
        const y = p.t + ih - ih * i / 3;
        svg.appendChild(el('line', { x1: p.l, y1: y, x2: w - p.r, y2: y, stroke: 'rgba(124,111,255,.12)', 'stroke-dasharray': i ? '3 4' : '' }));
        const t = el('text', { x: p.l - 5, y: y + 3.5, fill: '#6d669d', 'font-size': 9, 'text-anchor': 'end', 'font-family': 'monospace' });
        t.textContent = Math.round(max * i / 3); svg.appendChild(t);
      }
      opt.labels.forEach((l, i) => {
        const x = p.l + bw * i + bw * 0.22, bwi = bw * 0.56;
        let acc = 0;
        opt.series.forEach(s => {
          const v = s.data[i] || 0;
          if (v <= 0) return;
          const y0 = Y(acc + v), y1 = Y(acc);
          const r = el('rect', { x, y: y0, width: bwi, height: Math.max(1, y1 - y0 - (opt.series.length > 1 ? 1 : 0)), fill: s.color, opacity: s.o || 1, rx: opt.series.length > 1 ? 1.5 : 2.5 });
          const ttl = el('title'); ttl.textContent = `${l} · ${s.name} ${v}`; r.appendChild(ttl);
          svg.appendChild(r); acc += v;
        });
        if (opt.showVal !== false) {
          const t = el('text', { x: x + bwi / 2, y: Y(totals[i]) - 5, fill: '#a49dd4', 'font-size': 9, 'text-anchor': 'middle', 'font-family': 'monospace' });
          t.textContent = opt.vfmt ? opt.vfmt(totals[i]) : totals[i]; svg.appendChild(t);
        }
        const t2 = el('text', { x: x + bwi / 2, y: h - 8, fill: '#6d669d', 'font-size': 9, 'text-anchor': 'middle' });
        t2.textContent = l; svg.appendChild(t2);
      });
      if (opt.avg != null) {
        const y = Y(opt.avg);
        svg.appendChild(el('line', { x1: p.l, y1: y, x2: w - p.r, y2: y, stroke: '#edb81c', 'stroke-dasharray': '4 3', 'stroke-width': 1.2 }));
        const t = el('text', { x: w - p.r, y: y - 4, fill: '#edb81c', 'font-size': 9, 'text-anchor': 'end' });
        t.textContent = opt.avgLabel || ''; svg.appendChild(t);
      }
      return svg;
    },

    /** horizontal ranking bars */
    hbar(host, opt) {
      const w = opt.w || 420, rowH = opt.rowH || 22;
      const h = opt.data.length * rowH + 8;
      const svg = mount(host, w, h);
      const lw = opt.labelW || 62;
      const max = Math.max(...opt.data.map(d => d.v));
      opt.data.forEach((d, i) => {
        const y = i * rowH + 4;
        const t = el('text', { x: 0, y: y + rowH / 2 + 3.5, fill: '#a49dd4', 'font-size': 11 });
        t.textContent = d.k; svg.appendChild(t);
        const bw = (w - lw - 54) * d.v / max;
        svg.appendChild(el('rect', { x: lw, y: y + 3, width: w - lw - 54, height: rowH - 9, rx: 2, fill: 'rgba(124,111,255,.08)' }));
        const r = el('rect', { x: lw, y: y + 3, width: Math.max(2, bw), height: rowH - 9, rx: 2, fill: d.c || '#4737cc', opacity: d.o || 1 });
        const ttl = el('title'); ttl.textContent = `${d.k} ${d.v}${opt.unit || ''}`; r.appendChild(ttl);
        svg.appendChild(r);
        const v = el('text', { x: w - 2, y: y + rowH / 2 + 3.5, fill: '#edeaff', 'font-size': 10.5, 'text-anchor': 'end', 'font-family': 'monospace' });
        v.textContent = opt.vfmt ? opt.vfmt(d.v) : d.v; svg.appendChild(v);
      });
      return svg;
    },

    /** donut with center metric */
    donut(host, opt) {
      const size = opt.size || 168, sw = opt.sw || 20, r = size / 2 - sw / 2 - 2;
      const cx = size / 2, cy = size / 2, C = 2 * Math.PI * r;
      const svg = mount(host, size, size);
      const total = opt.data.reduce((a, d) => a + d.v, 0) || 1;
      svg.appendChild(el('circle', { cx, cy, r, fill: 'none', stroke: 'rgba(124,111,255,.1)', 'stroke-width': sw }));
      let off = 0;
      opt.data.forEach(d => {
        const frac = d.v / total;
        const c = el('circle', {
          cx, cy, r, fill: 'none', stroke: d.c, 'stroke-width': sw,
          'stroke-dasharray': `${C * frac - 2} ${C}`, 'stroke-dashoffset': -C * off,
          transform: `rotate(-90 ${cx} ${cy})`, 'stroke-linecap': 'butt'
        });
        const ttl = el('title'); ttl.textContent = `${d.k} ${d.v} (${(frac * 100).toFixed(1)}%)`; c.appendChild(ttl);
        svg.appendChild(c); off += frac;
      });
      if (opt.center) {
        const a = el('text', { x: cx, y: cy - 1, fill: '#edeaff', 'font-size': 25, 'text-anchor': 'middle', 'font-family': 'monospace', 'font-weight': 600 });
        a.textContent = opt.center; svg.appendChild(a);
        const b = el('text', { x: cx, y: cy + 15, fill: '#6d669d', 'font-size': 10, 'text-anchor': 'middle' });
        b.textContent = opt.centerSub || ''; svg.appendChild(b);
      }
      return svg;
    },

    /** capability radar */
    radar(host, opt) {
      const size = opt.size || 210, cx = size / 2, cy = size / 2, R = size / 2 - 34;
      const n = opt.axes.length, svg = mount(host, size, size);
      const ang = i => -Math.PI / 2 + i * 2 * Math.PI / n;
      for (let k = 1; k <= 4; k++) {
        const pts = opt.axes.map((_, i) => `${cx + Math.cos(ang(i)) * R * k / 4},${cy + Math.sin(ang(i)) * R * k / 4}`).join(' ');
        svg.appendChild(el('polygon', { points: pts, fill: k === 4 ? 'rgba(124,111,255,.03)' : 'none', stroke: 'rgba(124,111,255,.16)', 'stroke-width': 1 }));
      }
      opt.axes.forEach((a, i) => {
        svg.appendChild(el('line', { x1: cx, y1: cy, x2: cx + Math.cos(ang(i)) * R, y2: cy + Math.sin(ang(i)) * R, stroke: 'rgba(124,111,255,.16)' }));
        const lx = cx + Math.cos(ang(i)) * (R + 19), ly = cy + Math.sin(ang(i)) * (R + 19);
        const t = el('text', { x: lx, y: ly + 3.5, fill: '#a49dd4', 'font-size': 10, 'text-anchor': Math.abs(Math.cos(ang(i))) < .25 ? 'middle' : (Math.cos(ang(i)) > 0 ? 'start' : 'end') });
        t.textContent = a; svg.appendChild(t);
      });
      opt.sets.forEach((s, si) => {
        const pts = s.data.map((v, i) => `${cx + Math.cos(ang(i)) * R * (v / (s.max || 100))},${cy + Math.sin(ang(i)) * R * (v / (s.max || 100))}`).join(' ');
        svg.appendChild(el('polygon', { points: pts, fill: s.c, 'fill-opacity': si ? .1 : .2, stroke: s.c, 'stroke-width': 2 }));
        s.data.forEach((v, i) => svg.appendChild(el('circle', { cx: cx + Math.cos(ang(i)) * R * (v / (s.max || 100)), cy: cy + Math.sin(ang(i)) * R * (v / (s.max || 100)), r: 2.6, fill: s.c })));
      });
      return svg;
    },

    /** conversion funnel */
    funnel(host, opt) {
      const w = opt.w || 420, rowH = 30, h = opt.steps.length * rowH + 6;
      const svg = mount(host, w, h);
      const max = opt.steps[0].v;
      opt.steps.forEach((s, i) => {
        const y = i * rowH + 3;
        const bw = (w - 96) * s.v / max;
        const t = el('text', { x: 0, y: y + 15, fill: '#a49dd4', 'font-size': 11 });
        t.textContent = s.k; svg.appendChild(t);
        const g = el('linearGradient', { id: uid(), x1: 0, y1: 0, x2: 1, y2: 0 });
        g.appendChild(el('stop', { offset: '0%', 'stop-color': s.c, 'stop-opacity': .95 }));
        g.appendChild(el('stop', { offset: '100%', 'stop-color': s.c, 'stop-opacity': .38 }));
        const defs = el('defs'); defs.appendChild(g); svg.appendChild(defs);
        svg.appendChild(el('rect', { x: 74, y: y + 4, width: Math.max(3, bw), height: rowH - 12, rx: 2.5, fill: `url(#${g.getAttribute('id')})` }));
        const v = el('text', { x: 78 + Math.max(3, bw), y: y + 17, fill: '#edeaff', 'font-size': 10.5, 'font-family': 'monospace' });
        v.textContent = fmt(s.v) + (opt.unit || ''); svg.appendChild(v);
        if (i) {
          const prev = opt.steps[i - 1].v;
          const cr = (s.v / prev * 100).toFixed(1);
          const crt = el('text', { x: w - 1, y: y + 17, fill: cr >= 40 ? '#5fcd96' : cr >= 20 ? '#edb81c' : '#e5615f', 'font-size': 10, 'text-anchor': 'end', 'font-family': 'monospace' });
          crt.textContent = cr + '%'; svg.appendChild(crt);
        }
      });
      return svg;
    },

    /** sparkline row (inline) */
    spark(host, opt) {
      const w = opt.w || 88, h = opt.h || 24;
      const svg = mount(host, w, h);
      const d0 = opt.data, mn = Math.min(...d0), mx = Math.max(...d0), rg = mx - mn || 1;
      const pts = d0.map((v, i) => `${i / (d0.length - 1) * (w - 4) + 2},${h - 3 - (v - mn) / rg * (h - 7)}`);
      svg.appendChild(el('path', { d: `M${pts.join(' L')}`, fill: 'none', stroke: opt.c || '#4737cc', 'stroke-width': 1.6, 'stroke-linecap': 'round' }));
      svg.appendChild(el('circle', { cx: pts[pts.length - 1].split(',')[0], cy: pts[pts.length - 1].split(',')[1], r: 2, fill: opt.c || '#4737cc' }));
      return svg;
    },

    /** semicircular gauge */
    gauge(host, opt) {
      const w = opt.w || 150, h = opt.h || 88;
      const svg = mount(host, w, h);
      const cx = w / 2, cy = h - 10, R = Math.min(w / 2 - 8, h - 18);
      svg.appendChild(el('path', { d: arc(cx, cy, R, 180, 0), fill: 'none', stroke: 'rgba(124,111,255,.12)', 'stroke-width': opt.sw || 11, 'stroke-linecap': 'round' }));
      svg.appendChild(el('path', { d: arc(cx, cy, R, 180, 180 * (opt.pct / 100)), fill: 'none', stroke: opt.c || '#4737cc', 'stroke-width': opt.sw || 11, 'stroke-linecap': 'round' }));
      const t = el('text', { x: cx, y: cy - 8, fill: '#edeaff', 'font-size': 22, 'text-anchor': 'middle', 'font-family': 'monospace', 'font-weight': 600 });
      t.textContent = opt.pct + (opt.unit || '%'); svg.appendChild(t);
      if (opt.label) {
        const l = el('text', { x: cx, y: cy + 10, fill: '#6d669d', 'font-size': 10, 'text-anchor': 'middle' });
        l.textContent = opt.label; svg.appendChild(l);
      }
      return svg;
      function arc(x, y, r, a0, a1) {
        const p = (a) => [x + Math.cos(a * Math.PI / 180) * r, y + Math.sin(a * Math.PI / 180) * r];
        const s = p(a0), e = p(a1);
        return `M${s[0]},${s[1]} A${r},${r} 0 ${a1 - a0 > 180 ? 1 : 0} 1 ${e[0]},${e[1]}`;
      }
    },
  };

  /* ------------------------------------------------------------- dataset */
  const D = {
    districts: [
      { n: '历城区', c: '370112', s: 486 }, { n: '章丘区', c: '370114', s: 402 },
      { n: '济阳区', c: '370115', s: 358 }, { n: '平阴县', c: '370124', s: 291 },
      { n: '商河县', c: '370126', s: 268 }, { n: '长清区', c: '370113', s: 244 },
      { n: '莱芜区', c: '370116', s: 197 }, { n: '钢城区', c: '370117', s: 152 },
      { n: '市中区', c: '370103', s: 138 }, { n: '天桥区', c: '370105', s: 121 },
      { n: '历下区', c: '370102', s: 116 }, { n: '槐荫区', c: '370104', s: 97 },
    ],
    stage: [
      { k: '成长期', v: 986, c: '#edb81c' }, { k: '起步期', v: 682, c: '#6b5bf2' },
      { k: '成熟期', v: 461, c: '#5fcd96' }, { k: '转型期', v: 213, c: '#45c4d8' },
    ],
    months: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月'],
    growth: {
      name: '全市学员平均能力分', color: '#6b5bf2',
      data: [51.2, 53.6, 55.1, 58.4, 61.0, 63.7, 66.2, 68.9, 71.4, 73.8],
    },
    reachTrend: {
      name: '政策有效触达率', color: '#edb81c',
      data: [41.5, 45.8, 48.2, 52.6, 55.1, 58.4, 61.9, 64.2, 66.8, 69.3],
    },
    stack: [
      { name: '已录取 enrolled', color: '#4737cc', data: [412, 486, 553, 598, 642, 715, 768, 812, 866, 924] },
      { name: '审核中 pending', color: '#edb81c', data: [96, 88, 104, 92, 78, 86, 71, 64, 58, 47] },
      { name: '已完成 completed', color: '#5fcd96', data: [188, 226, 274, 331, 402, 468, 541, 612, 688, 761] },
    ],
    funnel: [
      { k: '系统推送', v: 18420, c: '#4737cc' },
      { k: 'App 内查看', v: 12680, c: '#6b5bf2' },
      { k: '收藏 / 加入清单', v: 7430, c: '#8f80ff' },
      { k: '咨询 / 报名', v: 4126, c: '#a79bff' },
      { k: '提交申报', v: 2378, c: '#edb81c' },
      { k: '获批落地', v: 1364, c: '#5fcd96' },
    ],
    radar: {
      axes: ['技术水平', '经营管理', '品牌营销', '电商运营', '政策申报', '联农带农'],
      sets: [{ c: '#4737cc', data: [74, 68, 55, 47, 81, 52], max: 100 }],
    },
    radarCity: {
      axes: ['技术水平', '经营管理', '品牌营销', '电商运营', '政策申报', '联农带农'],
      sets: [
        { c: '#4737cc', data: [74, 68, 55, 47, 81, 52], max: 100 },
        { c: '#edb81c', data: [64, 58, 41, 34, 72, 39], max: 100 },
      ],
    },
    policies: [
      { t: '关于开展 2026 年度市级家庭农场示范场申报的通知', w: '济农〔2026〕12 号', u: '市农业农村局', d: '2026-10-28', sc: 95, reach: 428, read: 386, apply: 142, tag: ['家庭农场', '示范创建', '荣誉申报'], gap: false },
      { t: '济南市家庭农场示范户补助实施办法', w: '济政办〔2026〕7 号', u: '市政府办公厅', d: '2026-12-15', sc: 88, reach: 612, read: 528, apply: 218, tag: ['家庭农场', '财政补助', '规模≥100亩'], gap: false },
      { t: '商河县粮食高产创建奖励资金申报', w: '商农〔2026〕31 号', u: '商河县农业农村局', d: '2026-11-20', sc: 84, reach: 268, read: 231, apply: 96, tag: ['粮食种植', '奖励补贴'], gap: false },
      { t: '平阴县玫瑰特色产业扶持专项资金', w: '平政发〔2026〕5 号', u: '平阴县政府', d: '2026-10-15', sc: 79, reach: 187, read: 118, apply: 41, tag: ['玫瑰产业', '加工扶持'], gap: true },
      { t: '章丘大葱产业提升补贴办法（2026 修订）', w: '章政规〔2026〕2 号', u: '章丘区政府', d: '2026-12-31', sc: 76, reach: 214, read: 173, apply: 58, tag: ['蔬菜种植', '技改补贴'], gap: false },
      { t: '长清生态农旅融合示范项目扶持', w: '长政发〔2026〕9 号', u: '长清区政府', d: '2027-01-20', sc: 72, reach: 163, read: 132, apply: 37, tag: ['休闲农业', '农旅融合'], gap: false },
      { t: '济阳区设施蔬菜水肥一体化推广补贴', w: '济阳农〔2026〕18 号', u: '济阳区农业农村局', d: '2026-11-08', sc: 91, reach: 204, read: 196, apply: 87, tag: ['设施蔬菜', '技术推广'], gap: false },
      { t: '莱芜生姜绿色防控专项补助', w: '莱农〔2026〕6 号', u: '莱芜区农业农村局', d: '2026-10-31', sc: 86, reach: 176, read: 164, apply: 71, tag: ['生姜种植', '绿色防控'], gap: false },
      { t: '农机购置与应用补贴（2026 年度第一批）', w: '农财〔2026〕44 号', u: '市财政局', d: '2026-12-05', sc: 74, reach: 528, read: 402, apply: 186, tag: ['农机补贴', '全产业'], gap: false },
      { t: '高素质农民培育示范户遴选', w: '农广校〔2026〕14 号', u: '市农广校', d: '2026-11-12', sc: 82, reach: 342, read: 315, apply: 128, tag: ['培育示范', '荣誉申报'], gap: false },
    ],
    courses: [
      { t: '市直·政策解读与申报辅导', l: '市直班 · 市农广校教研室 · 市农广校（市直）', st: '已录取', sc: 92, cap: 60, en: 52, d: '10-15 09:00', p: '市农广校 三号报告厅' },
      { t: '市直·农创客品牌营销实务', l: '市直班 · 市农广校教研室 · 市农广校（市直）', st: '已录取', sc: 88, cap: 60, en: 48, d: '10-17 09:00', p: '市农广校 三号报告厅' },
      { t: '小麦高产技术培训', l: '历城区 · 王守粮 · 历城区农广校', st: '审核中', sc: 81, cap: 50, en: 46, d: '10-22 08:30', p: '历城区农技推广中心' },
      { t: '历下都市农业运营入门', l: '历城区 · 吴市农 · 历下区农广校', st: '报名', sc: 68, cap: 40, en: 22, d: '10-26 14:00', p: '历下都市农业园' },
      { t: '莱芜生姜绿色防控课堂', l: '莱芜区 · 张姜农 · 莱芜区农广校', st: '审核中', sc: 79, cap: 45, en: 41, d: '10-24 09:00', p: '莱芜区农广校' },
      { t: '市直·高素质农民培育示范班', l: '市直班 · 市农广校教研室 · 市农广校（市直）', st: '已录取', sc: 90, cap: 80, en: 73, d: '11-03 09:00', p: '市农广校 培训基地' },
      { t: '设施蔬菜水肥一体化', l: '济阳区 · 孙园丁 · 济阳区蔬菜示范园', st: '报名', sc: 85, cap: 35, en: 18, d: '11-06 08:30', p: '济阳区蔬菜示范园' },
      { t: '章丘大葱标准化种植班', l: '章丘区 · 刘葱香 · 章丘区农业培训中心', st: '报名', sc: 83, cap: 50, en: 27, d: '11-08 09:00', p: '章丘区农业培训中心' },
      { t: '长清生态农旅运营实务', l: '长清区 · 周山果 · 长清区农广校', st: '报名', sc: 71, cap: 42, en: 19, d: '11-12 14:00', p: '长清区农广校' },
      { t: '平阴玫瑰精深加工研修', l: '平阴县 · 陈玫香 · 平阴县玫瑰产业园', st: '报名', sc: 77, cap: 30, en: 12, d: '11-15 09:00', p: '平阴县玫瑰产业园' },
    ],
    demand: [
      { k: '大棚补光灯技术', v: 286 }, { k: '直播带货实操', v: 264 }, { k: '政策申报辅导', v: 241 },
      { k: '设施蔬菜连作障碍', v: 218 }, { k: '品牌注册与商标', v: 187 }, { k: '农机补贴政策', v: 164 },
      { k: '订单农业对接', v: 148 }, { k: '休闲农业规划', v: 121 }, { k: '农产品冷链仓储', v: 96 },
      { k: '种苗选育技术', v: 84 }, { k: '农机具维保', v: 62 }, { k: ' farm 主业转型', v: 41 },
    ],
    // policy × district match heat
    heatRows: [
      { k: '家庭农场示范场申报', v: [4, 4, 4, 4, 4, 4, 3, 3, 2, 2, 1, 1] },
      { k: '家庭农场补助办法', v: [4, 4, 4, 3, 3, 3, 3, 2, 2, 2, 1, 1] },
      { k: '设施蔬菜水肥一体化', v: [1, 1, 1, 1, 4, 2, 3, 1, 2, 1, 3, 1] },
      { k: '莱芜生姜绿色防控', v: [1, 1, 0, 0, 1, 1, 5, 1, 1, 0, 0, 0] },
      { k: '章丘大葱产业提升', v: [1, 1, 1, 0, 1, 1, 3, 1, 1, 1, 4, 0] },
      { k: '平阴玫瑰产业扶持', v: [0, 1, 0, 1, 4, 1, 1, 1, 1, 0, 5, 0] },
      { k: '商河粮食高产奖励', v: [1, 1, 1, 0, 1, 1, 1, 1, 5, 2, 0, 1] },
      { k: '长清农旅融合示范', v: [2, 2, 3, 1, 1, 5, 1, 0, 1, 1, 1, 0] },
      { k: '农机购置补贴（一批）', v: [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] },
    ],
    cases: [
      { t: '商河县·粮食高产典型案例', sc: 93 }, { t: '平阴县·平阴玫瑰典型案例', sc: 90 },
      { t: '钢城区·山地林果典型案例', sc: 87 }, { t: '莱芜区·生姜大蒜典型案例', sc: 84 },
      { t: '济阳区·黄瓜番茄典型案例', sc: 81 }, { t: '长清区·生态农旅典型案例', sc: 79 },
      { t: '章丘区·大葱产业典型案例', sc: 76 },
    ],
    timeline: [
      { t: '09:12', k: '市直·政策解读与申报辅导', s: 'open', tag: '课程' },
      { t: '09:41', k: '家庭农场示范场申报通知（匹配度 95%）', s: 'push', tag: '推送' },
      { t: '10:03', k: '历城区 王守粮 提交小麦高产技术培训报名', s: 'enroll', tag: '报名' },
      { t: '10:27', k: '2026 年度农机补贴第一批政策入库并完成标签校准', s: 'policy', tag: '政策' },
      { t: '11:15', k: '平阴玫瑰产业扶持政策触发资源缺口告警', s: 'warn', tag: '预警' },
      { t: '13:48', k: '学员 李长河 完成「设施蔬菜水肥一体化」结业考试', s: 'done', tag: '结业' },
      { t: '14:22', k: '全市画像重算任务完成，触发推荐 1,842 条', s: 'job', tag: '引擎' },
      { t: '15:06', k: '章丘区 上报新学员 12 名（Excel 批量导入）', s: 'import', tag: '导入' },
    ],
    tagLib: [
      { c: 'identity', n: '身份', items: ['新农人', '合作社负责人', '家庭农场主', '种植大户', '返乡创业青年', '农业经纪人'] },
      { c: 'industry', n: '产业', items: ['粮食种植', '蔬菜种植', '果树种植', '畜牧养殖', '水产养殖', '花卉苗木', '中药材', '食用菌'] },
      { c: 'scale', n: '规模', items: ['小型', '中型', '大型'] },
      { c: 'income', n: '收入', items: ['低收入', '中等收入', '高收入'] },
      { c: 'stage', n: '阶段', items: ['起步期', '成长期', '成熟期', '转型期'] },
      { c: 'deadline', n: '时效', items: ['紧急', '当季', '年内'] },
    ],
    alerts: [
      { lv: 'high', t: '资源缺口', m: '「直播带货」相关需求累计 264 人次，标签库中缺少对应课程与服务供给', act: '补充资源' },
      { lv: 'high', t: '触达不足', m: '平阴玫瑰产业扶持政策匹配 291 人，仅推送 187 人（64.3%），低于 80% 阈值', act: '重跑推送' },
      { lv: 'mid', t: '能力下滑', m: '钢城区 6 名学员技术能力分环比下降超 8 分，连续两期走低', act: '查看名单' },
      { lv: 'mid', t: '画像不完整', m: '长清区 41 名学员未勾选产业与规模标签，不参与精准匹配', act: '批量督办' },
      { lv: 'low', t: '政策临期', m: '章丘大葱产业提升补贴办法距截止 12 天，仅 58 人已提交申报', act: '定向提醒' },
    ],
  };

  global.QL = { I, Chart, D, fmt, $: (s, r) => (r || document).querySelector(s), $$: (s, r) => Array.from((r || document).querySelectorAll(s)) };
})(window);
