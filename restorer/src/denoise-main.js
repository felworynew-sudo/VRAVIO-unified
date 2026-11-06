import { denoisePixels, hasWebGpu } from './utils/aiTools.js';
import { releaseAll } from './utils/ortClient.js';
import { translator, stageLabel } from './i18n.js';
import './denoise.css';

// The small AI Denoise window that Camera Raw's OK opens (like Camera Raw's own progress window): it
// receives the layer as 16-bit RGBA, denoises it with SCUNet, mixes the result by Amount and sends
// it back to the raster editor. The title bar drags the window; Cancel or Escape stop the run.
const app = document.querySelector('#denoise-app');
let t = translator(new URLSearchParams(location.search).get('lang') || navigator.language);
let stop = false, started = 0, running = false, answered = false;
// One answer per run: Cancel answers at once (the shell closes the window, which ends the work).
function answer(message, transfer = []) {
  if (answered) return;
  answered = true;
  parent.postMessage({ type: 'vravio-denoise-result', ...message }, location.origin, transfer);
}
const clock = n => `${Math.floor(n / 60)}:${String(Math.round(n % 60)).padStart(2, '0')}`;

function render() {
  document.title = `VRAVIO · ${t('denoiseWindow')}`;
  app.innerHTML = `<div class="bar" title="${t('dragHint')}"><strong>${t('denoiseWindow')}</strong></div>
    <div class="body"><div class="stage" id="stage">${t('preparing')}</div><progress id="progress" max="100" value="0"></progress>
    <div class="foot"><span class="time" id="time"></span><button id="cancel">${t('cancel')}</button></div></div>`;
  app.querySelector('#cancel').onclick = cancel;
  drag(app.querySelector('.bar'));
}

function set(stage, value, time = '', warn = false) {
  app.querySelector('#stage').textContent = stage;
  if (value !== null) app.querySelector('#progress').value = value;
  const el = app.querySelector('#time');
  el.textContent = time; el.classList.toggle('warn', warn);
}

// The window is an iframe in the shell: the shell moves it by the pointer's screen offset.
function drag(handle) {
  let last = null;
  handle.addEventListener('pointerdown', e => {
    if (e.button !== 0) return;
    last = [e.screenX, e.screenY];
    handle.setPointerCapture(e.pointerId);
  });
  handle.addEventListener('pointermove', e => {
    if (!last) return;
    const dx = e.screenX - last[0], dy = e.screenY - last[1];
    if (!dx && !dy) return;
    last = [e.screenX, e.screenY];
    parent.postMessage({ type: 'vravio-denoise-move', dx, dy }, location.origin);
  });
  const end = () => { last = null; };
  handle.addEventListener('pointerup', end);
  handle.addEventListener('pointercancel', end);
}

function cancel() {
  stop = true;
  answer({ cancelled: true });
}
document.addEventListener('keydown', e => { if (e.key === 'Escape') { e.preventDefault(); cancel(); } });

async function run({ width, height, data, amount }) {
  running = true;
  const gpu = await hasWebGpu();
  const src = data instanceof Uint16Array ? data : new Uint16Array(data);
  const hooks = {
    onStage: stage => {
      started = 0;
      set(stage.endsWith('-load') ? t(stage) : `${t('processing')}: ${stageLabel(t, stage)}`, 0, gpu ? (stage.endsWith('-load') ? '' : t('estimating')) : t('cpuDenoise'), !gpu);
    },
    // After the download the model still has to start (a few seconds): say so instead of a frozen 100 %.
    onDownload: (got, total) => set(total && got >= total ? t('preparing') : total ? `${t('downloadingModel')}: ${Math.min(100, Math.round(got / total * 100))}%` : t('downloadingModel'), total ? got / total * 100 : 0),
    onProgress: fraction => {
      started ||= performance.now();
      const left = fraction > 0.02 && fraction < 1 ? (performance.now() - started) / 1000 / fraction * (1 - fraction) : 0;
      set(`${t('processing')}: ${Math.round(fraction * 100)}%`, fraction * 100, fraction < 1 && left <= 0 ? t('estimating') : left > 1 ? `${t('remaining')} ${clock(left)}` : '');
    },
    shouldStop: () => stop,
  };
  try {
    const { pixels } = await denoisePixels(src, width, height, 65535, hooks);
    // Amount below 100 mixes in the original: some grain stays and fine texture does not smear.
    const k = Math.min(100, Math.max(0, Number(amount) || 0)) / 100;
    if (k < 1) for (let i = 0; i < pixels.length; i++) if ((i & 3) !== 3) pixels[i] = Math.round(src[i] + (pixels[i] - src[i]) * k);
    set(t('ready'), 100);
    answer({ data: pixels }, [pixels.buffer]);
  } catch (error) {
    answer(stop ? { cancelled: true } : { error: error.message });
  } finally {
    running = false;
  }
}

window.addEventListener('message', event => {
  if (event.origin !== location.origin || event.source !== parent) return;
  const m = event.data;
  if (m?.type === 'vravio-denoise-cancel') { cancel(); return; }
  if (m?.type !== 'vravio-denoise-input' || running) return;
  t = translator(m.locale);
  document.documentElement.lang = m.locale || navigator.language;
  render();
  void run(m);
});
window.addEventListener('pagehide', () => { stop = true; releaseAll(); });
render();
