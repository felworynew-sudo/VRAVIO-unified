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
let restorerSource = null;
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
function openTab(kind) {
  if (!environments[kind]) return;
  const existing = tabs.find(t => t.kind === kind);
  if (existing) { chooserOpen = false; selectTab(existing.id); return; }
  const id = nextId++;
  tabs.push({ id, kind });
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
  if (!window.confirm('Закрыть рабочую среду? Сохраните документы в редакторе перед закрытием.')) return;
  tabs.splice(index, 1);
  if (activeId === id) activeId = tabs[Math.min(index, tabs.length - 1)]?.id ?? null;
  save();
  render();
}
function render() {
  const active = tabs.find(t => t.id === activeId);
  if (!app.querySelector('.workarea')) app.innerHTML = `
    <nav class="tabs" aria-label="Рабочие среды"></nav>
    <main class="workarea"></main>
    <div id="modal-root"></div><div id="restorer-root"></div>`;
  app.querySelector('.tabs').innerHTML = `
      ${tabs.map(t => `<div class="tab ${t.id === activeId ? 'selected' : ''}" style="--accent:${environments[t.kind].color}" data-id="${t.id}">
        <button class="tab-select" data-select="${t.id}" title="${environments[t.kind].name}"><img src="${environments[t.kind].icon}" alt=""><span>${environments[t.kind].name}</span></button>
        <button class="tab-close" data-close="${t.id}" aria-label="Закрыть среду ${environments[t.kind].name}">×</button>
      </div>`).join('')}
      <button class="tab-add" id="add" title="Открыть рабочую среду" aria-label="Открыть рабочую среду">＋</button>`;
  const workarea = app.querySelector('.workarea');
  workarea.querySelector('.welcome')?.remove();
  if (!active) workarea.insertAdjacentHTML('beforeend', `<div class="welcome"><img src="${local('assets/logo.svg')}" alt="VRAVIO"><h1>Выберите рабочую среду</h1><p>Растр, вектор, аудио и видео в одном окне.</p><button id="welcome-new">Открыть среду</button></div>`);
  const modal = app.querySelector('#modal-root');
  modal.innerHTML = chooserOpen ? `<div class="scrim" id="scrim"><div class="dialog" role="dialog" aria-modal="true" aria-labelledby="dialog-title"><div class="dialog-head"><h2 id="dialog-title">Открыть рабочую среду</h2><button id="dismiss" aria-label="Закрыть">×</button></div><p>Документы создаются внутри выбранного редактора.</p><div class="choices">${Object.entries(environments).map(([key, e]) => `<button class="choice" data-create="${key}" style="--accent:${e.color}"><img src="${e.icon}" alt=""><span>${e.name}</span></button>`).join('')}</div></div></div>` : '';
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
      holder.setAttribute('aria-label', environments[tab.kind].name);
      workarea.append(holder);
      const iframe = document.createElement('iframe');
      iframe.src = environments[tab.kind].path;
      iframe.title = environments[tab.kind].name;
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
    holder.setAttribute('aria-label', environments[tab.kind].name);
    frames.get(tab.id).title = environments[tab.kind].name;
  }
  app.querySelector('#add').onclick = showChooser;
  app.querySelector('#welcome-new')?.addEventListener('click', showChooser);
  app.querySelector('#dismiss')?.addEventListener('click', hideChooser);
  app.querySelector('#scrim')?.addEventListener('click', e => { if (e.target.id === 'scrim') hideChooser(); });
  app.querySelectorAll('[data-create]').forEach(el => el.onclick = () => openTab(el.dataset.create));
  app.querySelectorAll('[data-select]').forEach(el => {
    el.onclick = () => selectTab(Number(el.dataset.select));
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
window.addEventListener('message', event => {
  if (event.origin !== location.origin) return;
  const message = event.data;
  if (message?.type === 'vravio-restorer-open' || message?.type === 'vravio-cutout-open') {
    const raster = tabs.find(t => t.kind === 'raster');
    if (!raster || frames.get(raster.id)?.contentWindow !== event.source) return;
    restorerSource = event.source;
    const root = document.querySelector('#restorer-root');
    const cutout = message.type === 'vravio-cutout-open';
    root.innerHTML = `<div class="restore-scrim"><iframe title="${cutout ? 'Удалить фон' : 'Реставрация старых фото'}"></iframe></div>`;
    const frame = root.querySelector('iframe');
    frame.onload = () => frame.contentWindow.postMessage({ type: cutout ? 'vravio-cutout-input' : 'vravio-restorer-input', bytes: message.bytes, name: 'photo.png' }, location.origin);
    frame.src = local(cutout ? 'restorer/cutout/' : 'restorer/');
  }
  if (['vravio-restorer-close', 'vravio-restorer-result', 'vravio-cutout-close', 'vravio-cutout-result'].includes(message?.type)) {
    const frame = document.querySelector('#restorer-root iframe');
    if (frame?.contentWindow !== event.source) return;
    if (message.type === 'vravio-restorer-result' || message.type === 'vravio-cutout-result') restorerSource?.postMessage(message, location.origin);
    document.querySelector('#restorer-root').replaceChildren();
    restorerSource = null;
  }
});
load();
render();
