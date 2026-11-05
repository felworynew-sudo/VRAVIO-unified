import { depthMap, upscaleX4, denoise, hasWebGpu, MAX_UPSCALE_IN } from './utils/aiTools.js';
import { releaseAll } from './utils/ortClient.js';
import { translator, stageLabel } from './i18n.js';
import './cutout.css';
import './ai.css';

const app = document.querySelector('#ai-app');
const TOOLS = ['depth', 'upscale', 'denoise'];
let source = null, result = null, before = null, name = 'photo.png', busy = false, stop = false;
let tool = 'depth', status = '', progress = 0, warn = false, closeArmed = false, gpu = null;
let strength = 100, clean = null, original = null; // шумоподавление: чистый результат и исходник (ImageData) для смешивания
let actual = false, scroll = [0, 0]; // просмотр 1:1 и его прокрутка
let t = translator(new URLSearchParams(location.search).get('lang') || navigator.language);

const toUrl = canvas => new Promise((resolve, reject) => canvas.toBlob(b => b ? resolve(URL.createObjectURL(b)) : reject(new Error(t('pngFailed'))), 'image/png'));
const baseName = () => name.replace(/\.[^.]*$/, '');
const clock = n => `${Math.floor(n / 60)}:${String(Math.round(n % 60)).padStart(2, '0')}`;
// Окно получает документ растра под общим именем photo.png — тогда без приставки.
const resultName = () => tool === 'depth' ? `${t('depthLayer')}.png` : tool === 'denoise' ? `${t('denoisedLayer')}.png`
  : name === 'photo.png' ? `${t('upscaledName')}.png` : `${baseName()}-${t('upscaledName')}.png`;
const idleStatus = () => gpu === null ? '' : t(gpu ? 'gpuReady' : tool === 'denoise' ? 'cpuDenoise' : 'cpuOnly');

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
  const zoomTitle = t(actual ? 'fitHint' : 'zoomHint');
  app.innerHTML = `<header><strong>${t('aiTools')} · AI</strong><button id="close" aria-label="${t('close')}" title="${t('close')}">×</button></header>
    <section class="controls"><label class="group">${t('tool')} <select id="tool" ${busy ? 'disabled' : ''}>${TOOLS.map(k => `<option value="${k}" ${tool === k ? 'selected' : ''}>${t(`${k}Tool`)}</option>`).join('')}</select></label>
    <span class="group"><label for="file">${t('photo')}</label><button id="file-button" type="button" ${busy ? 'disabled' : ''}>${t('chooseFile')}</button><input id="file" type="file" accept="image/*" hidden><span id="file-name" class="file-name"></span></span>
    ${tool === 'denoise' && clean && !busy ? `<label class="group strength">${t('strength')} <input id="strength" type="range" min="0" max="100" step="5" value="${strength}"><output id="strength-value">${strength} %</output></label>` : ''}
    <span class="hint">${t(`${tool}Hint`)}${source ? ` · ${zoomTitle}` : ''}</span></section>
    <div class="preview${actual ? ' actual' : ''}" style="--panes:${result ? 2 : 1}">${source ? `<figure><figcaption>${t('before')}</figcaption><div title="${zoomTitle}"><img src="${source}" alt="${t('before')}"></div></figure>` : `<p>${t('openRasterPhoto')}</p>`}${result ? `<figure><figcaption>${after}</figcaption><div title="${zoomTitle}"><img src="${result}" alt="${after}"></div></figure>` : ''}</div>
    <footer><span id="status"></span><progress id="progress" max="100" value="0" hidden></progress>
    <button id="run" ${!source || busy ? 'disabled' : ''}>${t('run')}</button>${busy ? `<button id="cancel">${t('cancel')}</button>` : ''}
    ${result && !busy ? `<button id="apply">${t(tool === 'upscale' ? 'newDocBeforeAfter' : 'addLayer')}</button><button id="save">${t('download')}</button>` : ''}</footer>`;
  app.querySelector('#close').onclick = close;
  app.querySelector('#tool').onchange = e => { tool = e.target.value; clearResult(); render(); if (!source) setStatus(idleStatus()); };
  app.querySelector('#file-button').onclick = () => app.querySelector('#file').click();
  app.querySelector('#file-name').textContent = source ? name : t('noFile');
  app.querySelector('#file').onchange = e => { const f = e.target.files?.[0]; if (f) setSource(f, f.name); };
  app.querySelector('#run').onclick = run;
  app.querySelector('#cancel')?.addEventListener('click', () => { stop = true; setStatus(t('stopping')); });
  app.querySelector('#apply')?.addEventListener('click', apply);
  app.querySelector('#save')?.addEventListener('click', () => { const a = document.createElement('a'); a.href = result; a.download = resultName(); a.click(); });
  const slider = app.querySelector('#strength');
  if (slider) {
    slider.oninput = () => { app.querySelector('#strength-value').textContent = `${slider.value} %`; };
    slider.onchange = () => { strength = Number(slider.value); void blend(); };
  }
  // Щелчок по снимку переключает «вписать» и 100 %; при 100 % обе панели прокручиваются вместе.
  const panes = [...app.querySelectorAll('.preview figure div')];
  panes.forEach((pane, k) => {
    pane.onclick = e => {
      const img = pane.querySelector('img');
      if (!actual && img) { // точка под курсором остаётся под курсором
        const r = img.getBoundingClientRect();
        const fx = Math.min(1, Math.max(0, (e.clientX - r.left) / r.width)), fy = Math.min(1, Math.max(0, (e.clientY - r.top) / r.height));
        actual = true; render();
        const p = app.querySelector('.preview figure div'), im = p?.querySelector('img');
        if (p && im) { scroll = [fx * im.naturalWidth - p.clientWidth / 2, fy * im.naturalHeight - p.clientHeight / 2]; syncScroll(); }
      } else { actual = false; render(); }
    };
    pane.onscroll = () => { if (!actual) return; scroll = [pane.scrollLeft, pane.scrollTop]; panes.forEach((other, i) => { if (i !== k && (other.scrollLeft !== pane.scrollLeft || other.scrollTop !== pane.scrollTop)) { other.scrollLeft = pane.scrollLeft; other.scrollTop = pane.scrollTop; } }); };
  });
  if (actual) syncScroll();
  setStatus(status, progress, warn);
  parent.postMessage({ type: 'vravio-ai-state', guard: guarded() }, location.origin);
}

function syncScroll() {
  app.querySelectorAll('.preview figure div').forEach(pane => {
    const restore = () => { pane.scrollLeft = scroll[0]; pane.scrollTop = scroll[1]; };
    restore();
    pane.querySelector('img')?.decode().then(restore, () => {});
  });
}

const guarded = () => busy || !!result;

function clearResult() {
  if (result) URL.revokeObjectURL(result);
  if (before) URL.revokeObjectURL(before);
  result = null; before = null; clean = null; original = null;
}

function setSource(blob, fileName) {
  if (source) URL.revokeObjectURL(source);
  clearResult();
  source = URL.createObjectURL(blob); name = fileName; progress = 0; render();
}

// Сила меньше 100 % — смесь с исходником: остаётся часть зерна, а мелкая текстура не замыливается.
async function blend() {
  if (!clean || !original) return;
  const k = strength / 100, mix = new ImageData(clean.width, clean.height), a = clean.data, b = original.data, m = mix.data;
  for (let i = 0; i < m.length; i++) m[i] = (i & 3) === 3 ? a[i] : b[i] + (a[i] - b[i]) * k;
  const canvas = document.createElement('canvas'); canvas.width = mix.width; canvas.height = mix.height;
  canvas.getContext('2d').putImageData(mix, 0, 0);
  const url = await toUrl(canvas);
  if (result) URL.revokeObjectURL(result);
  result = url; render();
}

async function run() {
  if (!source || busy) return;
  busy = true; stop = false; clearResult(); status = t('preparing'); progress = 0; warn = false; render();
  try {
    const image = new Image(); image.src = source; await image.decode();
    const canvas = document.createElement('canvas'); canvas.width = image.naturalWidth; canvas.height = image.naturalHeight;
    canvas.getContext('2d').drawImage(image, 0, 0);
    let started = 0;
    const hooks = {
      onStage: stage => { started = 0; setStatus(stage.endsWith('-load') ? t(stage) : `${t('processing')}: ${stageLabel(t, stage)}`, 0); },
      onProgress: fraction => {
        started ||= performance.now();
        const left = fraction > 0.02 && fraction < 1 ? (performance.now() - started) / 1000 / fraction * (1 - fraction) : 0;
        setStatus(`${t('processing')}: ${Math.round(fraction * 100)}%${left > 5 ? ` · ${t('remaining')} ${clock(left)}` : ''}`, fraction * 100);
      },
      onDownload: (got, total) => setStatus(total ? `${t('downloadingModel')}: ${Math.min(100, Math.round(got / total * 100))}%` : t('downloadingModel'), total ? got / total * 100 : 0),
      shouldStop: () => stop,
    };
    const out = tool === 'depth' ? await depthMap(canvas, hooks) : tool === 'denoise' ? await denoise(canvas, hooks) : await upscaleX4(canvas, hooks);
    if (tool === 'denoise') {
      clean = out.canvas.getContext('2d').getImageData(0, 0, canvas.width, canvas.height);
      original = canvas.getContext('2d').getImageData(0, 0, canvas.width, canvas.height);
      if (strength < 100) { busy = false; status = t('ready'); progress = 100; await blend(); return; }
    }
    result = await toUrl(out.canvas);
    if (out.before) before = await toUrl(out.before);
    busy = false;
    status = out.reduced ? `${t('ready')}. ${t('reducedForUpscale').replace('{n}', MAX_UPSCALE_IN[out.device] || MAX_UPSCALE_IN.wasm)}` : t('ready');
    warn = !!out.reduced; progress = 100; render();
  } catch (error) {
    busy = false; clean = null; original = null;
    status = stop ? t('cancelled') : `${t('error')}: ${error.message}`; progress = 0; warn = !stop; render();
  }
}

async function apply() {
  const bytes = await (await fetch(result)).arrayBuffer();
  if (tool !== 'upscale') {
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
  if (TOOLS.includes(event.data.tool)) tool = event.data.tool;
  setSource(new Blob([event.data.bytes], { type: 'image/png' }), event.data.name || 'photo.png');
  if (!busy) setStatus(idleStatus());
});
window.addEventListener('pagehide', () => { stop = true; clearResult(); if (source) URL.revokeObjectURL(source); releaseAll(); });
render();
hasWebGpu().then(found => { gpu = found; if (!busy && !result) setStatus(idleStatus()); });
