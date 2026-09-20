/* Full-screen cover: typewriter subtitle and header state.
   Strings are the English originals; translations come from i18n.js (window.jgT),
   which is keyed by a hash of the English text, so no separate key set is needed. */
(() => {
  'use strict';
  const cover = document.querySelector('.cover');
  if (!cover) return;

  const root = document.documentElement;
  const out = cover.querySelector('.cover-typed');
  const caret = cover.querySelector('.cover-caret');
  const header = document.querySelector('.site-header');

  /* ---- header: transparent over the painting, solid once the cover is behind us ---- */
  let ticking = false;
  const syncHeader = () => {
    const bottom = header ? header.getBoundingClientRect().bottom : 112;
    document.body.style.setProperty('--header-bottom', `${Math.round(bottom)}px`);
    const limit = cover.offsetHeight - bottom;
    document.body.classList.toggle('is-past-cover', scrollY > Math.max(0, limit));
    ticking = false;
  };
  const queueHeader = () => { if (!ticking) { ticking = true; requestAnimationFrame(syncHeader); } };
  addEventListener('scroll', queueHeader, { passive: true });
  addEventListener('resize', queueHeader, { passive: true });
  syncHeader();

  /* ---- typewriter ---- */
  if (!out) return;

  const SENTENCES = [
    'Visiting undergraduate at UW–Madison (Fall 2026).',
    'Information engineering undergraduate at SUSTech.'
  ];
  const TYPE = 62, ERASE = 32, HOLD = 2000, GAP = 420;

  const translate = s => (window.jgT ? window.jgT(s) : s);
  const still = () => matchMedia('(prefers-reduced-motion: reduce)').matches || root.dataset.motion === 'paused';

  let lines = SENTENCES.slice();
  let timer = 0;
  let index = 0;
  let chars = 0;
  let erasing = false;
  let booted = false;

  const clear = () => { clearTimeout(timer); timer = 0; };
  const show = text => { out.textContent = text; };

  function tick() {
    if (still()) { show(lines[index]); if (caret) caret.hidden = true; return; }
    if (caret) caret.hidden = false;
    const line = lines[index];
    if (!erasing) {
      chars += 1;
      show(line.slice(0, chars));
      if (chars >= line.length) { erasing = true; timer = setTimeout(tick, HOLD); return; }
      timer = setTimeout(tick, TYPE + Math.random() * 45);
      return;
    }
    chars -= 1;
    show(line.slice(0, Math.max(0, chars)));
    if (chars <= 0) {
      erasing = false;
      index = (index + 1) % lines.length;
      timer = setTimeout(tick, GAP);
      return;
    }
    timer = setTimeout(tick, ERASE);
  }

  function restart() {
    clear();
    index = 0; chars = 0; erasing = false;
    if (still()) { show(lines[0]); if (caret) caret.hidden = true; return; }
    if (caret) caret.hidden = false;
    tick();
  }

  function refresh() {
    booted = true;
    lines = SENTENCES.map(translate);
    restart();
  }

  document.addEventListener('jg:languagechange', refresh, { once: true });
  const lang = root.dataset.lang;
  if (!lang || lang === 'en') refresh();
  else setTimeout(() => { if (!booted) refresh(); }, 2600);

  /* Respond to the site's own motion toggle as well as the OS setting. */
  new MutationObserver(restart).observe(root, { attributes: true, attributeFilter: ['data-motion'] });
  matchMedia('(prefers-reduced-motion: reduce)').addEventListener('change', restart);
})();
