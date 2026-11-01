import { hasWebGpu, loadVetorManifest, restoreClassic, restoreVetor, toWorkCanvas, releaseAll } from './utils/photoRestore.js';
import { translator, stageLabel } from './i18n.js';

export function mountRestorer(app, { bytes, name = 'photo.png', locale, onClose, onResult } = {}) {
  const t = translator(locale);
  let source = null, result = null, manifest = null, busy = false, stop = false;
  let fileName = name, status = t('preparingModels'), progress = 0, advanced = false;
  const settings = { texture: 'vetor', repair: 'vetor', faces: 'vetor', colorize: 'auto', upscale: 'off' };
  const option = (value, label, chosen) => `<option value="${value}" ${chosen === value ? 'selected' : ''}>${label}</option>`;
  function updateStatus(label, value = progress) {
    status = label; progress = Math.min(100, Math.max(0, value));
    const text = app.querySelector('#status-text'), bar = app.querySelector('#progress');
    if (text) text.textContent = status;
    if (bar) { bar.value = progress; bar.hidden = !busy && progress === 0; }
  }
  function render() {
    app.innerHTML = `<div class="restore-panel" role="dialog" aria-modal="true" aria-label="${t('title')}">
      <header><strong>${t('title')} · Vetor Restore</strong><button id="close" aria-label="${t('close')}">×</button></header>
      <section class="controls"><label for="file">${t('photo')}</label><button id="file-button" type="button" ${busy ? 'disabled' : ''}>${t('chooseFile')}</button><input id="file" type="file" accept="image/*" hidden><span id="file-name" class="file-name"></span>
      <button id="advanced" aria-expanded="${advanced}">${t('advanced')} ${advanced ? '▴' : '▾'}</button></section>
      ${advanced ? `<section class="advanced">
        <label>${t('texture')} <select data-setting="texture">${option('vetor', 'Vetor', settings.texture)}${option('off', t('skip'), settings.texture)}</select></label>
        <label>${t('defects')} <select data-setting="repair">${option('vetor', t('reconstruct'), settings.repair)}${option('off', t('skip'), settings.repair)}</select></label>
        <label>${t('faces')} <select data-setting="faces">${option('vetor', 'Vetor', settings.faces)}${option('third-party', 'RestoreFormer++', settings.faces)}${option('off', t('skip'), settings.faces)}</select></label>
        <label>${t('color')} <select data-setting="colorize">${option('auto', t('automatic'), settings.colorize)}${option('on', t('always'), settings.colorize)}${option('off', t('skip'), settings.colorize)}</select></label>
        <label>${t('upscale')} <select data-setting="upscale">${option('off', t('noUpscale'), settings.upscale)}${option('third-party', 'Real-ESRGAN ×4', settings.upscale)}</select></label>
      </section>` : ''}
      <div class="preview">${source ? `<img src="${source}" alt="${t('before')}">` : `<p>${t('choosePhoto')}</p>`}${result ? `<img src="${result}" alt="${t('after')}">` : ''}</div>
      <footer><div class="status"><span id="status-text"></span><progress id="progress" max="100" value="0" hidden></progress></div>
      <button id="run" ${!source || busy ? 'disabled' : ''}>${t('restore')}</button>${busy ? `<button id="cancel">${t('cancel')}</button>` : ''}
      ${result ? `<button id="new-doc">${t('newDocument')}</button><button id="current-doc">${t('currentDocument')}</button><button id="save">${t('download')}</button>` : ''}</footer></div>`;
    app.querySelector('#close').onclick = () => { stop = true; onClose?.(); };
    app.querySelector('#advanced').onclick = () => { advanced = !advanced; render(); };
    app.querySelector('#file-button').onclick = () => app.querySelector('#file').click();
    app.querySelector('#file-name').textContent = source ? fileName : t('noFile');
    app.querySelectorAll('[data-setting]').forEach(select => { select.onchange = () => { settings[select.dataset.setting] = select.value; }; });
    app.querySelector('#file').onchange = e => { const f = e.target.files?.[0]; if (f) setSource(f, f.name); };
    app.querySelector('#run').onclick = run;
    app.querySelector('#cancel')?.addEventListener('click', () => { stop = true; updateStatus(t('stopping')); });
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
        if (!originalBlob) { updateStatus(t('originalFailed')); return; }
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
    status = t(manifest?.status === 'ready' ? 'modelsReady' : 'checkingModels'); render();
  }
  async function run() {
    if (!source || busy) return;
    if (manifest?.status !== 'ready') { updateStatus(t('modelsUnavailable')); return; }
    busy = true; stop = false; updateStatus(t('preparing'), 0); render();
    try {
      const image = new Image(); image.src = source; await image.decode();
      const { canvas, scaled } = toWorkCanvas(image, 3000);
      if (scaled) updateStatus(t('largePhoto'));
      const hooks = {
        onStage: stage => updateStatus(`${t('processing')}: ${stageLabel(t, stage)}`, 0),
        onProgress: fraction => updateStatus(`${t('processing')}: ${Math.round(fraction * 100)}%`, fraction * 100),
        onDownload: (got, total) => updateStatus(total ? `${t('downloadingModel')}: ${Math.min(100, Math.round(got / total * 100))}%` : t('downloadingModel'), total ? got / total * 100 : 0),
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
      if (!blob) throw new Error(t('pngFailed'));
      if (result) URL.revokeObjectURL(result);
      result = URL.createObjectURL(blob); busy = false; status = t('ready'); progress = 100; render();
    } catch (error) {
      busy = false; status = stop ? t('cancelled') : `${t('error')}: ${error.message}`; progress = 0; render();
    }
  }
  if (bytes) setSource(new Blob([bytes], { type: 'image/png' }), name); else render();
  loadVetorManifest().then(value => {
    manifest = value;
    if (!busy) updateStatus(t(value.status === 'ready' ? 'modelsReady' : 'modelsUnavailable'));
  });
  hasWebGpu().then(gpu => { if (!gpu && !busy) updateStatus(t('cpuSlow')); });
  return () => { stop = true; if (source) URL.revokeObjectURL(source); if (result) URL.revokeObjectURL(result); releaseAll(); };
}
