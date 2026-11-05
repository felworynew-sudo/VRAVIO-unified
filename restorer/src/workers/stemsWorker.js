// Stem separation (HTDemucs) off the page's thread, so the dialog's progress and Cancel stay live.
// Protocol: { type: 'run', left, right } (44.1 kHz) → { download: [got, total] } | { stage } | { progress, segmentMs }
//           → { stems: [[left, right] × 4 in SOURCES order], device } or { error }; { type: 'stop' } ends a run.

import { getOrt, fetchModel } from '../utils/ortRuntime.js';
import { separate } from '../utils/stems.js';

// MIT: github.com/facebookresearch/demucs (HTDemucs); ONNX export with the weights embedded, fp16.
const MODEL = 'https://huggingface.co/FeatherLoom/htdemucs-web/resolve/main/htdemucs_embedded_fp16.onnx';
let session = null;
let stop = false;

async function open() {
  if (session) return session;
  const ort = await getOrt();
  const bytes = await fetchModel(MODEL, (got, total) => self.postMessage({ download: [got, total] }));
  self.postMessage({ stage: 'prepare' });
  for (const device of ['webgpu', 'wasm']) {
    if (device === 'webgpu' && !(self.navigator?.gpu && await self.navigator.gpu.requestAdapter().catch(() => null))) continue;
    try {
      const s = await ort.InferenceSession.create(bytes, { executionProviders: [device], graphOptimizationLevel: 'all' });
      session = { ort, s, device };
      return session;
    } catch (error) {
      if (device === 'wasm') throw error;
    }
  }
  throw new Error('no backend');
}

async function run(left, right) {
  stop = false;
  let { ort, s, device } = await open();
  self.postMessage({ stage: 'separate', device });
  let started = performance.now();
  const call = async (input, x) => {
    const r = await s.run({ input: new ort.Tensor('float32', input, [1, 2, input.length / 2]), x: new ort.Tensor('float32', x, [1, 4, 2048, 336]) });
    return { spectral: r.output.data, time: r.add_67.data };
  };
  const hooks = {
    shouldStop: () => stop,
    onProgress: p => { self.postMessage({ progress: p, segmentMs: performance.now() - started }); started = performance.now(); },
  };
  let stems;
  try {
    stems = await separate(left, right, call, hooks);
  } catch (error) {
    // WebGPU may load the graph and still fail on a kernel: run it again on the CPU.
    if (device !== 'webgpu' || error.message === 'stopped') throw error;
    session = { ort, s: await ort.InferenceSession.create(await fetchModel(MODEL, () => {}), { executionProviders: ['wasm'], graphOptimizationLevel: 'all' }), device: 'wasm' };
    ({ s, device } = session);
    self.postMessage({ stage: 'separate', device });
    started = performance.now();
    stems = await separate(left, right, call, hooks);
  }
  return { stems, device };
}

self.onmessage = async e => {
  const m = e.data;
  if (m.type === 'stop') { stop = true; return; }
  if (m.type !== 'run') return;
  try {
    const { stems, device } = await run(m.left, m.right);
    self.postMessage({ stems, device }, stems.flat().map(a => a.buffer));
  } catch (error) {
    self.postMessage({ error: String(error?.message || error) });
  }
};
