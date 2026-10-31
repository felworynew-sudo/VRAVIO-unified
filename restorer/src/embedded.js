import css from './style.css?inline';
import { mountRestorer } from './main.js';
window.__vravioMountRestorer = mountRestorer;
const style = document.createElement('style');
style.textContent = css;
document.head.append(style);
