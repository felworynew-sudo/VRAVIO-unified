import './style.css';
import { mountRestorer } from './main.js';
import { translator } from './i18n.js';

const app = document.querySelector('#restore-app');
const locale = new URLSearchParams(location.search).get('lang') || navigator.language;
document.documentElement.lang = locale;
document.title = `VRAVIO · ${translator(locale)('title')}`;
let cleanup = null;
function close() { cleanup?.(); cleanup = null; parent.postMessage({ type: 'vravio-restorer-close' }, location.origin); }
function show(bytes, name) {
  cleanup?.();
  cleanup = mountRestorer(app, { bytes, name, locale, onClose: close,
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
