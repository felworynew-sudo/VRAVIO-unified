import { translator } from './i18n.js';
import { SOURCES, SAMPLE_RATE } from './utils/stems.js';
import './cutout.css';
import './stems.css';

// The audio editor sends the selected clip ({ name, sampleRate, left, right }); the stems go back as
// 32-bit float WAV files at the clip's rate, each becoming a new track at the clip's position.
const app = document.querySelector('#stems-app');
const ORDER = ['vocals', 'drums', 'bass', 'other'];
const MAX_SECONDS = 600;
let t = translator(new URLSearchParams(location.search).get('lang') || navigator.language);
let clip = null, stems = null, urls = {}, busy = false, applied = false, closeArmed = false;
let chosen = new Set(ORDER), status = '', warn = false, progress = 0, worker = null;
let eta = null, tick = null; // when the separation should end (ms), and the timer that counts down to it

const label = name => t(`stem_${name}`);
const seconds = n => `${Math.floor(n / 60)}:${String(Math.round(n % 60)).padStart(2, '0')}`;
const guarded = () => busy || (!!stems && !applied);

function setStatus(text, value = progress, isWarning = false) {
  if (closeArmed && !isWarning) return; // the close warning stays until the next action
  status = text; progress = value; warn = isWarning;
  const s = app.querySelector('#status'), bar = app.querySelector('#progress');
  if (s) { s.textContent = status; s.classList.toggle('warn', warn); }
  if (bar) { bar.value = progress; bar.hidden = !busy; }
}

function render() {
  closeArmed = false;
  document.title = `VRAVIO · ${t('stemsTitle')}`;
  const length = clip ? clip.left.length / clip.sampleRate : 0;
  app.innerHTML = `<header><strong>${t('stemsTitle')} · AI</strong><button id="close" aria-label="${t('close')}" title="${t('close')}">×</button></header>
    <section class="controls">${clip
      ? `<span class="clip"><b></b> · ${seconds(length)} · ${clip.sampleRate} Hz</span>
         <span class="group">${ORDER.map(n => `<label><input type="checkbox" data-stem="${n}" ${chosen.has(n) ? 'checked' : ''} ${busy ? 'disabled' : ''}> ${label(n)}</label>`).join('')}</span>
         <span class="hint">${t('stemsHint')}</span>`
      : `<span class="hint">${t('stemsNoClip')}</span>`}</section>
    <div class="stems">${stems
      ? ORDER.filter(n => chosen.has(n)).map(n => `<div class="stem"><span>${label(n)}</span><audio controls preload="metadata" src="${urls[n]}"></audio><a href="${urls[n]}" download="${fileName(n)}">${t('downloadWav')}</a></div>`).join('')
      : `<p>${clip ? t('stemsReady') : ''}</p>`}</div>
    <footer><span id="status"></span><progress id="progress" max="100" value="0" hidden></progress>
      <button id="run" ${!clip || busy || !chosen.size ? 'disabled' : ''}>${t('separate')}</button>${busy ? `<button id="cancel">${t('cancel')}</button>` : ''}
      ${stems && !busy ? `<button id="apply">${t('addTracks')}</button>` : ''}</footer>`;
  if (clip) app.querySelector('.clip b').textContent = clip.name;
  app.querySelector('#close').onclick = close;
  app.querySelectorAll('[data-stem]').forEach(box => { box.onchange = () => { box.checked ? chosen.add(box.dataset.stem) : chosen.delete(box.dataset.stem); applied = false; render(); }; });
  app.querySelector('#run').onclick = run;
  app.querySelector('#cancel')?.addEventListener('click', () => { worker?.postMessage({ type: 'stop' }); setStatus(t('stopping')); });
  app.querySelector('#apply')?.addEventListener('click', apply);
  setStatus(status, progress, warn);
  parent.postMessage({ type: 'vravio-ai-state', guard: guarded() }, location.origin);
}

const fileName = n => `${label(n)} - ${(clip?.name || 'clip').replace(/[\\/:*?"<>|]/g, '_')}.wav`;

// Resample through the browser's own resampler (an OfflineAudioContext renders at the target rate).
async function resample(channels, from, to) {
  if (from === to) return channels;
  const frames = Math.max(1, Math.round(channels[0].length * to / from));
  const ctx = new OfflineAudioContext(channels.length, frames, to);
  const buffer = ctx.createBuffer(channels.length, channels[0].length, from);
  channels.forEach((c, i) => buffer.copyToChannel(c, i));
  const node = ctx.createBufferSource(); node.buffer = buffer; node.connect(ctx.destination); node.start();
  const out = await ctx.startRendering();
  return channels.map((_, i) => out.getChannelData(i).slice());
}

function wav(left, right, rate) {
  const n = left.length, view = new DataView(new ArrayBuffer(44 + n * 8));
  const text = (at, s) => { for (let i = 0; i < s.length; i++) view.setUint8(at + i, s.charCodeAt(i)); };
  text(0, 'RIFF'); view.setUint32(4, 36 + n * 8, true); text(8, 'WAVEfmt '); view.setUint32(16, 16, true);
  view.setUint16(20, 3, true); view.setUint16(22, 2, true); view.setUint32(24, rate, true); view.setUint32(28, rate * 8, true);
  view.setUint16(32, 8, true); view.setUint16(34, 32, true); text(36, 'data'); view.setUint32(40, n * 8, true);
  for (let i = 0, at = 44; i < n; i++, at += 8) { view.setFloat32(at, left[i], true); view.setFloat32(at + 4, right[i], true); }
  return view.buffer;
}

function clear() { Object.values(urls).forEach(u => URL.revokeObjectURL(u)); urls = {}; stems = null; applied = false; }

async function run() {
  if (!clip || busy) return;
  const length = clip.left.length / clip.sampleRate;
  if (length > MAX_SECONDS) { setStatus(t('stemsTooLong').replace('{n}', MAX_SECONDS / 60), 0, true); return; }
  clear(); busy = true; status = t('preparing'); progress = 0; warn = false; render();
  try {
    const [left, right] = await resample([clip.left, clip.right], clip.sampleRate, SAMPLE_RATE);
    worker = new Worker(new URL('./workers/stemsWorker.js', import.meta.url), { type: 'module' });
    let done = 0;
    const showProgress = p => { done = p; setStatus(`${t('processing')}: ${Math.round(p * 100)}%${eta ? ` · ${t('remaining')} ${seconds(Math.max(0, (eta - Date.now()) / 1000))}` : ''}`, p * 100); };
    tick = setInterval(() => { if (eta) showProgress(done); }, 1000);
    const result = await new Promise((resolve, reject) => {
      const segments = Math.ceil(left.length / Math.floor(0.75 * 343980));
      worker.onmessage = ({ data: m }) => {
        if (m.download) { const [got, total] = m.download; setStatus(total ? `${t('downloadingModel')}: ${Math.min(100, Math.round(got / total * 100))}%` : t('downloadingModel'), total ? got / total * 100 : 0); }
        else if (m.stage === 'prepare') setStatus(t('preparing'), 0);
        else if (m.stage === 'separate') setStatus(`${t('processing')}${m.device === 'wasm' ? ` · ${t('cpuSlow')}` : ''}`, 0);
        else if (m.progress !== undefined) {
          eta = m.progress < 1 ? Date.now() + (1 - m.progress) * segments * m.segmentMs : null;
          showProgress(m.progress);
        } else if (m.stems) resolve(m);
        else if (m.error) reject(new Error(m.error));
      };
      worker.onerror = e => reject(new Error(e.message || 'worker error'));
      worker.postMessage({ type: 'run', left, right }, [left.buffer, right.buffer]);
    });
    stems = {};
    for (let k = 0; k < SOURCES.length; k++) {
      const [l, r] = await resample(result.stems[k], SAMPLE_RATE, clip.sampleRate);
      const n = Math.min(l.length, clip.left.length); // the clip's exact length
      stems[SOURCES[k]] = wav(l.subarray(0, n), r.subarray(0, n), clip.sampleRate);
      urls[SOURCES[k]] = URL.createObjectURL(new Blob([stems[SOURCES[k]]], { type: 'audio/wav' }));
    }
    busy = false; status = t('ready'); progress = 100; render();
  } catch (error) {
    busy = false; clear(); status = error.message === 'stopped' ? t('cancelled') : `${t('error')}: ${error.message}`; warn = error.message !== 'stopped'; progress = 0; render();
  } finally {
    clearInterval(tick); tick = null; eta = null;
    worker?.terminate(); worker = null;
  }
}

function apply() {
  const list = ORDER.filter(n => chosen.has(n) && stems?.[n]).map(n => ({ name: fileName(n), bytes: stems[n].slice(0) }));
  if (!list.length) return;
  applied = true;
  parent.postMessage({ type: 'vravio-stems-result', stems: list }, location.origin, list.map(s => s.bytes));
}

// Closing never silently drops a minute of work or unadded stems: the first press warns.
function close() {
  if (guarded() && !closeArmed) {
    closeArmed = true;
    status = t(busy ? 'busyClose' : 'stemsUnsavedClose'); warn = true;
    const s = app.querySelector('#status'); if (s) { s.textContent = status; s.classList.add('warn'); }
    return;
  }
  worker?.postMessage({ type: 'stop' });
  parent.postMessage({ type: 'vravio-ai-close' }, location.origin);
}
document.addEventListener('keydown', e => { if (e.key === 'Escape') { e.preventDefault(); close(); } });

window.addEventListener('message', event => {
  if (event.origin !== location.origin || event.source !== parent) return;
  const m = event.data;
  if (m?.type === 'vravio-ai-close-request') { close(); return; }
  if (m?.type !== 'vravio-stems-input') return;
  t = translator(m.locale);
  document.documentElement.lang = m.locale || navigator.language;
  clear();
  const left = m.left instanceof Float32Array ? m.left : new Float32Array(m.left);
  const right = m.right instanceof Float32Array ? m.right : new Float32Array(m.right);
  clip = { name: String(m.name || 'Clip'), sampleRate: Number(m.sampleRate) || 48000, left, right };
  status = ''; render();
});
window.addEventListener('pagehide', () => { worker?.terminate(); clear(); });
render();
