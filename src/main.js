const root = new URL('../', import.meta.url);
const local = path => new URL(path, root).href;
const environments = {
  raster: { name: 'Растр', icon: local('assets/raster.svg'), color: '#a100ff', path: local('editors/raster/') },
  vector: { name: 'Вектор', icon: local('assets/vector.svg'), color: '#0068ff', path: local('editors/vector/') },
  audio: { name: 'Аудио', icon: local('assets/audio.svg'), color: '#ffb600', path: `${local('editors/audio/')}?empty` },
  video: { name: 'Видео', icon: local('assets/video.svg'), color: '#ff0000', path: `${local('editors/video/')}?empty` }
};
const storageKey = 'vravio-unified-workspace-v1';
let tabs = [];
let activeId = null;
let nextId = 1;
let chooserOpen = false;
let restorerSource = null;
let restoreCleanup = null;
let restoreGeneration = 0;
let rasterReady = false;
let vectorEdit = null;
let bridgeStatus = '';
let crossClipboard = null;
let audioWelcome = true;
const bridgeToken = location.hash.match(/^#bridge=([a-f0-9]{32})$/)?.[1] || null;
const bridge = bridgeToken && window.opener ? { token: bridgeToken, opener: window.opener, origin: null, payload: null, rasterReady: false, sent: false } : null;
const app = document.querySelector('#app');

function deliverBridgePhoto() {
  if (!bridge?.rasterReady || !bridge.payload || bridge.sent) return;
  const raster = tabs.find(t => t.kind === 'raster');
  const target = raster && frames.get(raster.id)?.contentWindow;
  if (!target) return;
  target.postMessage({ type: 'vravio-bridge:open', name: `vravio-bridge-${bridge.token}.png`, bytes: bridge.payload }, location.origin);
  bridge.sent = true;
  bridge.payload = null;
}
function bytesFromBase64(value) {
  const binary = atob(value);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}
function base64FromBytes(bytes) {
  let binary = '';
  for (let i = 0; i < bytes.length; i += 0x8000) binary += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return btoa(binary);
}
async function asPng(bytes, name) {
  if (name.toLowerCase().endsWith('.png') && [137, 80, 78, 71, 13, 10, 26, 10].every((v, i) => bytes[i] === v)) return bytes;
  const bitmap = await createImageBitmap(new Blob([bytes]));
  try {
    const canvas = document.createElement('canvas');
    canvas.width = bitmap.width;
    canvas.height = bitmap.height;
    canvas.getContext('2d').drawImage(bitmap, 0, 0);
    return new Uint8Array(await new Promise((resolve, reject) => canvas.toBlob(blob => blob ? blob.arrayBuffer().then(resolve, reject) : reject(new Error('Не удалось преобразовать изображение в PNG')), 'image/png')));
  } finally { bitmap.close(); }
}
async function cropTransparentPng(bytes) {
  const bitmap = await createImageBitmap(new Blob([bytes], { type: 'image/png' }));
  try {
    const canvas = document.createElement('canvas');
    canvas.width = bitmap.width;
    canvas.height = bitmap.height;
    const context = canvas.getContext('2d', { willReadFrequently: true });
    context.drawImage(bitmap, 0, 0);
    const pixels = context.getImageData(0, 0, canvas.width, canvas.height).data;
    let left = canvas.width, top = canvas.height, right = -1, bottom = -1;
    for (let y = 0; y < canvas.height; y++) for (let x = 0; x < canvas.width; x++) {
      if (pixels[(y * canvas.width + x) * 4 + 3] === 0) continue;
      left = Math.min(left, x); top = Math.min(top, y);
      right = Math.max(right, x); bottom = Math.max(bottom, y);
    }
    if (right < left) throw new Error('Выделение не содержит видимых пикселей');
    const cropped = document.createElement('canvas');
    cropped.width = right - left + 1;
    cropped.height = bottom - top + 1;
    cropped.getContext('2d').drawImage(canvas, left, top, cropped.width, cropped.height, 0, 0, cropped.width, cropped.height);
    return new Uint8Array(await new Promise((resolve, reject) => cropped.toBlob(blob => blob ? blob.arrayBuffer().then(resolve, reject) : reject(new Error('Не удалось скопировать выделение')), 'image/png')));
  } finally { bitmap.close(); }
}
function deliverVectorImage() {
  if (!vectorEdit?.payload || !rasterReady) return;
  const raster = tabs.find(t => t.kind === 'raster');
  const target = raster && frames.get(raster.id)?.contentWindow;
  if (!target) return;
  target.postMessage({ type: 'vravio-bridge:open', name: `vravio-bridge-${vectorEdit.token}.png`, bytes: vectorEdit.payload }, location.origin);
  vectorEdit.payload = null;
}
async function editVectorImage() {
  const vector = tabs.find(t => t.kind === 'vector');
  const frame = vector && frames.get(vector.id);
  const api = frame?.contentWindow?.vectorcraft;
  if (!api) { bridgeStatus = 'Векторный редактор ещё загружается'; render(); return; }
  try {
    const state = await api.inspect();
    const selected = await api.execute('links.goTo', {});
    const image = await api.execute('links.unembed', { id: selected.id });
    const payload = await asPng(bytesFromBase64(image.dataBase64), image.name);
    const token = Array.from(crypto.getRandomValues(new Uint8Array(16)), x => x.toString(16).padStart(2, '0')).join('');
    vectorEdit = { token, id: selected.id, vectorId: vector.id, documentIndex: state.activeDocument, documentTitle: state.documents?.[state.activeDocument]?.title, payload };
    bridgeStatus = 'Изображение открывается в растре. Ctrl+S вернёт правку в вектор.';
    rasterReady = Boolean(tabs.find(t => t.kind === 'raster') && rasterReady);
    openTab('raster');
    deliverVectorImage();
  } catch (error) {
    bridgeStatus = `Выделите встроенное изображение: ${error.message}`;
    render();
  }
}
async function returnVectorImage(message) {
  if (!vectorEdit || message.token !== vectorEdit.token) return;
  const raster = tabs.find(t => t.kind === 'raster');
  if (frames.get(raster?.id)?.contentWindow !== message.source) return;
  const vector = tabs.find(t => t.id === vectorEdit.vectorId);
  const api = vector && frames.get(vector.id)?.contentWindow?.vectorcraft;
  if (!api) { bridgeStatus = 'Векторная среда закрыта. Изменения остались в растровой вкладке.'; render(); return; }
  try {
    const bytes = message.bytes instanceof ArrayBuffer ? new Uint8Array(message.bytes) : message.bytes;
    if (!(bytes instanceof Uint8Array) || ![137, 80, 78, 71, 13, 10, 26, 10].every((v, i) => bytes[i] === v)) throw new Error('Растровый редактор вернул некорректный PNG');
    const state = await api.inspect();
    if (state.activeDocument !== vectorEdit.documentIndex || state.documents?.[state.activeDocument]?.title !== vectorEdit.documentTitle) throw new Error('Сначала вернитесь к исходному векторному документу');
    await api.execute('links.goTo', { id: vectorEdit.id });
    const result = await api.execute('file.place', { name: 'vravio-edited.png', dataBase64: base64FromBytes(bytes), replace: true });
    vectorEdit.id = result.ids?.[0] ?? vectorEdit.id;
    bridgeStatus = 'Правка применена в векторном документе. Сохраните его для записи на диск.';
    selectTab(vector.id);
  } catch (error) { bridgeStatus = `Не удалось заменить изображение: ${error.message}`; render(); }
}
function announceBridge() {
  if (!bridge || bridge.origin) return;
  try { if (!bridge.opener.closed) bridge.opener.postMessage({ type: 'vravio-bridge:ready', version: 1, token: bridge.token }, '*'); } catch { /* opener was closed */ }
}
if (bridge) { announceBridge(); setInterval(announceBridge, 1000); }

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
  const closedKind = tabs[index].kind;
  tabs.splice(index, 1);
  if (vectorEdit && (vectorEdit.vectorId === id || closedKind === 'raster')) vectorEdit = null;
  if (closedKind === 'raster') rasterReady = false;
  if (closedKind === 'audio') audioWelcome = true;
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
  if (bridge) app.querySelector('.tabs').insertAdjacentHTML('beforeend', '<span class="bridge-label" title="Ctrl+S отправит результат в сортировщик">Связано с сортировщиком · Ctrl+S для возврата</span>');
  if (active?.kind === 'vector') app.querySelector('.tabs').insertAdjacentHTML('beforeend', '<button class="vector-edit" title="Открыть выделенное встроенное изображение в растровой среде">Редактировать изображение в растре</button>');
  if (bridgeStatus) app.querySelector('.tabs').insertAdjacentHTML('beforeend', `<span class="bridge-status" role="status"></span>`);
  if (bridgeStatus) app.querySelector('.bridge-status').textContent = bridgeStatus;
  const workarea = app.querySelector('.workarea');
  workarea.querySelector('.welcome')?.remove();
  workarea.querySelector('.audio-welcome')?.remove();
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
            if (tab.kind === 'audio' && audioWelcome) { audioWelcome = false; app.querySelector('.audio-welcome')?.remove(); }
            const link = event.target.closest?.('a[href]');
            if (!link || link.hasAttribute('download') || link.href.startsWith('blob:')) return;
            if (new URL(link.href).origin !== window.location.origin) event.preventDefault();
          }, true);
          // Keep editor shortcuts inside the app. Browsers otherwise claim
          // Ctrl+N/O/S/W before the canvas-based editors can handle them.
          child.document.addEventListener('keydown', event => {
            if (!(event.ctrlKey || event.metaKey)) return;
            const key = event.key.toLowerCase();
            if (tab.kind === 'vector' && key === 'c' && !event.shiftKey) {
              const api = child.vectorcraft;
              crossClipboard = api?.execute('document.serialize', { format: 'png', selectedOnly: true }).then(result => cropTransparentPng(bytesFromBase64(result.dataBase64))).catch(() => null) ?? null;
            } else if (tab.kind !== 'vector' && (key === 'c' || key === 'x')) {
              crossClipboard = null;
            }
            if (tab.kind === 'raster' && key === 'v' && crossClipboard) {
              event.preventDefault();
              event.stopImmediatePropagation();
              void crossClipboard.then(bytes => {
                if (!bytes) return;
                child.postMessage({ type: 'vravio-restorer-result', mode: 'current', name: 'vector-selection.png', bytes }, location.origin);
              });
              return;
            }
            if (['n', 'o', 's', 'w'].includes(key)) {
              event.preventDefault();
            }
          }, true);
          if (tab.id === activeId) { child.focus(); child.document.querySelector('canvas[tabindex]')?.focus(); }
        } catch { /* A future cross-origin editor remains usable without this guard. */ }
      });
      frames.set(tab.id, iframe);
      holder.append(iframe);
    }
    holder.setAttribute('aria-label', environments[tab.kind].name);
    frames.get(tab.id).title = environments[tab.kind].name;
  }
  app.querySelector('#add').onclick = showChooser;
  if (active?.kind === 'audio' && audioWelcome) {
    workarea.insertAdjacentHTML('beforeend', `<div class="audio-welcome"><h1>VRAVIO</h1><p>Начните работу со звуком: создайте сессию или откройте существующую.</p><div><button data-audio-action="n">Новая сессия…</button><button data-audio-action="o">Открыть…</button></div></div>`);
    workarea.querySelectorAll('[data-audio-action]').forEach(button => button.onclick = () => {
      const key = button.dataset.audioAction;
      const child = frames.get(active.id)?.contentWindow;
      const canvas = child?.document.querySelector('canvas[tabindex]');
      audioWelcome = false;
      workarea.querySelector('.audio-welcome')?.remove();
      canvas?.focus();
      canvas?.dispatchEvent(new KeyboardEvent('keydown', { key, code: `Key${key.toUpperCase()}`, ctrlKey: true, bubbles: true, cancelable: true }));
    });
  }
  app.querySelector('.vector-edit')?.addEventListener('click', editVectorImage);
  app.querySelector('#welcome-new')?.addEventListener('click', showChooser);
  app.querySelector('#dismiss')?.addEventListener('click', hideChooser);
  app.querySelector('#scrim')?.addEventListener('click', e => { if (e.target.id === 'scrim') hideChooser(); });
  app.querySelectorAll('[data-create]').forEach(el => el.onclick = () => openTab(el.dataset.create));
  app.querySelectorAll('[data-select]').forEach(el => {
    el.onclick = () => selectTab(Number(el.dataset.select));
  });
  app.querySelectorAll('[data-close]').forEach(el => el.onclick = () => closeTab(Number(el.dataset.close)));
  if (active && !chooserOpen) {
    const child = frames.get(active.id)?.contentWindow;
    child?.focus();
    try { child?.document.querySelector('canvas[tabindex]')?.focus(); } catch { /* Cross-origin editor. */ }
  }
}
const frames = new Map();
function showChooser() { chooserOpen = true; render(); }
function hideChooser() { chooserOpen = false; render(); }
function closeRestorer() {
  restoreGeneration++;
  restoreCleanup?.();
  restoreCleanup = null;
  document.querySelector('#restorer-root')?.replaceChildren();
  restorerSource = null;
}
document.addEventListener('keydown', event => {
  if (event.key === 'Escape' && document.querySelector('#restorer-root .restore-scrim')) {
    event.preventDefault(); closeRestorer(); return;
  }
  if (event.key === 'Escape' && chooserOpen) { hideChooser(); return; }
  if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'n') { event.preventDefault(); showChooser(); }
  if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'w' && activeId !== null && !chooserOpen) { event.preventDefault(); closeTab(activeId); }
});
window.addEventListener('beforeunload', event => {
  if (!tabs.length) return;
  event.preventDefault();
  event.returnValue = '';
});
window.addEventListener('message', event => {
  const message = event.data;
  if (bridge && event.source === bridge.opener && message?.type === 'vravio-bridge:open') {
    if (message.version !== 1 || message.token !== bridge.token || (bridge.origin && event.origin !== bridge.origin)) return;
    const bytes = message.bytes instanceof ArrayBuffer ? new Uint8Array(message.bytes) : message.bytes;
    if (!(bytes instanceof Uint8Array) || bytes.byteLength > 100_000_000 || bytes.byteLength < 8 || ![137,80,78,71,13,10,26,10].every((n, i) => bytes[i] === n)) return;
    bridge.origin = event.origin;
    bridge.payload = bytes;
    bridge.sent = false;
    openTab('raster');
    deliverBridgePhoto();
    return;
  }
  if (event.origin !== location.origin) return;
  if (message?.type === 'vravio-bridge:raster-ready') {
    const raster = tabs.find(t => t.kind === 'raster');
    if (raster && frames.get(raster.id)?.contentWindow === event.source) { rasterReady = true; if (bridge) bridge.rasterReady = true; deliverBridgePhoto(); deliverVectorImage(); }
    return;
  }
  if (vectorEdit && message?.type === 'vravio-bridge:saved' && message.token === vectorEdit.token) {
    void returnVectorImage({ ...message, source: event.source });
    return;
  }
  if (bridge && message?.type === 'vravio-bridge:saved') {
    const raster = tabs.find(t => t.kind === 'raster');
    if (!raster || frames.get(raster.id)?.contentWindow !== event.source || message.token !== bridge.token || !bridge.origin) return;
    try { bridge.opener.postMessage({ type: 'vravio-bridge:saved', version: 1, token: bridge.token, bytes: message.bytes }, bridge.origin); } catch { /* opener was closed */ }
    return;
  }
  if (message?.type === 'vravio-restorer-open' || message?.type === 'vravio-cutout-open') {
    const raster = tabs.find(t => t.kind === 'raster');
    if (!raster || frames.get(raster.id)?.contentWindow !== event.source) return;
    restorerSource = event.source;
    const root = document.querySelector('#restorer-root');
    const cutout = message.type === 'vravio-cutout-open';
    closeRestorer();
    restorerSource = event.source;
    const generation = restoreGeneration;
    root.innerHTML = `<div class="restore-scrim"><button class="restore-dismiss" aria-label="Закрыть окно" title="Закрыть">×</button>${cutout ? '<iframe title="Удалить фон"></iframe>' : `<div id="restore-app" data-base="${local('restorer/')}"><div class="restore-loading">Открываем реставрацию…</div></div>`}</div>`;
    root.querySelector('.restore-dismiss').onclick = closeRestorer;
    root.querySelector('.restore-scrim').addEventListener('click', e => { if (e.target.classList.contains('restore-scrim')) closeRestorer(); });
    if (cutout) {
      const frame = root.querySelector('iframe');
      frame.onload = () => frame.contentWindow.postMessage({ type: 'vravio-cutout-input', bytes: message.bytes, name: 'photo.png' }, location.origin);
      frame.src = local('restorer/cutout/');
    } else {
      import(local('restorer/embedded.js')).then(() => {
        if (generation !== restoreGeneration) return;
        restoreCleanup = window.__vravioMountRestorer(root.querySelector('#restore-app'), {
          bytes: message.bytes, name: 'photo.png', onClose: closeRestorer,
          onResult: ({ bytes, original, mode, name }) => {
            restorerSource?.postMessage({ type: 'vravio-restorer-result', bytes, original, mode, name }, location.origin, [bytes, original]);
            closeRestorer();
          },
        });
      }).catch(error => {
        if (generation === restoreGeneration) root.querySelector('#restore-app').textContent = `Не удалось открыть реставрацию: ${error.message}`;
      });
    }
    return;
  }
  if (['vravio-restorer-close', 'vravio-restorer-result', 'vravio-cutout-close', 'vravio-cutout-result'].includes(message?.type)) {
    const frame = document.querySelector('#restorer-root iframe');
    if (frame?.contentWindow !== event.source) return;
    if (message.type === 'vravio-restorer-result' || message.type === 'vravio-cutout-result') restorerSource?.postMessage(message, location.origin);
    closeRestorer();
  }
});
load();
render();
