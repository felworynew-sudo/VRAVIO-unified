import { guidedFilter } from './guidedFilter.js';

// The same two browser models used by Vetor Studio. Portraits use the light
// matte network; the larger general model is an explicit WebGPU quality mode.
export const CUTOUT_MODELS = {
  fast: { id: 'Xenova/modnet', input: 'input' },
  quality: { id: 'studioludens/birefnet-lite-512', input: 'input_image', output: 'logits', sigmoid: true, dtype: 'fp16' },
};

const cache = new Map();
async function load(spec, progress) {
  if (!cache.has(spec.id)) {
    cache.set(spec.id, (async () => {
      const lib = await import('@huggingface/transformers');
      const { AutoModel, AutoProcessor, env } = lib;
      env.allowLocalModels = false;
      const gpu = !!navigator.gpu && !!(await navigator.gpu.requestAdapter().catch(() => null));
      const options = { device: gpu ? 'webgpu' : 'wasm', progress_callback: progress };
      if (spec.dtype) options.dtype = spec.dtype;
      return { model: await AutoModel.from_pretrained(spec.id, options), processor: await AutoProcessor.from_pretrained(spec.id), RawImage: lib.RawImage };
    })().catch(error => { cache.delete(spec.id); throw error; }));
  }
  return cache.get(spec.id);
}

export async function cutOut(imageUrl, quality, progress = () => {}) {
  const spec = CUTOUT_MODELS[quality] || CUTOUT_MODELS.fast;
  progress('Загрузка модели…');
  const { model, processor, RawImage } = await load(spec, info => {
    if (info?.status === 'progress' && info.total) progress(`Загрузка модели: ${Math.round(info.loaded / info.total * 100)}%`);
  });
  progress('Построение маски…');
  const image = await RawImage.fromURL(imageUrl);
  const { pixel_values } = await processor(image);
  const output = await model({ [spec.input]: pixel_values });
  let tensor = (spec.output && output[spec.output]) || output.output || output.last_hidden_state || Object.values(output)[0];
  tensor = tensor[0];
  if (spec.sigmoid) tensor = tensor.sigmoid();
  const matte = await RawImage.fromTensor(tensor.mul(255).to('uint8')).resize(image.width, image.height);
  const w = image.width, h = image.height;
  const raw = new Uint8ClampedArray(w * h);
  const channels = matte.channels || 1;
  for (let i = 0; i < raw.length; i++) raw[i] = matte.data[i * channels];

  // Edge-aware refinement follows the source luminance, retaining semi-transparent
  // strands instead of thresholding them into a hard silhouette.
  progress('Уточнение волос и краёв…');
  const bitmap = await createImageBitmap(await (await fetch(imageUrl)).blob());
  const source = document.createElement('canvas'); source.width = w; source.height = h;
  source.getContext('2d').drawImage(bitmap, 0, 0); bitmap.close();
  const scale = Math.min(1, 2048 / Math.max(w, h));
  const ww = Math.max(1, Math.round(w * scale)), hh = Math.max(1, Math.round(h * scale));
  const small = document.createElement('canvas'); small.width = ww; small.height = hh;
  const sc = small.getContext('2d', { willReadFrequently: true });
  sc.drawImage(source, 0, 0, ww, hh);
  const rgb = sc.getImageData(0, 0, ww, hh).data;
  const guide = new Float32Array(ww * hh);
  for (let i = 0; i < guide.length; i++) guide[i] = (0.299 * rgb[i * 4] + 0.587 * rgb[i * 4 + 1] + 0.114 * rgb[i * 4 + 2]) / 255;
  const maskCanvas = document.createElement('canvas'); maskCanvas.width = w; maskCanvas.height = h;
  const mc = maskCanvas.getContext('2d', { willReadFrequently: true });
  const maskPixels = mc.createImageData(w, h);
  for (let i = 0; i < raw.length; i++) maskPixels.data[i * 4 + 3] = raw[i];
  mc.putImageData(maskPixels, 0, 0);
  sc.clearRect(0, 0, ww, hh); sc.drawImage(maskCanvas, 0, 0, ww, hh);
  const smallMask = sc.getImageData(0, 0, ww, hh).data;
  const p = new Float32Array(ww * hh);
  for (let i = 0; i < p.length; i++) p[i] = smallMask[i * 4 + 3] / 255;
  const refined = guidedFilter(guide, p, ww, hh, Math.max(3, Math.round(Math.max(ww, hh) / 320)), 2e-3);
  const refinedPixels = sc.createImageData(ww, hh);
  for (let i = 0; i < refined.length; i++) refinedPixels.data[i * 4 + 3] = Math.round(refined[i] * 255);
  sc.putImageData(refinedPixels, 0, 0);
  mc.clearRect(0, 0, w, h); mc.imageSmoothingQuality = 'high'; mc.drawImage(small, 0, 0, w, h);
  const up = mc.getImageData(0, 0, w, h).data;
  const imagePixels = source.getContext('2d', { willReadFrequently: true }).getImageData(0, 0, w, h);
  for (let i = 0; i < raw.length; i++) {
    const q = up[i * 4 + 3], m = raw[i];
    const alpha = m < 8 && q < 40 ? 0 : m > 247 && q > 215 ? 255 : q < 10 ? 0 : q > 245 ? 255 : q;
    imagePixels.data[i * 4 + 3] = Math.round(imagePixels.data[i * 4 + 3] * alpha / 255);
  }
  source.getContext('2d').putImageData(imagePixels, 0, 0);
  return source;
}
