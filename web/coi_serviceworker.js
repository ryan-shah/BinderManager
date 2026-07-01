// Injects Cross-Origin-Opener-Policy / Cross-Origin-Embedder-Policy headers
// so the page becomes crossOriginIsolated, enabling SharedArrayBuffer and
// OPFS-backed sqlite3 storage. Needed because static hosts (GitHub Pages)
// cannot set response headers.
//
// COEP `credentialless` is used instead of `require-corp` so cross-origin
// card images from Scryfall keep loading without CORP headers. Browsers
// without credentialless support (e.g. Safari) simply stay non-isolated and
// drift falls back to IndexedDB storage — no breakage.

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.cache === 'only-if-cached' && request.mode !== 'same-origin') {
    return;
  }

  // Strip credentials from no-cors cross-origin requests, as credentialless
  // COEP requires.
  const outgoing = request.mode === 'no-cors'
    ? new Request(request, { credentials: 'omit' })
    : request;

  event.respondWith(
    fetch(outgoing).then((response) => {
      if (response.status === 0) {
        return response;
      }
      const headers = new Headers(response.headers);
      headers.set('Cross-Origin-Embedder-Policy', 'credentialless');
      headers.set('Cross-Origin-Opener-Policy', 'same-origin');
      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers,
      });
    })
  );
});
