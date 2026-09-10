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
  progress.innerHTML = '<span class="progress-dots" aria-hidden="true"></span><span class="progress-trail" aria-hidden="true"></span><span class="progress-pacman" aria-hidden="true"><span class="progress-eye"></span></span><input class="progress-seek" type="range" min="0" max="100" step="any" value="0" aria-label="Reading progress" title="Click a dot or drag to jump through the page">';
  progress.removeAttribute('aria-hidden');
  const progressSeek = progress.querySelector('.progress-seek');
  progress.classList.add('is-ready');
  root.classList.add('has-reading-progress');
  let scheduled = false;
  let motionTimeout;
  const updateProgress = () => {
    const distance = root.scrollHeight - innerHeight;
    const fraction = distance > 0 ? Math.min(1, Math.max(0, scrollY / distance)) : 1;
    const position = 2 + fraction * Math.max(0, progress.clientWidth - 20);
    progress.style.setProperty('--progress-x', `${position}px`);
    progress.style.setProperty('--progress-percent', `${fraction * 100}%`);
    progressSeek.value = fraction * 100;
    progressSeek.setAttribute('aria-valuetext', `${Math.round(fraction * 100)}% through the page`);
    progressSeek.disabled = distance <= 0;
    scheduled = false;
  };
  progressSeek.addEventListener('input', () => {
    const fraction = Number(progressSeek.value) / 100;
    const distance = Math.max(0, root.scrollHeight - innerHeight);
    scrollTo({ top: fraction * distance, behavior: 'instant' });
    updateProgress();
  });
  const scheduleProgress = () => {
    if (!scheduled) { scheduled = true; requestAnimationFrame(updateProgress); }
  };
  addEventListener('scroll', () => {
    scheduleProgress();
    progress.classList.add('is-moving');
    clearTimeout(motionTimeout);
    motionTimeout = setTimeout(() => progress.classList.remove('is-moving'), 160);
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
