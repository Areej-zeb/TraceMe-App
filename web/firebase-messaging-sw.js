// Empty service worker for development stubbing
self.addEventListener('install', (event) => {
    self.skipWaiting();
});

self.addEventListener('activate', (event) => {
    event.waitUntil(self.clients.claim());
});

// Real implementation would handle background messages here
// But for "firebase_messaging" flutter web plugin, we often just need the file to exist.
