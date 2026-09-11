(() => {
  'use strict';
  const t = (s) => (window.jgT ? window.jgT(s) : s);
  const list = document.getElementById('reading-list');
  if (!list) return;
  const notes = (window.readingNotes || []).filter(note => {
    if (!note.title || !note.url) return false;
    try {
      const url = new URL(note.url, location.href);
      return url.protocol === 'https:' || (url.origin === location.origin && url.protocol === 'http:');
    } catch (_) { return false; }
  }).sort((a, b) => (b.date || '').localeCompare(a.date || ''));
  if (!notes.length) return;
  document.getElementById('reading-empty').hidden = true;
  document.getElementById('reading-tools').hidden = false;
  const search = document.getElementById('reading-search');
  const filter = document.getElementById('reading-tag');
  const result = document.getElementById('reading-result');
  const element = (tag, text, className) => {
    const node = document.createElement(tag);
    if (text) node.textContent = text;
    if (className) node.className = className;
    return node;
  };
  const tags = note => Array.isArray(note.tags) ? note.tags : [];
  [...new Set(notes.flatMap(tags))].sort().forEach(tag => {
    const option = element('option', tag); option.value = tag; filter.append(option);
  });
  function render() {
    const query = search.value.trim().toLocaleLowerCase();
    const shown = notes.filter(note => (!filter.value || tags(note).includes(filter.value)) &&
      [note.title, note.author, note.summary, ...tags(note)].join(' ').toLocaleLowerCase().includes(query));
    list.replaceChildren();
    result.textContent = shown.length ? t(shown.length === 1 ? '{n} note' : '{n} notes').replace('{n}', shown.length) : t('No notes match. Try another search or topic.');
    shown.forEach(note => {
      const card = element('article', '', 'reading-card');
      const meta = element('p', '', 'reading-meta');
      if (note.author) meta.append(element('span', note.author));
      if (note.date) { const time = element('time', note.date); time.dateTime = note.date; meta.append(time); }
      const heading = element('h2');
      const link = element('a', note.title); link.href = note.url;
      if (new URL(note.url, location.href).origin !== location.origin) { link.target = '_blank'; link.rel = 'noopener noreferrer'; }
      heading.append(link); card.append(meta, heading);
      if (note.summary) card.append(element('p', note.summary, 'reading-summary'));
      if (tags(note).length) {
        const topics = element('ul', '', 'interest-tags');
        tags(note).forEach(tag => topics.append(element('li', tag))); card.append(topics);
      }
      list.append(card);
    });
  }
  search.addEventListener('input', render);
  filter.addEventListener('change', render);
  render();
})();
