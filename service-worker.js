const CACHE_NAME = 'tivy-v1';
const urlsToCache = [
  '/',
  '/manifest.json',
  '/favicon.png',
  '/index.html'
  // Only cache files we KNOW exist - no CSS/JS (they load dynamically)
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('Caching essential files');
        return cache.addAll(urlsToCache);
      })
      .catch(err => {
        console.log('Cache addAll failed (normal if files missing):', err);
      })
  );
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        // Return cached version or fetch from network
        return response || fetch(event.request).catch(() => {
          // Offline fallback
          return caches.match('/');
        });
      })
  );
});
