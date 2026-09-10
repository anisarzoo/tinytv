const CACHE_NAME = 'tinytv-v2';
const urlsToCache = [
  './',
  'index.html',
  'manifest.json',
  'favicon.png',
  'app.jpg',
  'logo-192.png',
  'logo-512.png',
  'src/css/main.css',
  'src/css/player.css',
  'src/css/sidebar.css',
  'src/css/desktop.css',
  'src/css/mobile.css',
  'src/js/main.js',
  'src/js/app.js',
  'src/js/components/player.js',
  'src/js/components/channelgrid.js',
  'src/js/components/controls.js',
  'src/js/components/filters.js',
  'src/js/components/sidebar.js',
  'src/js/utils/channelfilter.js',
  'src/js/utils/dropdown.js',
  'src/js/utils/m3uparser.js',
  'src/js/utils/storage.js'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('Caching essential assets for offline support');
        return cache.addAll(urlsToCache);
      })
      .catch(err => {
        console.warn('Cache addAll warning:', err);
      })
  );
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames
          .filter(name => name !== CACHE_NAME)
          .map(name => caches.delete(name))
      );
    })
  );
  self.clients.claim();
});

self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);

  // Never intercept or cache video stream segments/manifests
  if (url.pathname.includes('.m3u8') || url.pathname.includes('.ts')) {
    return;
  }

  event.respondWith(
    caches.match(event.request).then(cachedResponse => {
      if (cachedResponse) {
        return cachedResponse;
      }
      return fetch(event.request).then(response => {
        if (!response || response.status !== 200 || response.type !== 'basic') {
          return response;
        }
        const responseToCache = response.clone();
        caches.open(CACHE_NAME).then(cache => {
          cache.put(event.request, responseToCache);
        });
        return response;
      }).catch(() => {
        return caches.match('./') || caches.match('index.html');
      });
    })
  );
});
