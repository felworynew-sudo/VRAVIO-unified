import { depthMap, upscaleX4, hasWebGpu, MAX_UPSCALE_IN } from './utils/aiTools.js';
import { releaseAll } from './utils/ortClient.js';
import { translator, stageLabel } from './i18n.js';
import './cutout.css';
import './ai.css';

const app = document.querySelector('#ai-app');
let source = null, result = null, before = null, name = 'photo.png', busy = false, stop = false;
let tool = 'depth', status = '', progress = 0, warn = false, closeArmed = false;
let t = translator(new URLSearchParams(location.search).get('lang') || navigator.language);

const toUrl = canvas => new Promise((resolve, reject) => canvas.toBlob(b => b ? resolve(URL.createObjectURL(b)) : reject(new Error(t('pngFailed'))), 'image/png'));
const baseName = () => name.replace(/\.[^.]*$/, '');
// Окно получает документ растра под общим именем photo.png — тогда без приставки.
const resultName = () => tool === 'depth' ? `${t('depthLayer')}.png` : name === 'photo.png' ? `${t('upscaledName')}.png` : `${baseName()}-${t('upscaledName')}.png`;

function setStatus(text, value = progress, isWarning = false) {
  if (closeArmed && !isWarning) { text = status; isWarning = true; } // предупреждение о закрытии не перебивается ходом счёта
  status = text; progress = value; warn = isWarning;
  const s = app.querySelector('#status'), bar = app.querySelector('#progress');
  if (s) { s.textContent = status; s.classList.toggle('warn', warn); }
  if (bar) { bar.value = progress; bar.hidden = !busy; }
}

function render() {
  closeArmed = false;
  document.title = `VRAVIO · ${t('aiTools')}`;
  const after = t(tool === 'depth' ? 'depthLayer' : 'after');
  app.innerHTML = `<header><strong>${t('aiTools')} · AI</strong><button id="close" aria-label="${t('close')}" title="${t('close')}">×</button></header>
    <section class="controls"><label class="group">${t('tool')} <select id="tool" ${busy ? 'disabled' : ''}><option value="depth" ${tool === 'depth' ? 'selected' : ''}>${t('depthTool')}</option><option value="upscale" ${tool === 'upscale' ? 'selected' : ''}>${t('upscaleTool')}</option></select></label>
    <span class="group"><label for="file">${t('photo')}</label><button id="file-button" type="button" ${busy ? 'disabled' : ''}>${t('chooseFile')}</button><input id="file" type="file" accept="image/*" hidden><span id="file-name" class="file-name"></span></span>
    <span class="hint">${t(tool === 'depth' ? 'depthHint' : 'upscaleHint')}</span></section>
    <div class="preview" style="--panes:${result ? 2 : 1}">${source ? `<figure><figcaption>${t('before')}</figcaption><div><img src="${source}" alt="${t('before')}"></div></figure>` : `<p>${t('openRasterPhoto')}</p>`}${result ? `<figure><figcaption>${after}</figcaption><div><img src="${result}" alt="${after}"></div></figure>` : ''}</div>
    <footer><span id="status"></span><progress id="progress" max="100" value="0" hidden></progress>
    <button id="run" ${!source || busy ? 'disabled' : ''}>${t('run')}</button>${busy ? `<button id="cancel">${t('cancel')}</button>` : ''}
    ${result && !busy ? `<button id="apply">${t(tool === 'depth' ? 'addLayer' : 'newDocBeforeAfter')}</button><button id="save">${t('download')}</button>` : ''}</footer>`;
  app.querySelector('#close').onclick = close;
  app.querySelector('#tool').onchange = e => { tool = e.target.value; clearResult(); render(); };
  app.querySelector('#file-button').onclick = () => app.querySelector('#file').click();
  app.querySelector('#file-name').textContent = source ? name : t('noFile');
  app.querySelector('#file').onchange = e => { const f = e.target.files?.[0]; if (f) setSource(f, f.name); };
  app.querySelector('#run').onclick = run;
  app.querySelector('#cancel')?.addEventListener('click', () => { stop = true; setStatus(t('stopping')); });
  app.querySelector('#apply')?.addEventListener('click', apply);
  app.querySelector('#save')?.addEventListener('click', () => { const a = document.createElement('a'); a.href = result; a.download = resultName(); a.click(); });
  setStatus(status, progress, warn);
  parent.postMessage({ type: 'vravio-ai-state', guard: guarded() }, location.origin);
}

const guarded = () => busy || !!result;

function clearResult() {
  if (result) URL.revokeObjectURL(result);
  if (before) URL.revokeObjectURL(before);
  result = null; before = null;
}

function setSource(blob, fileName) {
  if (source) URL.revokeObjectURL(source);
  clearResult();
  source = URL.createObjectURL(blob); name = fileName; progress = 0; render();
}

async function run() {
  if (!source || busy) return;
  busy = true; stop = false; clearResult(); status = t('preparing'); progress = 0; warn = false; render();
  try {
    const image = new Image(); image.src = source; await image.decode();
    const canvas = document.createElement('canvas'); canvas.width = image.naturalWidth; canvas.height = image.naturalHeight;
    canvas.getContext('2d').drawImage(image, 0, 0);
    const hooks = {
      onStage: stage => setStatus(stage.endsWith('-load') ? t(stage) : `${t('processing')}: ${stageLabel(t, stage)}`, 0),
      onProgress: fraction => setStatus(`${t('processing')}: ${Math.round(fraction * 100)}%`, fraction * 100),
      onDownload: (got, total) => setStatus(total ? `${t('downloadingModel')}: ${Math.min(100, Math.round(got / total * 100))}%` : t('downloadingModel'), total ? got / total * 100 : 0),
      shouldStop: () => stop,
    };
    const out = tool === 'depth' ? await depthMap(canvas, hooks) : await upscaleX4(canvas, hooks);
    result = await toUrl(out.canvas);
    if (out.before) before = await toUrl(out.before);
    busy = false;
    status = out.reduced ? `${t('ready')}. ${t('reducedForUpscale').replace('{n}', MAX_UPSCALE_IN[out.device] || MAX_UPSCALE_IN.wasm)}` : t('ready');
    warn = !!out.reduced; progress = 100; render();
  } catch (error) {
    busy = false; status = stop ? t('cancelled') : `${t('error')}: ${error.message}`; progress = 0; warn = !stop; render();
  }
}

async function apply() {
  const bytes = await (await fetch(result)).arrayBuffer();
  if (tool === 'depth') {
    parent.postMessage({ type: 'vravio-restorer-result', mode: 'current', name: resultName(), bytes }, location.origin, [bytes]);
  } else {
    const original = await (await fetch(before)).arrayBuffer();
    parent.postMessage({ type: 'vravio-restorer-result', mode: 'new', name: resultName(), bytes, original }, location.origin, [bytes, original]);
  }
}

// Закрытие не должно молча терять минуту счёта или готовый результат: первое нажатие предупреждает, второе закрывает.
function close() {
  if (guarded() && !closeArmed) {
    closeArmed = true;
    setStatus(t(busy ? 'busyClose' : 'unsavedClose'), progress, true);
    return;
  }
  stop = true;
  parent.postMessage({ type: 'vravio-ai-close' }, location.origin);
}
document.addEventListener('keydown', event => { if (event.key === 'Escape') { event.preventDefault(); close(); } });

window.addEventListener('message', event => {
  if (event.origin !== location.origin || event.source !== parent) return;
  if (event.data?.type === 'vravio-ai-close-request') { close(); return; }
  if (event.data?.type !== 'vravio-ai-input') return;
  t = translator(event.data.locale);
  document.documentElement.lang = event.data.locale || navigator.language;
  setSource(new Blob([event.data.bytes], { type: 'image/png' }), event.data.name || 'photo.png');
});
window.addEventListener('pagehide', () => { stop = true; clearResult(); if (source) URL.revokeObjectURL(source); releaseAll(); });
render();
hasWebGpu().then(gpu => { if (!busy && !result) setStatus(t(gpu ? 'gpuReady' : 'cpuOnly')); });
