// Copied from the VRAVIO AI lab bench (node/stems-core.mjs), where its output was checked.
// HTDemucs (htdemucs_embedded_fp16.onnx) around the ONNX graph: the STFT in, the inverse STFT out, and the
// overlapping 7.8 s segments of demucs.apply_model. The graph takes the padded waveform segment and its
// complex-as-channels spectrogram; it returns the spectral branch (masked spectrogram per source) and the
// time branch (waveform per source). A source is istft(spectral) + time.
// Mirrors demucs/htdemucs.py (_spec, _ispec, _magnitude, _mask) and demucs/apply.py (split, overlap 0.25).

export const SOURCES = ['drums', 'bass', 'other', 'vocals'];
export const SAMPLE_RATE = 44100;
export const SEGMENT = 343980; // 7.8 s, the model's fixed input length
const NFFT = 4096, HOP = 1024, BINS = NFFT / 2, FRAMES = Math.ceil(SEGMENT / HOP); // 2048 bins, 336 frames
const PAD = (HOP / 2) * 3; // 1536

// ---------- FFT (radix 2, in place, complex) ----------
const fftTables = new Map();
function tables(n) {
  if (fftTables.has(n)) return fftTables.get(n);
  const bits = Math.log2(n), rev = new Uint32Array(n), cos = new Float64Array(n / 2), sin = new Float64Array(n / 2);
  for (let i = 0; i < n; i++) { let r = 0; for (let b = 0; b < bits; b++) r |= ((i >> b) & 1) << (bits - 1 - b); rev[i] = r; }
  for (let i = 0; i < n / 2; i++) { cos[i] = Math.cos(2 * Math.PI * i / n); sin[i] = Math.sin(2 * Math.PI * i / n); }
  const t = { rev, cos, sin }; fftTables.set(n, t); return t;
}
// Forward when sign = -1 (e^{-i}), inverse (unscaled) when sign = +1.
function fft(re, im, sign) {
  const n = re.length, { rev, cos, sin } = tables(n);
  for (let i = 0; i < n; i++) { const j = rev[i]; if (j > i) { let t = re[i]; re[i] = re[j]; re[j] = t; t = im[i]; im[i] = im[j]; im[j] = t; } }
  for (let size = 2; size <= n; size <<= 1) {
    const half = size >> 1, step = n / size;
    for (let start = 0; start < n; start += size) {
      for (let k = 0; k < half; k++) {
        const wr = cos[k * step], wi = sign * sin[k * step], a = start + k, b = a + half;
        const tr = re[b] * wr - im[b] * wi, ti = re[b] * wi + im[b] * wr;
        re[b] = re[a] - tr; im[b] = im[a] - ti; re[a] += tr; im[a] += ti;
      }
    }
  }
}

const WINDOW = (() => { const w = new Float64Array(NFFT); for (let i = 0; i < NFFT; i++) w[i] = 0.5 - 0.5 * Math.cos(2 * Math.PI * i / NFFT); return w; })(); // torch.hann_window (periodic)

// torch reflect padding (the edge sample is not repeated).
function reflectPad(x, left, right) {
  const n = x.length, out = new Float32Array(n + left + right);
  for (let i = 0; i < out.length; i++) {
    let j = i - left;
    while (j < 0 || j >= n) j = j < 0 ? -j : 2 * (n - 1) - j;
    out[i] = x[j];
  }
  return out;
}

// HTDemucs._spec for one channel: [re, im] each BINS × FRAMES (bin-major), normalized STFT.
function spec(channel) {
  const padded = reflectPad(channel, PAD, PAD + FRAMES * HOP - channel.length); // pad1d reflect
  const centered = reflectPad(padded, NFFT / 2, NFFT / 2); // stft center=True
  const re = new Float32Array(BINS * FRAMES), im = new Float32Array(BINS * FRAMES);
  const fr = new Float64Array(NFFT), fi = new Float64Array(NFFT), scale = 1 / Math.sqrt(NFFT);
  for (let t = 0; t < FRAMES; t++) {
    const start = (t + 2) * HOP; // z[..., 2:2+le]
    for (let i = 0; i < NFFT; i++) { fr[i] = centered[start + i] * WINDOW[i]; fi[i] = 0; }
    fft(fr, fi, -1);
    for (let f = 0; f < BINS; f++) { re[f * FRAMES + t] = fr[f] * scale; im[f * FRAMES + t] = fi[f] * scale; } // drops the Nyquist bin
  }
  return [re, im];
}

// HTDemucs._ispec for one channel of one source: re/im BINS × FRAMES → SEGMENT samples.
function ispec(re, im) {
  const frames = FRAMES + 4; // F.pad(z, (2, 2)) along time; the Nyquist bin is padded back as zero
  const total = NFFT + HOP * (frames - 1);
  const out = new Float64Array(total), env = new Float64Array(total);
  const fr = new Float64Array(NFFT), fi = new Float64Array(NFFT), scale = Math.sqrt(NFFT) / NFFT; // normalized istft, irfft's 1/N
  for (let t = 0; t < frames; t++) {
    const src = t - 2;
    fr.fill(0); fi.fill(0);
    if (src >= 0 && src < FRAMES) {
      for (let f = 0; f < BINS; f++) { fr[f] = re[f * FRAMES + src]; fi[f] = im[f * FRAMES + src]; }
      for (let f = 1; f < BINS; f++) { fr[NFFT - f] = fr[f]; fi[NFFT - f] = -fi[f]; } // Hermitian (irfft)
      fi[0] = 0;
    }
    fft(fr, fi, +1);
    const start = t * HOP;
    for (let i = 0; i < NFFT; i++) { out[start + i] += fr[i] * scale * WINDOW[i]; env[start + i] += WINDOW[i] * WINDOW[i]; }
  }
  // center=True drops NFFT/2 at the start; then x[..., pad: pad + length]
  const res = new Float32Array(SEGMENT);
  for (let i = 0; i < SEGMENT; i++) { const k = NFFT / 2 + PAD + i; res[i] = env[k] > 1e-11 ? out[k] / env[k] : 0; }
  return res;
}

// One model call on exactly SEGMENT samples per channel. `run(inputs)` returns { output, add_67 } data arrays.
export async function separateSegment(left, right, run) {
  const input = new Float32Array(2 * SEGMENT); input.set(left, 0); input.set(right, SEGMENT);
  const [lr, li] = spec(left), [rr, ri] = spec(right);
  const plane = BINS * FRAMES, x = new Float32Array(4 * plane);
  x.set(lr, 0); x.set(li, plane); x.set(rr, 2 * plane); x.set(ri, 3 * plane); // [ch0 re, ch0 im, ch1 re, ch1 im]
  const { spectral, time } = await run(input, x);
  const stems = [];
  for (let s = 0; s < 4; s++) {
    const channels = [];
    for (let c = 0; c < 2; c++) {
      const base = (s * 4 + c * 2) * plane;
      const wave = ispec(spectral.subarray(base, base + plane), spectral.subarray(base + plane, base + 2 * plane));
      const t = time.subarray((s * 2 + c) * SEGMENT, (s * 2 + c + 1) * SEGMENT);
      for (let i = 0; i < SEGMENT; i++) wave[i] += t[i];
      channels.push(wave);
    }
    stems.push(channels);
  }
  return stems;
}

// demucs.apply_model(split=True, overlap=0.25, shifts=0) over a whole stereo track at 44.1 kHz.
export async function separate(left, right, run, { onProgress, shouldStop } = {}) {
  const length = left.length;
  // Whole-track normalization (apply.py: ref = mix.mean(0); (mix - ref.mean()) / ref.std()).
  let mean = 0; for (let i = 0; i < length; i++) mean += (left[i] + right[i]) / 2; mean /= length;
  let variance = 0; for (let i = 0; i < length; i++) { const d = (left[i] + right[i]) / 2 - mean; variance += d * d; }
  const std = Math.sqrt(variance / Math.max(1, length - 1)) || 1;
  const norm = ch => { const o = new Float32Array(length); for (let i = 0; i < length; i++) o[i] = (ch[i] - mean) / std; return o; };
  const L = norm(left), R = norm(right);
  const stride = Math.floor(0.75 * SEGMENT);
  const weight = new Float32Array(SEGMENT);
  const half = Math.floor(SEGMENT / 2);
  for (let i = 0; i < SEGMENT; i++) weight[i] = i < half ? i + 1 : SEGMENT - i;
  let max = 0; for (const w of weight) if (w > max) max = w;
  for (let i = 0; i < SEGMENT; i++) weight[i] /= max;
  const out = Array.from({ length: 4 }, () => [new Float32Array(length), new Float32Array(length)]);
  const sum = new Float32Array(length);
  const offsets = []; for (let o = 0; o < length; o += stride) offsets.push(o);
  for (let n = 0; n < offsets.length; n++) {
    if (shouldStop?.()) throw new Error('stopped');
    const offset = offsets[n], chunk = Math.min(SEGMENT, length - offset);
    // TensorChunk.padded: centre the chunk in SEGMENT, filling with the neighbouring audio, else zeros.
    const start = offset - Math.floor((SEGMENT - chunk) / 2);
    const segL = new Float32Array(SEGMENT), segR = new Float32Array(SEGMENT);
    for (let i = 0; i < SEGMENT; i++) { const k = start + i; if (k >= 0 && k < length) { segL[i] = L[k]; segR[i] = R[k]; } }
    const stems = await separateSegment(segL, segR, run);
    const trim = offset - start; // center_trim back to the chunk
    for (let s = 0; s < 4; s++) for (let c = 0; c < 2; c++) {
      const src = stems[s][c], dst = out[s][c];
      for (let i = 0; i < chunk; i++) dst[offset + i] += weight[i] * src[trim + i];
    }
    for (let i = 0; i < chunk; i++) sum[offset + i] += weight[i];
    onProgress?.((n + 1) / offsets.length);
  }
  for (let s = 0; s < 4; s++) for (let c = 0; c < 2; c++) { const d = out[s][c]; for (let i = 0; i < length; i++) d[i] = d[i] / sum[i] * std + mean; }
  return out; // [source][channel] Float32Array, SOURCES order
}
