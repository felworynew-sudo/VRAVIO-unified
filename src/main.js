const root = new URL('../', import.meta.url);
const local = path => new URL(path, root).href;
const environments = {
  raster: { name: 'Растр', icon: local('assets/raster.svg'), color: '#a100ff', path: local('editors/raster/') },
  vector: { name: 'Вектор', icon: local('assets/vector.svg'), color: '#0068ff', path: local('editors/vector/') },
  audio: { name: 'Аудио', icon: local('assets/audio.svg'), color: '#ffb600', path: local('editors/audio/') },
  video: { name: 'Видео', icon: local('assets/video.svg'), color: '#ff0000', path: `${local('editors/video/')}?empty` }
};
const storageKey = 'vravio-unified-workspace-v1';
let tabs = [];
let activeId = null;
let nextId = 1;
let chooserOpen = false;
const app = document.querySelector('#app');

function load() {
  try {
    const saved = JSON.parse(localStorage.getItem(storageKey) || '{}');
    if (Array.isArray(saved.tabs)) {
      const seen = new Set();
      tabs = saved.tabs.filter(t => {
        if (!environments[t.kind] || !Number.isInteger(t.id) || seen.has(t.kind)) return false;
        seen.add(t.kind);
        return true;
      });
      nextId = Math.max(0, ...tabs.map(t => t.id)) + 1;
      activeId = tabs.some(t => t.id === saved.activeId) ? saved.activeId : tabs[0]?.id ?? null;
    }
  } catch { /* A corrupt preference must not prevent startup. */ }
}
function save() {
  try { localStorage.setItem(storageKey, JSON.stringify({ tabs, activeId })); } catch { /* Private mode. */ }
}
function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[ch]);
}
function openTab(kind) {
  if (!environments[kind]) return;
  const existing = tabs.find(t => t.kind === kind);
  if (existing) { chooserOpen = false; selectTab(existing.id); return; }
  const id = nextId++;
  tabs.push({ id, kind, title: environments[kind].name });
  activeId = id;
  chooserOpen = false;
  save();
  render();
}
function selectTab(id) {
  if (!tabs.some(t => t.id === id)) return;
  activeId = id;
  save();
  render();
}
function closeTab(id) {
  const index = tabs.findIndex(t => t.id === id);
  if (index < 0) return;
  if (!window.confirm('Закрыть вкладку? Сохраните изменения в редакторе перед закрытием.')) return;
  tabs.splice(index, 1);
  if (activeId === id) activeId = tabs[Math.min(index, tabs.length - 1)]?.id ?? null;
  save();
  render();
}
function renameTab(id) {
  const tab = tabs.find(t => t.id === id);
  if (!tab) return;
  const name = prompt('Название вкладки', tab.title);
  if (name === null) return;
  tab.title = name.trim().slice(0, 80) || tab.title;
  save();
  render();
}
function render() {
  const active = tabs.find(t => t.id === activeId);
  if (!app.querySelector('.workarea')) app.innerHTML = `
    <header class="topbar">
      <button class="brand" id="home" title="Начальная страница"><img src="${local('assets/logo.svg')}" alt="VRAVIO"></button>
      <span class="divider"></span>
      <button class="new-button" id="new" title="Новый документ (Ctrl+N)">＋ <span>Создать</span></button>
      <div class="topbar-spacer"></div>
      <span class="environment-label"></span>
    </header>
    <nav class="tabs" aria-label="Документы"></nav>
    <main class="workarea"></main>
    <div id="modal-root"></div>`;
  app.querySelector('.environment-label').textContent = active ? environments[active.kind].name : 'Все среды';
  app.querySelector('.tabs').innerHTML = `
      ${tabs.map(t => `<div class="tab ${t.id === activeId ? 'selected' : ''}" style="--accent:${environments[t.kind].color}" data-id="${t.id}">
        <button class="tab-select" data-select="${t.id}" title="${escapeHtml(t.title)}"><img src="${environments[t.kind].icon}" alt=""><span>${escapeHtml(t.title)}</span></button>
        <button class="tab-close" data-close="${t.id}" aria-label="Закрыть ${escapeHtml(t.title)}">×</button>
      </div>`).join('')}
      <button class="tab-add" id="add" title="Добавить документ">＋</button>`;
  const workarea = app.querySelector('.workarea');
  workarea.querySelector('.welcome')?.remove();
  if (!active) workarea.insertAdjacentHTML('beforeend', `<div class="welcome"><img src="${local('assets/logo.svg')}" alt=""><h1>Начните с документа</h1><p>Четыре рабочие среды в одном окне.</p><button id="welcome-new">Создать документ</button></div>`);
  const modal = app.querySelector('#modal-root');
  modal.innerHTML = chooserOpen ? `<div class="scrim" id="scrim"><div class="dialog" role="dialog" aria-modal="true" aria-labelledby="dialog-title"><div class="dialog-head"><h2 id="dialog-title">Новый документ</h2><button id="dismiss" aria-label="Закрыть">×</button></div><p>Выберите рабочую среду</p><div class="choices">${Object.entries(environments).map(([key, e]) => `<button class="choice" data-create="${key}" style="--accent:${e.color}"><img src="${e.icon}" alt=""><span>${e.name}</span></button>`).join('')}</div></div></div>` : '';
  for (const holder of workarea.querySelectorAll('[data-frame]')) {
    const id = Number(holder.dataset.frame);
    if (!tabs.some(t => t.id === id)) { holder.remove(); frames.delete(id); }
    else holder.classList.toggle('active', id === activeId);
  }
  // A canvas stays mounted while another environment is active, preserving in-memory edits.
  for (const tab of tabs) {
    let holder = workarea.querySelector(`[data-frame="${tab.id}"]`);
    if (!holder) {
      holder = document.createElement('section');
      holder.className = `editor-frame ${tab.id === activeId ? 'active' : ''}`;
      holder.dataset.frame = String(tab.id);
      holder.setAttribute('aria-label', tab.title);
      workarea.append(holder);
      const iframe = document.createElement('iframe');
      iframe.src = environments[tab.kind].path;
      iframe.title = tab.title;
      iframe.allow = 'fullscreen; clipboard-read; clipboard-write; microphone';
      iframe.setAttribute('loading', tab.id === activeId ? 'eager' : 'lazy');
      iframe.addEventListener('load', () => {
        try {
          const child = iframe.contentWindow;
          child.open = (url, ...args) => {
            const destination = new URL(url, child.location.href);
            return destination.origin === window.location.origin ? window.open(destination.href, ...args) : null;
          };
          child.document.addEventListener('click', event => {
            const link = event.target.closest?.('a[href]');
            if (!link || link.hasAttribute('download') || link.href.startsWith('blob:')) return;
            if (new URL(link.href).origin !== window.location.origin) event.preventDefault();
          }, true);
        } catch { /* A future cross-origin editor remains usable without this guard. */ }
      });
      frames.set(tab.id, iframe);
      holder.append(iframe);
    }
  }
  app.querySelector('#new').onclick = showChooser;
  app.querySelector('#add').onclick = showChooser;
  app.querySelector('#welcome-new')?.addEventListener('click', showChooser);
  app.querySelector('#home').onclick = () => { chooserOpen = true; render(); };
  app.querySelector('#dismiss')?.addEventListener('click', hideChooser);
  app.querySelector('#scrim')?.addEventListener('click', e => { if (e.target.id === 'scrim') hideChooser(); });
  app.querySelectorAll('[data-create]').forEach(el => el.onclick = () => openTab(el.dataset.create));
  app.querySelectorAll('[data-select]').forEach(el => {
    el.onclick = () => selectTab(Number(el.dataset.select));
    el.ondblclick = () => renameTab(Number(el.dataset.select));
  });
  app.querySelectorAll('[data-close]').forEach(el => el.onclick = () => closeTab(Number(el.dataset.close)));
}
const frames = new Map();
function showChooser() { chooserOpen = true; render(); }
function hideChooser() { chooserOpen = false; render(); }
document.addEventListener('keydown', event => {
  if (event.key === 'Escape' && chooserOpen) { hideChooser(); return; }
  if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'n') { event.preventDefault(); showChooser(); }
  if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'w' && activeId !== null && !chooserOpen) { event.preventDefault(); closeTab(activeId); }
});
load();
render();
