import { defineConfig } from 'vite';
import { fileURLToPath } from 'node:url';
export default defineConfig({ root: fileURLToPath(new URL('.', import.meta.url)), base: './', worker: { format: 'es' }, build: { outDir: '../dist/restorer', emptyOutDir: true, rollupOptions: { input: { restore: fileURLToPath(new URL('./index.html', import.meta.url)), cutout: fileURLToPath(new URL('./cutout/index.html', import.meta.url)) } } } });
