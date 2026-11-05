// Нейросети для растра: карта глубины (Depth Anything V2 Small), увеличение ×4 (Real-ESRGAN general-x4v3)
// и шумоподавление (SCUNet, слепое к виду шума: сенсор RAW, высокий ISO, JPEG).
// Обе считаются в воркере onnxruntime-web (ortClient): WebGPU, если есть, иначе процессор.

import { loadSession } from './ortClient';

const BASE = new URL('../models/restore/', document.baseURI).href;
const HF_SCUNET = 'https://huggingface.co/Heliosoph/scunet-onnx/resolve/main/scunet_color_real_psnr';

export const AI_MODELS = {
  // Apache-2.0. Веса q4f16 (18 МБ) скачиваются при первом запуске и остаются в кэше браузера.
  depth: { url: 'https://huggingface.co/onnx-community/depth-anything-v2-small/resolve/main/onnx/model_q4f16.onnx', mb: 18, opt: 'basic' },
  // BSD-3-Clause. Вход только 128×128, поэтому кадр режется на плитки ровно этого размера.
  upscale: { url: `${BASE}realesr-general-x4v3.onnx`, mb: 4.7 },
  // Apache-2.0 (cszn/SCUNet, real-PSNR), 73 МБ: граф и веса — два файла. Только fp32: fp16 на WebGPU (JSEP) даёт мусор.
  denoise: { url: `${HF_SCUNET}.onnx`, external: { path: 'scunet_color_real_psnr.onnx.data', url: `${HF_SCUNET}.onnx.data` }, mb: 73 },
};

const DEPTH_SIDE = 518; // родное разрешение Depth Anything; стороны кратны 14
const TILE = 128, PAD = 8, STEP = TILE - 2 * PAD, SCALE = 4;
export const MAX_UPSCALE_IN = { webgpu: 1024, wasm: 640 };
// SCUNet: окна Swin 8×8 после трёх уменьшений — стороны плитки кратны 64. Плитка одна и та же — WebGPU не пересобирает граф.
// Перекрытие 16: в лаборатории качество то же, что при 32, а плиток почти вдвое меньше. Плитка 512 на WebGPU медленнее четырёх по 256.
const D_TILE = 256, D_PAD = 16, D_STEP = D_TILE - 2 * D_PAD;

const makeCanvas = (w, h) => { const c = document.createElement('canvas'); c.width = w; c.height = h; return c; };
const nextFrame = () => new Promise(resolve => setTimeout(resolve, 0));

export async function hasWebGpu() {
  try { return !!navigator.gpu && !!(await navigator.gpu.requestAdapter()); } catch { return false; }
}

// WebGPU может не потянуть модель уже на запуске (нет shader-f16 и т. п.) — тогда тот же расчёт повторяется на процессоре.
async function withSession(name, hooks, work) {
  const spec = AI_MODELS[name];
  const gpu = await hasWebGpu();
  const open = device => loadSession(`ai-${name}`, spec.url, device, hooks.onDownload, { opt: spec.opt, external: spec.external });
  let session = await open(gpu ? 'webgpu' : 'wasm');
  try {
    return await work(session);
  } catch (error) {
    if (session.device !== 'webgpu' || error.message === 'stopped') throw error;
    session = await open('wasm');
    return work(session);
  }
}

export async function depthMap(source, hooks = {}) {
  const w = source.width, h = source.height;
  const k = DEPTH_SIDE / Math.max(w, h);
  const dw = Math.max(14, Math.round(w * k / 14) * 14), dh = Math.max(14, Math.round(h * k / 14) * 14);
  hooks.onStage?.('depth-load');
  return withSession('depth', hooks, async session => {
    hooks.onStage?.('depth');
    const small = makeCanvas(dw, dh), sctx = small.getContext('2d', { willReadFrequently: true });
    sctx.imageSmoothingQuality = 'high'; sctx.drawImage(source, 0, 0, dw, dh);
    const px = sctx.getImageData(0, 0, dw, dh).data, plane = dw * dh, x = new Float32Array(3 * plane);
    const mean = [0.485, 0.456, 0.406], std = [0.229, 0.224, 0.225];
    for (let i = 0; i < plane; i++) for (let c = 0; c < 3; c++) x[c * plane + i] = (px[i * 4 + c] / 255 - mean[c]) / std[c];
    const out = await session.run(x, [1, 3, dh, dw]);
    const { data, dims } = out[session.outputNames[0]];
    const ow = dims[dims.length - 1], oh = dims[dims.length - 2];
    let lo = Infinity, hi = -Infinity;
    for (const v of data) { if (v < lo) lo = v; if (v > hi) hi = v; }
    // Depth Anything выдаёт относительную обратную глубину: больше — ближе, поэтому близкое светлое.
    const map = makeCanvas(ow, oh), mctx = map.getContext('2d'), img = mctx.createImageData(ow, oh);
    for (let i = 0; i < ow * oh; i++) {
      const v = Math.round((data[i] - lo) / (hi - lo || 1) * 255);
      img.data[i * 4] = img.data[i * 4 + 1] = img.data[i * 4 + 2] = v; img.data[i * 4 + 3] = 255;
    }
    mctx.putImageData(img, 0, 0);
    const result = makeCanvas(w, h), rctx = result.getContext('2d');
    rctx.imageSmoothingQuality = 'high'; rctx.drawImage(map, 0, 0, w, h);
    hooks.onProgress?.(1);
    return { canvas: result, device: session.device };
  });
}

export async function upscaleX4(source, hooks = {}) {
  hooks.onStage?.('upscale-load');
  return withSession('upscale', hooks, async session => {
    let input = source;
    const limit = MAX_UPSCALE_IN[session.device] || MAX_UPSCALE_IN.wasm;
    const k = Math.min(1, limit / Math.max(source.width, source.height));
    if (k < 1) {
      input = makeCanvas(Math.round(source.width * k), Math.round(source.height * k));
      const ictx = input.getContext('2d'); ictx.imageSmoothingQuality = 'high'; ictx.drawImage(source, 0, 0, input.width, input.height);
    }
    hooks.onStage?.('upscale');
    const w = input.width, h = input.height, src = input.getContext('2d', { willReadFrequently: true }).getImageData(0, 0, w, h).data;
    const out = makeCanvas(w * SCALE, h * SCALE), octx = out.getContext('2d');
    const total = Math.ceil(w / STEP) * Math.ceil(h / STEP);
    let done = 0;
    const plane = TILE * TILE, oTile = TILE * SCALE, oPlane = oTile * oTile;
    for (let y0 = 0; y0 < h; y0 += STEP) {
      for (let x0 = 0; x0 < w; x0 += STEP) {
        if (hooks.shouldStop?.()) throw new Error('stopped');
        // Плитка всегда 128×128: края кадра дополняются повтором крайних пикселей.
        const x = new Float32Array(3 * plane);
        for (let j = 0; j < TILE; j++) {
          const sy = Math.min(h - 1, Math.max(0, y0 - PAD + j));
          for (let i = 0; i < TILE; i++) {
            const p = (sy * w + Math.min(w - 1, Math.max(0, x0 - PAD + i))) * 4, t = j * TILE + i;
            x[t] = src[p] / 255; x[plane + t] = src[p + 1] / 255; x[2 * plane + t] = src[p + 2] / 255;
          }
        }
        const y = (await session.run(x, [1, 3, TILE, TILE]))[session.outputNames[0]].data;
        const cw = Math.min(STEP, w - x0) * SCALE, ch = Math.min(STEP, h - y0) * SCALE, img = octx.createImageData(cw, ch);
        for (let j = 0; j < ch; j++) {
          for (let i = 0; i < cw; i++) {
            const si = (PAD * SCALE + j) * oTile + PAD * SCALE + i, di = (j * cw + i) * 4;
            for (let c = 0; c < 3; c++) img.data[di + c] = Math.round(Math.min(1, Math.max(0, y[c * oPlane + si])) * 255);
            img.data[di + 3] = 255;
          }
        }
        octx.putImageData(img, x0 * SCALE, y0 * SCALE);
        done += 1; hooks.onProgress?.(done / total);
        await nextFrame();
      }
    }
    // «До» для сравнения: исходник, растянутый до того же размера обычной интерполяцией.
    const before = makeCanvas(out.width, out.height), bctx = before.getContext('2d');
    bctx.imageSmoothingQuality = 'high'; bctx.drawImage(input, 0, 0, out.width, out.height);
    return { canvas: out, before, reduced: k < 1, device: session.device };
  });
}

// Шумоподавление в полном разрешении: плитки 256×256 с перекрытием 32 пикселя по краям (швы не видны),
// края кадра дополняются повтором крайних пикселей. Прозрачность исходника сохраняется.
export async function denoise(source, hooks = {}) {
  hooks.onStage?.('denoise-load');
  return withSession('denoise', hooks, async session => {
    hooks.onStage?.('denoise');
    const w = source.width, h = source.height, src = source.getContext('2d', { willReadFrequently: true }).getImageData(0, 0, w, h).data;
    const out = makeCanvas(w, h), octx = out.getContext('2d');
    const total = Math.ceil(w / D_STEP) * Math.ceil(h / D_STEP), plane = D_TILE * D_TILE;
    let done = 0;
    for (let y0 = 0; y0 < h; y0 += D_STEP) {
      for (let x0 = 0; x0 < w; x0 += D_STEP) {
        if (hooks.shouldStop?.()) throw new Error('stopped');
        const x = new Float32Array(3 * plane);
        for (let j = 0; j < D_TILE; j++) {
          const sy = Math.min(h - 1, Math.max(0, y0 - D_PAD + j));
          for (let i = 0; i < D_TILE; i++) {
            const p = (sy * w + Math.min(w - 1, Math.max(0, x0 - D_PAD + i))) * 4, t = j * D_TILE + i;
            x[t] = src[p] / 255; x[plane + t] = src[p + 1] / 255; x[2 * plane + t] = src[p + 2] / 255;
          }
        }
        const y = (await session.run(x, [1, 3, D_TILE, D_TILE]))[session.outputNames[0]].data;
        const cw = Math.min(D_STEP, w - x0), ch = Math.min(D_STEP, h - y0), img = octx.createImageData(cw, ch);
        for (let j = 0; j < ch; j++) {
          for (let i = 0; i < cw; i++) {
            const si = (D_PAD + j) * D_TILE + D_PAD + i, di = (j * cw + i) * 4;
            for (let c = 0; c < 3; c++) img.data[di + c] = Math.round(Math.min(1, Math.max(0, y[c * plane + si])) * 255);
            img.data[di + 3] = src[((y0 + j) * w + x0 + i) * 4 + 3];
          }
        }
        octx.putImageData(img, x0, y0);
        done += 1; hooks.onProgress?.(done / total);
        await nextFrame();
      }
    }
    return { canvas: out, device: session.device };
  });
}
