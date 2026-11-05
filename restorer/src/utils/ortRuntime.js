// onnxruntime-web for the workers: the runtime (one copy per worker) and model downloads kept in the browser cache.
// Shared by ortWorker.js (restoration, depth, upscale) and stemsWorker.js (stem separation).

import ortWasmUrl from 'onnxruntime-web/ort-wasm-simd-threaded.jsep.wasm?url';

const CACHE = 'vetor-restore-models-v3';
let ortPromise = null;

export function getOrt() {
  if (!ortPromise) {
    ortPromise = import('onnxruntime-web').then((ort) => {
      ort.env.wasm.wasmPaths = { wasm: ortWasmUrl };
      ort.env.wasm.numThreads = (typeof crossOriginIsolated !== 'undefined' && crossOriginIsolated) ? Math.min(4, navigator.hardwareConcurrency || 2) : 1;
      return ort;
    });
  }
  return ortPromise;
}

// Кэш браузера хранит модель кусками по 32 МБ: одна запись в сотни мегабайт во многих браузерах падает с «internal error».
const CHUNK = 32 * 1024 * 1024;
// фрагмент после # Cache API отбрасывает — различаем записи параметром запроса
const meta = (url) => `${url}${url.includes('?') ? '&' : '?'}rr=meta`;
const part = (url, i) => `${url}${url.includes('?') ? '&' : '?'}rr=${i}`;

async function readCached(cache, url) {
  const m = await cache.match(meta(url));
  if (!m) return null;
  const { total, n } = await m.json();
  const out = new Uint8Array(total); let at = 0;
  for (let i = 0; i < n; i += 1) {
    // eslint-disable-next-line no-await-in-loop
    const r = await cache.match(part(url, i));
    if (!r) return null;
    // eslint-disable-next-line no-await-in-loop
    const b = new Uint8Array(await r.arrayBuffer());
    if (at + b.length > total) return null;
    out.set(b, at); at += b.length;
  }
  return at === total ? out : null;
}

async function writeCached(cache, url, bytes) {
  const n = Math.ceil(bytes.length / CHUNK);
  for (let i = 0; i < n; i += 1) {
    // eslint-disable-next-line no-await-in-loop
    await cache.put(part(url, i), new Response(bytes.slice(i * CHUNK, (i + 1) * CHUNK), { headers: { 'content-type': 'application/octet-stream' } }));
  }
  await cache.put(meta(url), new Response(JSON.stringify({ total: bytes.length, n })));
}

// Скачивание с прогрессом и кэшем браузера: большие модели грузятся один раз.
async function fetchBytes(url, onProgress) {
  let cache = null;
  try { if (typeof caches !== 'undefined') cache = await caches.open(CACHE); } catch { cache = null; }
  if (cache) {
    try {
      const hit = await readCached(cache, url);
      if (hit) { onProgress(hit.length, hit.length); return hit; }
    } catch { /* битый кэш — качаем заново */ }
  }
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${res.status} ${url}`);
  const total = Number(res.headers.get('content-length')) || 0;
  let bytes;
  if (res.body && total) {
    const reader = res.body.getReader();
    bytes = new Uint8Array(total);
    let got = 0;
    for (;;) {
      // eslint-disable-next-line no-await-in-loop
      const { done, value } = await reader.read();
      if (done) break;
      if (got + value.length > bytes.length) { const grown = new Uint8Array(got + value.length); grown.set(bytes.subarray(0, got)); bytes = grown; }
      bytes.set(value, got); got += value.length;
      onProgress(got, total);
    }
    bytes = bytes.subarray(0, got);
  } else {
    bytes = new Uint8Array(await res.arrayBuffer());
    onProgress(bytes.length, bytes.length);
  }
  if (cache) { try { await writeCached(cache, url, bytes); } catch { /* кэш переполнен — не страшно */ } }
  return bytes;
}

// url — строка или массив частей одного файла (модель >100 МБ режется на куски для GitHub): части качаются по очереди и склеиваются.
export async function fetchModel(url, onProgress) {
  if (!Array.isArray(url)) return fetchBytes(url, onProgress);
  const sizes = url.map(() => 0); const got = url.map(() => 0);
  const report = () => onProgress(got.reduce((a, b) => a + b, 0), Math.max(sizes.reduce((a, b) => a + b, 0), 1));
  const parts = [];
  for (let i = 0; i < url.length; i += 1) {
    // eslint-disable-next-line no-await-in-loop
    parts.push(await fetchBytes(url[i], (g, t) => { got[i] = g; sizes[i] = t; report(); }));
  }
  const out = new Uint8Array(parts.reduce((a, p) => a + p.length, 0)); let at = 0;
  parts.forEach((p) => { out.set(p, at); at += p.length; });
  return out;
}
