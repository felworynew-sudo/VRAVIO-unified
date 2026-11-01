import { cutOut } from './utils/cutout.js';
import { translator } from './i18n.js';
import './cutout.css';

const app = document.querySelector('#cutout-app');
let source = null, result = null, name = 'photo.png', busy = false, webgpu = false;
let quality = 'fast';
const initialLocale = new URLSearchParams(location.search).get('lang') || navigator.language;
let t = translator(initialLocale);
document.documentElement.lang = initialLocale;
document.title = `VRAVIO · ${t('removeBackground')}`;

function render() {
  app.innerHTML = `<header><strong>${t('removeBackground')} · AI</strong><button id="close" aria-label="${t('close')}">×</button></header>
    <section class="controls"><label>${t('model')} <select id="quality" ${busy ? 'disabled' : ''}><option value="fast" ${quality === 'fast' ? 'selected' : ''}>${t('fastModel')}</option><option value="quality" ${quality === 'quality' ? 'selected' : ''} ${webgpu ? '' : 'disabled'}>${t('qualityModel')}</option></select></label>
    <label>${t('photo')} <input id="file" type="file" accept="image/*" ${busy ? 'disabled' : ''}></label></section>
    <div class="preview">${source ? `<img src="${source}" alt="${t('before')}">` : `<p>${t('openRasterPhoto')}</p>`}${result ? `<img src="${result}" alt="${t('noBackground')}">` : ''}</div>
    <footer><span id="status">${t(webgpu ? 'webgpuReady' : 'cpuFast')}</span><button id="run" ${!source || busy ? 'disabled' : ''}>${t('removeBackground')}</button>${result ? `<button id="apply">${t('applyMask')}</button><button id="save">${t('download')}</button>` : ''}</footer>`;
  app.querySelector('#close').onclick = () => parent.postMessage({ type: 'vravio-cutout-close' }, location.origin);
  app.querySelector('#quality').onchange = e => { quality = e.target.value; };
  app.querySelector('#file').onchange = async e => { const file = e.target.files?.[0]; if (file) setSource(file, file.name); };
  app.querySelector('#run').onclick = run;
  app.querySelector('#apply')?.addEventListener('click', async () => {
    const bytes = await (await fetch(result)).arrayBuffer();
    parent.postMessage({ type: 'vravio-cutout-result', bytes }, location.origin, [bytes]);
  });
  app.querySelector('#save')?.addEventListener('click', () => { const a = document.createElement('a'); a.href = result; a.download = `cutout-${name.replace(/\.[^.]*$/, '')}.png`; a.click(); });
}
function setSource(blob, fileName) {
  if (source) URL.revokeObjectURL(source);
  if (result) URL.revokeObjectURL(result);
  source = URL.createObjectURL(blob); result = null; name = fileName; render();
}
async function run() {
  if (!source || busy) return;
  busy = true; render();
  try {
    const canvas = await cutOut(source, quality, status => { app.querySelector('#status').textContent = status; }, t);
    const blob = await new Promise(resolve => canvas.toBlob(resolve, 'image/png'));
    if (!blob) throw new Error(t('pngFailed'));
    if (result) URL.revokeObjectURL(result);
    result = URL.createObjectURL(blob); busy = false; render(); app.querySelector('#status').textContent = t('ready');
  } catch (error) {
    busy = false; render(); app.querySelector('#status').textContent = `${t('error')}: ${error.message}`;
  }
}
window.addEventListener('message', event => {
  if (event.origin !== location.origin || event.source !== parent || event.data?.type !== 'vravio-cutout-input') return;
  t = translator(event.data.locale);
  document.documentElement.lang = event.data.locale || navigator.language;
  document.title = `VRAVIO · ${t('removeBackground')}`;
  setSource(new Blob([event.data.bytes], { type: 'image/png' }), event.data.name || 'photo.png');
});
window.addEventListener('pagehide', () => { if (source) URL.revokeObjectURL(source); if (result) URL.revokeObjectURL(result); });
render();
if (navigator.gpu) navigator.gpu.requestAdapter().then(adapter => { webgpu = !!adapter; render(); }).catch(() => {});
