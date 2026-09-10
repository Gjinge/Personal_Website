(() => {
  'use strict';
  const grid = document.getElementById('portfolio-grid');
  if (!grid) return;
  const kind = document.body.dataset.portfolio;
  const items = window.portfolio?.[kind] || [];
  if (!items.length) return;
  document.getElementById('portfolio-empty').hidden = true;
  const node = (tag, className, text) => {
    const element = document.createElement(tag);
    if (className) element.className = className;
    if (text) element.textContent = text;
    return element;
  };
  const image = (src, alt) => {
    const img = node('img');
    img.src = src; img.alt = alt; img.loading = 'lazy'; img.decoding = 'async';
    return img;
  };
  if (kind === 'videos') {
    items.forEach(item => {
      let url;
      try { url = new URL(item.url); } catch (_) { return; }
      if (url.protocol !== 'https:') return;
      const card = node('a', 'video-card');
      card.href = url.href; card.target = '_blank'; card.rel = 'noopener noreferrer';
      const cover = node('div', 'video-cover');
      if (item.poster) cover.append(image(item.poster, ''));
      cover.append(node('span', 'video-play', '▶'));
      cover.setAttribute('aria-hidden', 'true');
      const info = node('div', 'video-info');
      info.append(node('p', 'eyebrow', item.platform || url.hostname), node('h2', '', item.title), node('p', '', item.description), node('span', 'text-link', 'Watch video ↗'));
      card.append(cover, info); grid.append(card);
    });
    if (!grid.children.length) document.getElementById('portfolio-empty').hidden = false;
    return;
  }
  const dialog = document.getElementById('photo-viewer');
  const viewerImage = document.getElementById('viewer-image');
  const caption = document.getElementById('viewer-caption');
  const position = document.getElementById('viewer-position');
  let visible = items, current = 0;
  const display = index => {
    current = (index + visible.length) % visible.length;
    const item = visible[current];
    viewerImage.src = item.full || item.src; viewerImage.alt = item.alt;
    caption.textContent = [item.title, item.caption].filter(Boolean).join(' — ');
    position.textContent = `${current + 1} / ${visible.length}`;
  };
  const render = collection => {
    visible = collection === null ? items : items.filter(item => item.collection === collection);
    grid.replaceChildren();
    visible.forEach((item, index) => {
      const figure = node('figure', 'photo-card');
      const link = node('a', 'photo-open'); link.href = item.full || item.src;
      link.setAttribute('aria-label', `Enlarge ${item.title || item.alt}`);
      link.append(image(item.src, item.alt));
      link.addEventListener('click', event => {
        if (!dialog.showModal || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
        event.preventDefault(); display(index); dialog.showModal();
        document.body.classList.add('viewer-open');
      });
      figure.append(link, node('figcaption', '', item.title || item.alt)); grid.append(figure);
    });
  };
  const filters = document.getElementById('portfolio-filters');
  const collections = [...new Set(items.map(item => item.collection).filter(Boolean))];
  if (collections.length) {
    filters.hidden = false;
    [null, ...collections].forEach(collection => {
      const button = node('button', 'filter-button', collection || 'All photographs');
      button.type = 'button'; button.setAttribute('aria-pressed', String(collection === null));
      button.addEventListener('click', () => {
        filters.querySelectorAll('button').forEach(other => other.setAttribute('aria-pressed', String(other === button)));
        render(collection);
      });
      filters.append(button);
    });
  }
  document.getElementById('viewer-close').addEventListener('click', () => dialog.close());
  document.getElementById('viewer-prev').addEventListener('click', () => display(current - 1));
  document.getElementById('viewer-next').addEventListener('click', () => display(current + 1));
  dialog.addEventListener('keydown', event => {
    if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
      event.preventDefault(); display(current + (event.key === 'ArrowLeft' ? -1 : 1));
    }
  });
  dialog.addEventListener('close', () => document.body.classList.remove('viewer-open'));
  render(null);
})();
