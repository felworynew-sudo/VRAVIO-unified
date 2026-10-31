import { cutOut } from './utils/cutout.js';
import './style.css';

const app = document.querySelector('#cutout-app');
let source = null, result = null, name = 'photo.png', busy = false, webgpu = false;
let quality = 'fast';

function render() {
  app.innerHTML = `<header><strong>Удалить фон · AI</strong><button id="close" aria-label="Закрыть">×</button></header>
    <section class="controls"><label>Модель <select id="quality" ${busy ? 'disabled' : ''}><option value="fast" ${quality === 'fast' ? 'selected' : ''}>Быстро · MODNet (портреты)</option><option value="quality" ${quality === 'quality' ? 'selected' : ''} ${webgpu ? '' : 'disabled'}>Качественно · BiRefNet (любые объекты)</option></select></label>
    <label>Фото <input id="file" type="file" accept="image/*" ${busy ? 'disabled' : ''}></label></section>
    <div class="preview">${source ? `<img src="${source}" alt="До">` : '<p>Откройте фото в растровом редакторе.</p>'}${result ? `<img src="${result}" alt="Без фона">` : ''}</div>
    <footer><span id="status">${webgpu ? 'WebGPU доступен' : 'Быстрый режим на процессоре'}</span><button id="run" ${!source || busy ? 'disabled' : ''}>Удалить фон</button>${result ? '<button id="apply">Применить маску к слою</button><button id="save">Скачать PNG</button>' : ''}</footer>`;
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
    const canvas = await cutOut(source, quality, status => { app.querySelector('#status').textContent = status; });
    const blob = await new Promise(resolve => canvas.toBlob(resolve, 'image/png'));
    if (!blob) throw new Error('Не удалось создать PNG');
    if (result) URL.revokeObjectURL(result);
    result = URL.createObjectURL(blob); busy = false; render(); app.querySelector('#status').textContent = 'Готово';
  } catch (error) {
    busy = false; render(); app.querySelector('#status').textContent = `Ошибка: ${error.message}`;
  }
}
window.addEventListener('message', event => {
  if (event.origin !== location.origin || event.source !== parent || event.data?.type !== 'vravio-cutout-input') return;
  setSource(new Blob([event.data.bytes], { type: 'image/png' }), event.data.name || 'photo.png');
});
window.addEventListener('pagehide', () => { if (source) URL.revokeObjectURL(source); if (result) URL.revokeObjectURL(result); });
render();
if (navigator.gpu) navigator.gpu.requestAdapter().then(adapter => { webgpu = !!adapter; render(); }).catch(() => {});
