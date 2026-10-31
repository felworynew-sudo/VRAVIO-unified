import './style.css';
import { mountRestorer } from './main.js';

const app = document.querySelector('#restore-app');
let cleanup = null;
function close() { cleanup?.(); cleanup = null; parent.postMessage({ type: 'vravio-restorer-close' }, location.origin); }
function show(bytes, name) {
  cleanup?.();
  cleanup = mountRestorer(app, { bytes, name, onClose: close,
    onResult: ({ bytes: output, original, mode, name: resultName }) =>
      parent.postMessage({ type: 'vravio-restorer-result', bytes: output, original, mode, name: resultName }, location.origin, [output, original]),
  });
}
show();
window.addEventListener('message', event => {
  if (event.origin !== location.origin || event.source !== parent || event.data?.type !== 'vravio-restorer-input') return;
  show(event.data.bytes, event.data.name);
});
window.addEventListener('pagehide', () => cleanup?.());
