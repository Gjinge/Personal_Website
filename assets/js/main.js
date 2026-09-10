(() => {
  'use strict';
  const root = document.documentElement;
  const themeButton = document.getElementById('theme-toggle');
  const motionButton = document.getElementById('motion-toggle');
  const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
  const save = (key, value) => { try { localStorage.setItem(key, value); } catch (_) {} };

  function updateControls() {
    const light = root.dataset.theme === 'light';
    const themeLabel = `Switch to ${light ? 'dark' : 'light'} theme`;
    themeButton.setAttribute('aria-label', themeLabel);
    themeButton.title = themeLabel;
    document.querySelector('meta[name="theme-color"]').content = light ? '#f3f6fc' : '#080d17';
    motionButton.hidden = reducedMotion.matches;
    const motionLabel = root.dataset.motion === 'paused' ? 'Resume decorative motion' : 'Pause decorative motion';
    motionButton.setAttribute('aria-label', motionLabel);
    motionButton.title = motionLabel;
  }
  themeButton.addEventListener('click', () => {
    root.dataset.theme = root.dataset.theme === 'light' ? 'dark' : 'light';
    save('jg-theme', root.dataset.theme);
    updateControls();
  });
  motionButton.addEventListener('click', () => {
    root.dataset.motion = root.dataset.motion === 'paused' ? 'running' : 'paused';
    save('jg-motion', root.dataset.motion);
    updateControls();
  });
  reducedMotion.addEventListener('change', () => {
    if (reducedMotion.matches) root.dataset.motion = 'paused';
    updateControls();
  });
  document.querySelector('.display-controls').hidden = false;
  updateControls();

  const progress = document.querySelector('.reading-progress');
  const ghosts = [['var(--ghost-a)', '20px'], ['var(--ghost-b)', '34px'], ['var(--ghost-c)', '48px']]
    .map(([color, gap]) => `<span class="progress-ghost" style="--ghost:${color};--gap:${gap}"></span>`).join('');
  progress.innerHTML = `<span class="progress-track" aria-hidden="true"><span class="progress-eaten"></span><span class="progress-dots"></span><span class="progress-marks"></span>${ghosts}<span class="progress-pacman"><span class="progress-eye"></span></span></span><span class="progress-label" aria-hidden="true" hidden></span><input class="progress-seek" type="range" min="0" max="100" step="any" value="0" aria-label="Reading progress" title="Click a pellet or drag to jump through the page">`;
  progress.removeAttribute('aria-hidden');
  progress.classList.add('is-ready');
  root.classList.add('has-reading-progress');
  const progressSeek = progress.querySelector('.progress-seek');
  const marksHost = progress.querySelector('.progress-marks');
  const progressLabel = progress.querySelector('.progress-label');
  const sections = [...document.querySelectorAll('main > section[id]')];
  const scrollDistance = () => Math.max(0, root.scrollHeight - innerHeight);
  let marks = [];

  function buildMarks() {
    const distance = scrollDistance();
    const rail = Math.max(1, progress.clientWidth - 20);
    marksHost.textContent = '';
    let lastPosition = -Infinity;
    marks = [];
    sections.forEach(section => {
      const top = section.getBoundingClientRect().top + scrollY - 90;
      const fraction = distance > 0 ? Math.min(1, Math.max(0, top / distance)) : 0;
      if (fraction * rail - lastPosition < 26) return;
      lastPosition = fraction * rail;
      const dot = document.createElement('span');
      dot.className = 'progress-mark';
      dot.style.left = `calc(10px + ${fraction} * (100% - 20px))`;
      marksHost.append(dot);
      const heading = section.querySelector('h1, h2');
      marks.push({ dot, fraction, name: (heading ? heading.textContent : section.id).trim() });
    });
  }

  let scheduled = false;
  let motionTimeout;
  let lastScrollY = scrollY;
  let lastHeight = 0;
  let facing = 1;
  const updateProgress = () => {
    if (root.scrollHeight !== lastHeight) { lastHeight = root.scrollHeight; buildMarks(); }
    const distance = scrollDistance();
    const fraction = distance > 0 ? Math.min(1, Math.max(0, scrollY / distance)) : 1;
    if (scrollY > lastScrollY + 1) facing = 1;
    else if (scrollY < lastScrollY - 1) facing = -1;
    lastScrollY = scrollY;
    progress.style.setProperty('--facing', facing);
    progress.style.setProperty('--progress-x', `${2 + fraction * Math.max(0, progress.clientWidth - 20)}px`);
    progress.style.setProperty('--progress-percent', `${fraction * 100}%`);
    progress.classList.toggle('is-cleared', fraction > 0.995);
    marks.forEach(mark => mark.dot.classList.toggle('is-eaten', mark.fraction <= fraction + 0.002));
    progressSeek.value = fraction * 100;
    progressSeek.setAttribute('aria-valuetext', `${Math.round(fraction * 100)}% through the page`);
    progressSeek.disabled = distance <= 0;
    scheduled = false;
  };
  progressSeek.addEventListener('input', () => {
    scrollTo({ top: Number(progressSeek.value) / 100 * scrollDistance(), behavior: 'instant' });
    updateProgress();
  });
  if (matchMedia('(hover: hover) and (pointer: fine)').matches) {
    progressSeek.addEventListener('pointermove', event => {
      if (!marks.length) return;
      const bounds = progress.getBoundingClientRect();
      const fraction = Math.min(1, Math.max(0, (event.clientX - bounds.left - 10) / Math.max(1, bounds.width - 20)));
      let nearest = marks[0];
      marks.forEach(mark => { if (mark.fraction <= fraction + 0.015) nearest = mark; });
      progressLabel.textContent = nearest.name;
      progressLabel.hidden = false;
      progressLabel.style.left = `${Math.min(bounds.width - 14, Math.max(14, event.clientX - bounds.left))}px`;
    }, { passive: true });
    progressSeek.addEventListener('pointerleave', () => { progressLabel.hidden = true; });
    progressSeek.addEventListener('blur', () => { progressLabel.hidden = true; });
  }
  const scheduleProgress = () => {
    if (!scheduled) { scheduled = true; requestAnimationFrame(updateProgress); }
  };
  addEventListener('scroll', () => {
    scheduleProgress();
    progress.classList.add('is-moving');
    clearTimeout(motionTimeout);
    motionTimeout = setTimeout(() => progress.classList.remove('is-moving'), 200);
  }, { passive: true });
  addEventListener('resize', scheduleProgress, { passive: true });
  addEventListener('load', scheduleProgress, { once: true });
  if ('ResizeObserver' in window) new ResizeObserver(scheduleProgress).observe(document.body);
  updateProgress();


  const links = [...document.querySelectorAll('nav a[href^="#"]')];
  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver(entries => {
      const active = entries.filter(entry => entry.isIntersecting).sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0];
      if (!active) return;
      links.forEach(link => {
        if (link.hash === `#${active.target.id}`) link.setAttribute('aria-current', 'location');
        else link.removeAttribute('aria-current');
      });
    }, { rootMargin: '-18% 0px -58% 0px', threshold: 0 });
    document.querySelectorAll('main>section[id]').forEach(section => observer.observe(section));
  }

  const visual = document.querySelector('.research-visual');
  if (visual && matchMedia('(hover: hover) and (pointer: fine)').matches) {
    visual.addEventListener('pointermove', event => {
      if (reducedMotion.matches || root.dataset.motion === 'paused') return;
      const bounds = visual.getBoundingClientRect();
      visual.style.setProperty('--pointer-x', `${(event.clientX - bounds.left) / bounds.width * 100}%`);
      visual.style.setProperty('--pointer-y', `${(event.clientY - bounds.top) / bounds.height * 100}%`);
    }, { passive: true });
    visual.addEventListener('pointerleave', () => {
      visual.style.removeProperty('--pointer-x');
      visual.style.removeProperty('--pointer-y');
    });
  }
})();
