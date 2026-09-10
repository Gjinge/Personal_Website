(() => {
  'use strict';
  const frame = document.querySelector('.visitor-map');
  const content = document.getElementById('visitor-map-content');
  const status = document.getElementById('visitor-map-status');
  if (!frame || !content || !status) return;

  const identifier = 'HsiE8aqOup9YTkYnoz300AdW_yLrMN8JEbOD9BHf-X4';
  const statisticsUrl = 'https://mapmyvisitors.com/web/1c84z';
  let settled = false;
  let timeout;
  let resizeObserver;
  let lastWidth = 0;
  const notify = message => {
    status.textContent = message;
    status.hidden = !message;
  };

  function resizeMap() {
    const width = content.clientWidth;
    if (!width || Math.abs(width - lastWidth) < 1) return;
    lastWidth = width;
    // The provider's jVectorMap instance must update its projection when its
    // container changes size, including a desktop app's resizable side panel.
    const jquery = window.vmap_jq;
    const map = content.querySelector('.mapmyvisitors-map');
    if (jquery && jquery.fn.vectorMap && map) {
      const instance = jquery(map).vectorMap('get', 'mapObject');
      if (instance && typeof instance.updateSize === 'function') instance.updateSize();
    }
  }

  function ready() {
    if (settled || !content.querySelector('#mapmyvisitors-widget svg') || content.querySelector('.mapmyvisitors-loading')) return;
    settled = true;
    clearTimeout(timeout);
    observer.disconnect();
    frame.dataset.state = 'ready';
    notify('');
    const widget = content.querySelector('#mapmyvisitors-widget');
    widget.href = statisticsUrl;
    widget.setAttribute('aria-label', 'Open visitor statistics');
    resizeMap();
    if ('ResizeObserver' in window) {
      resizeObserver = new ResizeObserver(resizeMap);
      resizeObserver.observe(content);
    }
  }

  function fallback() {
    if (settled) return;
    settled = true;
    clearTimeout(timeout);
    observer.disconnect();
    content.hidden = true;
    frame.dataset.state = 'recovering';
    notify('The interactive map could not load. Loading the image version…');

    const link = document.createElement('a');
    link.className = 'visitor-fallback';
    link.href = statisticsUrl;
    link.hidden = true;
    const image = new Image();
    image.alt = 'Visitor locations on a world map. Open visitor statistics.';
    image.decoding = 'async';
    let imageSettled = false;
    const unavailable = () => {
      if (imageSettled) return;
      imageSettled = true;
      clearTimeout(imageTimeout);
      frame.dataset.state = 'unavailable';
      link.remove();
      notify('The visitor map is unavailable on this connection. You can try the visitor statistics link below.');
    };
    const imageTimeout = setTimeout(unavailable, 10000);
    image.onload = () => {
      if (imageSettled) return;
      imageSettled = true;
      clearTimeout(imageTimeout);
      link.hidden = false;
      frame.dataset.state = 'fallback';
      notify('Showing the image version. Open visitor statistics for details.');
    };
    image.onerror = unavailable;
    link.appendChild(image);
    frame.appendChild(link);
    image.src = `https://mapmyvisitors.com/map.png?d=${identifier}&cl=ffffff`;
  }

  const observer = new MutationObserver(ready);
  observer.observe(content, { childList: true, subtree: true });
  frame.dataset.state = 'loading';
  notify('Loading visitor map…');
  const script = document.createElement('script');
  script.id = 'mapmyvisitors';
  script.async = true;
  script.src = `https://mapmyvisitors.com/map.js?d=${identifier}&cl=ffffff&w=a`;
  script.onerror = fallback;
  timeout = setTimeout(fallback, 10000);
  content.appendChild(script);
})();
