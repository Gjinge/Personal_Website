/* Client-side translation. Strings are keyed by a hash of their English text,
   so the HTML needs no markup changes and any missing key falls back to English. */
(() => {
  'use strict';
  const LANGS = { en: 'English', zh: '简体中文', fr: 'Français', es: 'Español' };
  const HTML_LANG = { en: 'en', zh: 'zh-Hans', fr: 'fr', es: 'es' };
  const INLINE = new Set(['A','SPAN','CODE','STRONG','EM','B','I','SMALL','BR','SUP','SUB','TIME','ABBR','U','MARK','KBD','SAMP','VAR','Q','CITE']);
  const SKIP = new Set(['SCRIPT','STYLE','PRE','NOSCRIPT','TEMPLATE','SVG']);
  const ATTRS = ['aria-label','title','alt','placeholder'];
  const root = document.documentElement;
  const encoder = new TextEncoder();

  const key = text => {
    const bytes = encoder.encode(String(text).replace(/\s+/g, ' ').trim());
    let h = 0xcbf29ce484222325n;
    const prime = 0x100000001b3n, mask = (1n << 64n) - 1n;
    for (let i = 0; i < bytes.length; i++) h = ((h ^ BigInt(bytes[i])) * prime) & mask;
    return h.toString(16).padStart(16, '0').slice(0, 10);
  };

  const store = (k, v) => { try { localStorage.setItem(k, v); } catch (_) {} };
  const read = k => { try { return localStorage.getItem(k); } catch (_) { return null; } };
  const current = () => (LANGS[root.dataset.lang] ? root.dataset.lang : 'en');

  let table = {};
  const translate = text => table[key(text)];
  window.jgT = (text, ...parts) => {
    const hit = translate(text);
    return hit === undefined ? text : hit;
  };

  const tag = el => String(el.tagName || '').toUpperCase();
  function blocked(el) {
    return SKIP.has(tag(el)) || el.classList.contains('source-code') || el.classList.contains('reading-progress');
  }
  function apply(node) {
    if (blocked(node)) return;
    const kids = [...node.children];
    if (!kids.some(c => !INLINE.has(tag(c)))) {
      const text = (node.textContent || '').replace(/\s+/g, ' ').trim();
      if (text && /[A-Za-z]/.test(text)) {
        const hit = table[key(text)];
        if (hit !== undefined) node.innerHTML = hit;
        return;
      }
    }
    kids.forEach(apply);
  }
  function applyAll() {
    if (document.body) apply(document.body);
    document.querySelectorAll('*').forEach(el => {
      if (SKIP.has(tag(el))) return;
      ATTRS.forEach(a => {
        const v = el.getAttribute(a);
        if (!v) return;
        const hit = table[key(v)];
        if (hit !== undefined) el.setAttribute(a, hit.replace(/<[^>]+>/g, ''));
      });
    });
    const title = document.querySelector('title');
    if (title) {
      const hit = table[key(title.textContent)];
      if (hit !== undefined) title.textContent = hit.replace(/<[^>]+>/g, '');
    }
    document.querySelectorAll('meta[name="description"], meta[property="og:description"], meta[property="og:title"]').forEach(m => {
      const hit = table[key(m.content)];
      if (hit !== undefined) m.content = hit.replace(/<[^>]+>/g, '');
    });
    document.dispatchEvent(new CustomEvent('jg:languagechange', { detail: { lang: current() } }));
  }

  function reveal() { root.removeAttribute('data-i18n-pending'); }

  function load(lang) {
    if (lang === 'en') { table = {}; reveal(); return Promise.resolve(); }
    return new Promise(resolve => {
      const depth = (document.querySelector('link[rel="stylesheet"]').getAttribute('href') || '').replace(/assets\/css\/styles\.css$/, '');
      const script = document.createElement('script');
      script.src = `${depth}assets/js/i18n/${lang}.js?v=2`;
      script.onload = () => { table = window.JG_I18N_DATA || {}; resolve(); };
      script.onerror = () => { table = {}; resolve(); };
      document.head.append(script);
    });
  }

  function switcher() {
    const host = document.querySelector('.display-controls');
    if (!host) return;
    const wrap = document.createElement('div');
    wrap.className = 'lang-switch';
    const select = document.createElement('select');
    select.id = 'lang-select';
    select.className = 'lang-select';
    select.setAttribute('aria-label', 'Language');
    Object.entries(LANGS).forEach(([code, label]) => {
      const option = document.createElement('option');
      option.value = code; option.textContent = label;
      select.append(option);
    });
    select.value = current();
    const globe = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    globe.setAttribute('viewBox', '0 0 24 24');
    globe.setAttribute('aria-hidden', 'true');
    globe.setAttribute('class', 'globe-icon');
    globe.innerHTML = '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c2.6 2.6 2.6 15.4 0 18M12 3c-2.6 2.6-2.6 15.4 0 18"/>';
    wrap.append(globe, select);
    host.prepend(wrap);
    select.addEventListener('change', () => {
      const lang = select.value;
      store('jg-lang', lang);
      // Always reload. Translations are keyed by the hash of the English text, so a
      // second swap on an already-translated page would find nothing to match.
      if (lang !== 'en') { root.dataset.lang = lang; root.setAttribute('data-i18n-pending', ''); }
      location.reload();
    });
  }

  const start = () => {
    switcher();
    const lang = current();
    if (lang === 'en') { reveal(); return; }
    root.lang = HTML_LANG[lang] || 'en';
    load(lang).then(() => { applyAll(); reveal(); });
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
  else start();
  setTimeout(reveal, 2500);
})();
