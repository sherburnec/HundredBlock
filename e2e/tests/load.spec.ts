import { test, expect } from '@playwright/test';
import { button, openHome, waitForPrecache } from './helpers';

// Records first-load and warm-load transfer size and time under a throttled network.
// Numbers are logged (see DECISIONS.md); the assertions are sanity bounds only.
test('first load and warm load size and time on a throttled network', async ({ page, context }) => {
  test.setTimeout(240_000);
  const cdp = await context.newCDPSession(page);
  await cdp.send('Network.enable');
  await cdp.send('Network.emulateNetworkConditions', {
    offline: false,
    latency: 40,
    downloadThroughput: (10 * 1024 * 1024) / 8, // 10 Mbit/s
    uploadThroughput: (5 * 1024 * 1024) / 8,
  });
  let bytes = 0;
  let requests = 0;
  cdp.on('Network.loadingFinished', (e: { encodedDataLength: number }) => {
    bytes += e.encodedDataLength;
    requests++;
  });

  const t0 = Date.now();
  await page.goto('');
  await expect(button(page, 'Play')).toBeVisible({ timeout: 120_000 });
  const coldMs = Date.now() - t0;
  const coldBytes = bytes;
  const coldRequests = requests;

  // the page is usable now; the service worker keeps downloading the rest in the background
  await waitForPrecache(page);
  const precacheBytes = bytes;
  const cache = await page.evaluate(async () => {
    const key = (await caches.keys()).find((k) => k.startsWith('hb-'))!;
    const c = await caches.open(key);
    const reqs = await c.keys();
    let total = 0;
    for (const r of reqs) total += (await (await c.match(r))!.clone().arrayBuffer()).byteLength;
    return { files: reqs.length, bytes: total };
  });

  bytes = 0;
  requests = 0;
  const t1 = Date.now();
  await page.reload();
  await expect(button(page, 'Play')).toBeVisible({ timeout: 60_000 });
  const warmMs = Date.now() - t1;
  const warmBytes = bytes;

  const mb = (n: number) => (n / 1024 / 1024).toFixed(2) + ' MB';
  console.log(
    `LOAD cold: ${coldMs} ms, ${mb(coldBytes)} over the wire in ${coldRequests} requests to first screen; ` +
      `total incl. background precache ${mb(precacheBytes)}; cache holds ${cache.files} files, ${mb(cache.bytes)} uncompressed; ` +
      `warm reload: ${warmMs} ms, ${mb(warmBytes)} over the wire`,
  );
  expect(cache.files).toBeGreaterThan(10);
  expect(warmBytes).toBeLessThan(coldBytes); // the warm load comes from the cache
});
