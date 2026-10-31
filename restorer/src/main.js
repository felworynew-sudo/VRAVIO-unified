import { hasWebGpu, loadVetorManifest, restoreClassic, restoreVetor, toWorkCanvas, releaseAll } from './utils/photoRestore.js';
import './style.css';

const app = document.querySelector('#restore-app');
let source = null;
let result = null;
let manifest = null;
let busy = false;
let stop = false;
let mode = 'vetor';
let fileName = 'photo.png';

function render() {
  app.innerHTML = `<header><strong>Реставрация старых фото</strong><button id="close" aria-label="Закрыть">×</button></header>
    <section class="controls"><label>Режим <select id="mode" ${busy ? 'disabled' : ''}><option value="vetor" ${mode === 'vetor' ? 'selected' : ''}>VRAVIO Restore</option><option value="classic" ${mode === 'classic' ? 'selected' : ''}>Классический</option></select></label>
    <label>Фото <input id="file" type="file" accept="image/*" ${busy ? 'disabled' : ''}></label>
    <label><input id="faces" type="checkbox" checked> Восстановить лица</label><label><input id="upscale" type="checkbox"> Увеличить ×4</label></section>
    <div class="preview">${source ? `<img src="${source}" alt="Исходное фото">` : '<p>Откройте фото в растровом редакторе или выберите файл.</p>'}${result ? `<img src="${result}" alt="Результат">` : ''}</div>
    <footer><span id="status">${manifest?.status === 'ready' ? 'Модель готова' : 'Модель загружается'}</span><button id="run" ${!source || busy ? 'disabled' : ''}>Восстановить</button>${busy ? '<button id="cancel">Отменить</button>' : ''}${result ? '<button id="apply">Открыть результат в редакторе</button><button id="save">Скачать PNG</button>' : ''}</footer>`;
  app.querySelector('#close').onclick = () => parent.postMessage({ type: 'vravio-restorer-close' }, location.origin);
  app.querySelector('#mode').onchange = e => { mode = e.target.value; };
  app.querySelector('#file').onchange = async e => { const f = e.target.files?.[0]; if (f) await setSource(f, f.name); };
  app.querySelector('#run').onclick = run;
  app.querySelector('#cancel')?.addEventListener('click', () => { stop = true; });
  app.querySelector('#apply')?.addEventListener('click', async () => {
    const bytes = await (await fetch(result)).arrayBuffer();
    parent.postMessage({ type: 'vravio-restorer-result', bytes, name: `restored-${fileName.replace(/\.[^.]*$/, '')}.png` }, location.origin, [bytes]);
  });
  app.querySelector('#save')?.addEventListener('click', () => { const a = document.createElement('a'); a.href = result; a.download = `restored-${fileName.replace(/\.[^.]*$/, '')}.png`; a.click(); });
}

async function setSource(blob, name) {
  if (source) URL.revokeObjectURL(source);
  if (result) URL.revokeObjectURL(result);
  source = URL.createObjectURL(blob); result = null; fileName = name;
  render();
}

async function run() {
  if (!source || busy) return;
  const choice = mode;
  const faces = app.querySelector('#faces').checked;
  const upscale = app.querySelector('#upscale').checked;
  busy = true; stop = false; render();
  const status = app.querySelector('#status');
  try {
    const image = new Image();
    image.src = source; await image.decode();
    const { canvas, scaled } = toWorkCanvas(image, choice === 'vetor' ? 3000 : 4096);
    if (scaled) status.textContent = 'Большое изображение уменьшено для обработки';
    const hooks = {
      onStage: stage => { status.textContent = `Обработка: ${stage}`; },
      onProgress: fraction => { status.textContent = `Обработка: ${Math.round(fraction * 100)}%`; },
      onDownload: (got, total) => { status.textContent = `Загрузка модели: ${Math.round(got / total * 100)}%`; },
      shouldStop: () => stop,
    };
    const output = choice === 'vetor'
      ? await restoreVetor(canvas, manifest, { strength: 1, texture: true, repair: true, inpaint: true, faces, faceStrength: 1, color: 'auto' }, hooks)
      : await restoreClassic(canvas, { faces, faceStrength: 1, keepColor: true, upscale: upscale ? 'on' : 'off' }, hooks);
    const blob = await new Promise(resolve => output.canvas.toBlob(resolve, 'image/png'));
    if (!blob) throw new Error('PNG encoding failed');
    if (result) URL.revokeObjectURL(result);
    result = URL.createObjectURL(blob);
    busy = false; render(); app.querySelector('#status').textContent = 'Готово';
  } catch (error) {
    busy = false; render(); app.querySelector('#status').textContent = stop ? 'Отменено' : `Ошибка: ${error.message}`;
  }
}

window.addEventListener('message', async event => {
  if (event.origin !== location.origin || event.source !== parent || event.data?.type !== 'vravio-restorer-input') return;
  await setSource(new Blob([event.data.bytes], { type: 'image/png' }), event.data.name || 'photo.png');
});
window.addEventListener('pagehide', () => { releaseAll(); if (source) URL.revokeObjectURL(source); if (result) URL.revokeObjectURL(result); });
render();
loadVetorManifest().then(value => { manifest = value; render(); });
hasWebGpu().then(gpu => { if (!gpu) app.querySelector('#status').textContent = 'Обработка на процессоре может занять больше времени'; });
