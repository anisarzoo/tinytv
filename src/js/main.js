import { initApp } from './app.js';

document.addEventListener('DOMContentLoaded', initApp);

// Service Worker
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/service-worker.js');
    });
}
