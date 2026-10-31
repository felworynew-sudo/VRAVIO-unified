import { hasWebGpu, loadVetorManifest, restoreClassic, restoreVetor, toWorkCanvas, releaseAll } from './utils/photoRestore.js';

export function mountRestorer(app, { bytes, name = 'photo.png', onClose, onResult } = {}) {
  let source = null, result = null, manifest = null, busy = false, stop = false;
  let fileName = name, status = 'Подготовка моделей', progress = 0, advanced = false;
  const settings = { texture: 'vetor', repair: 'vetor', faces: 'vetor', colorize: 'auto', upscale: 'off' };
  const option = (value, label, chosen) => `<option value="${value}" ${chosen === value ? 'selected' : ''}>${label}</option>`;
  function updateStatus(label, value = progress) {
    status = label; progress = Math.min(100, Math.max(0, value));
    const text = app.querySelector('#status-text'), bar = app.querySelector('#progress');
    if (text) text.textContent = status;
    if (bar) { bar.value = progress; bar.hidden = !busy && progress === 0; }
  }
  function render() {
    app.innerHTML = `<div class="restore-panel" role="dialog" aria-modal="true" aria-label="Реставрация старых фото">
      <header><strong>Реставрация старых фото · Vetor Restore</strong><button id="close" aria-label="Закрыть">×</button></header>
      <section class="controls"><label>Фото <input id="file" type="file" accept="image/*" ${busy ? 'disabled' : ''}></label>
      <button id="advanced" aria-expanded="${advanced}">Расширенные параметры ${advanced ? '▴' : '▾'}</button></section>
      ${advanced ? `<section class="advanced">
        <label>Текстура <select data-setting="texture">${option('vetor', 'Vetor', settings.texture)}${option('off', 'Пропустить', settings.texture)}</select></label>
        <label>Дефекты <select data-setting="repair">${option('vetor', 'Vetor + достройка', settings.repair)}${option('off', 'Пропустить', settings.repair)}</select></label>
        <label>Лица <select data-setting="faces">${option('vetor', 'Vetor', settings.faces)}${option('third-party', 'RestoreFormer++', settings.faces)}${option('off', 'Пропустить', settings.faces)}</select></label>
        <label>Цвет <select data-setting="colorize">${option('auto', 'Vetor · автоматически', settings.colorize)}${option('on', 'Vetor · всегда', settings.colorize)}${option('off', 'Пропустить', settings.colorize)}</select></label>
        <label>Увеличение <select data-setting="upscale">${option('off', 'Без увеличения', settings.upscale)}${option('third-party', 'Real-ESRGAN ×4', settings.upscale)}</select></label>
      </section>` : ''}
      <div class="preview">${source ? `<img src="${source}" alt="До">` : '<p>Откройте фото в растровом редакторе или выберите файл.</p>'}${result ? `<img src="${result}" alt="После">` : ''}</div>
      <footer><div class="status"><span id="status-text"></span><progress id="progress" max="100" value="0" hidden></progress></div>
      <button id="run" ${!source || busy ? 'disabled' : ''}>Восстановить</button>${busy ? '<button id="cancel">Отменить</button>' : ''}
      ${result ? '<button id="new-doc">В новый документ · до/после</button><button id="current-doc">В текущий документ</button><button id="save">Скачать PNG</button>' : ''}</footer></div>`;
    app.querySelector('#close').onclick = () => { stop = true; onClose?.(); };
    app.querySelector('#advanced').onclick = () => { advanced = !advanced; render(); };
    app.querySelectorAll('[data-setting]').forEach(select => { select.onchange = () => { settings[select.dataset.setting] = select.value; }; });
    app.querySelector('#file').onchange = e => { const f = e.target.files?.[0]; if (f) setSource(f, f.name); };
    app.querySelector('#run').onclick = run;
    app.querySelector('#cancel')?.addEventListener('click', () => { stop = true; updateStatus('Остановка после текущего шага'); });
    for (const [id, mode] of [['new-doc', 'new'], ['current-doc', 'current']]) {
      app.querySelector(`#${id}`)?.addEventListener('click', async () => {
        const output = await (await fetch(result)).arrayBuffer();
        // File picker accepts JPEG/WebP too, while the editor bridge imports PNG.
        const originalImage = new Image();
        originalImage.src = source;
        await originalImage.decode();
        const originalCanvas = document.createElement('canvas');
        originalCanvas.width = originalImage.naturalWidth;
        originalCanvas.height = originalImage.naturalHeight;
        originalCanvas.getContext('2d').drawImage(originalImage, 0, 0);
        const originalBlob = await new Promise(resolve => originalCanvas.toBlob(resolve, 'image/png'));
        if (!originalBlob) { updateStatus('Не удалось подготовить исходное фото'); return; }
        const original = await originalBlob.arrayBuffer();
        onResult?.({ bytes: output, original, mode, name: `restored-${fileName.replace(/\.[^.]*$/, '')}.png` });
      });
    }
    app.querySelector('#save')?.addEventListener('click', () => { const a = document.createElement('a'); a.href = result; a.download = `restored-${fileName.replace(/\.[^.]*$/, '')}.png`; a.click(); });
    updateStatus(status, progress);
  }
  function setSource(blob, newName) {
    if (source) URL.revokeObjectURL(source);
    if (result) URL.revokeObjectURL(result);
    source = URL.createObjectURL(blob); result = null; fileName = newName; progress = 0;
    status = manifest?.status === 'ready' ? 'Модели доступны' : 'Проверка моделей'; render();
  }
  async function run() {
    if (!source || busy) return;
    if (manifest?.status !== 'ready') { updateStatus('Модели Vetor пока недоступны'); return; }
    busy = true; stop = false; updateStatus('Подготовка', 0); render();
    try {
      const image = new Image(); image.src = source; await image.decode();
      const { canvas, scaled } = toWorkCanvas(image, 3000);
      if (scaled) updateStatus('Большое фото уменьшено для обработки');
      const hooks = {
        onStage: stage => updateStatus(`Обработка: ${stage}`, 0),
        onProgress: fraction => updateStatus(`Обработка: ${Math.round(fraction * 100)}%`, fraction * 100),
        onDownload: (got, total) => updateStatus(total ? `Загрузка модели: ${Math.round(got / total * 100)}%` : 'Загрузка модели', total ? got / total * 100 : 0),
        shouldStop: () => stop,
      };
      const vetor = await restoreVetor(canvas, manifest, {
        strength: 1, texture: settings.texture === 'vetor', repair: settings.repair === 'vetor',
        inpaint: settings.repair === 'vetor', faces: settings.faces === 'vetor', faceStrength: 1, color: settings.colorize,
      }, hooks);
      if (stop) throw new Error('stopped');
      const output = settings.faces === 'third-party' || settings.upscale === 'third-party'
        ? await restoreClassic(vetor.canvas, { faces: settings.faces === 'third-party', faceStrength: 1, keepColor: true, upscale: settings.upscale === 'third-party' ? 'on' : 'off' }, hooks)
        : vetor;
      if (stop) throw new Error('stopped');
      const blob = await new Promise(resolve => output.canvas.toBlob(resolve, 'image/png'));
      if (!blob) throw new Error('Не удалось создать PNG');
      if (result) URL.revokeObjectURL(result);
      result = URL.createObjectURL(blob); busy = false; status = 'Готово'; progress = 100; render();
    } catch (error) {
      busy = false; status = stop ? 'Отменено' : `Ошибка: ${error.message}`; progress = 0; render();
    }
  }
  if (bytes) setSource(new Blob([bytes], { type: 'image/png' }), name); else render();
  loadVetorManifest().then(value => {
    manifest = value;
    if (!busy) updateStatus(value.status === 'ready' ? 'Модели доступны' : 'Модели Vetor недоступны');
  });
  hasWebGpu().then(gpu => { if (!gpu && !busy) updateStatus('Обработка на процессоре может занять дольше'); });
  return () => { stop = true; if (source) URL.revokeObjectURL(source); if (result) URL.revokeObjectURL(result); releaseAll(); };
}
