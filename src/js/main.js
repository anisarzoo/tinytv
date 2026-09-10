import { initApp } from './app.js';

document.addEventListener('DOMContentLoaded', initApp);

// Service Worker
if ('serviceWorker' in navigator) {
    let refreshing = false;
    navigator.serviceWorker.addEventListener('controllerchange', () => {
        if (!refreshing) {
            refreshing = true;
            window.location.reload();
        }
    });

    window.addEventListener('load', () => {
        navigator.serviceWorker.register('./service-worker.js')
            .then(reg => {
                console.log('Service Worker registered');
                reg.update();
            })
            .catch(err => console.log('Service Worker registration failed:', err));
    });
}
