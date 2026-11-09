{{flutter_js}}
{{flutter_build_config}}

// No serviceWorkerSettings: Flutter's own worker is deprecated (a self-unregistering
// stub in 3.41). Hundred Block registers its own precaching worker, hb_sw.js.
_flutter.loader.load();

if ('serviceWorker' in navigator) {
  window.addEventListener('load', function () {
    navigator.serviceWorker.register('hb_sw.js').catch(function (e) {
      console.warn('service worker registration failed', e);
    });
  });
}
