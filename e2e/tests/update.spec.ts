import * as fs from 'fs';
import { test, expect } from '@playwright/test';
import { button, openHome, waitForPrecache } from './helpers';

// Simulates a new build by editing the served files in place (restored afterwards): the service
// worker script changes (new cache name) and one precached asset changes. The new worker must
// install its own cache, delete the old one, and the app must keep working, including offline.
// (The browser's service worker update check cannot be intercepted by Playwright routes, so the
// files on disk are changed instead.)
const SW = '/work/build/web/hb_sw.js';
const CSS = '/work/build/web/maplibre/maplibre-gl.css';

test('a new build replaces the old cache and leaves no stale or broken app', async ({ page, context }) => {
  test.setTimeout(180_000);
  const swOriginal = fs.readFileSync(SW, 'utf8');
  const cssOriginal = fs.readFileSync(CSS, 'utf8');
  try {
    await openHome(page);
    await waitForPrecache(page);
    const keysNow = () => page.evaluate(async () => (await caches.keys()).filter((k) => k.startsWith('hb-')));
    const oldKeys = await keysNow();
    expect(oldKeys).toHaveLength(1);

    // "deploy" build v2
    fs.writeFileSync(SW, swOriginal.replace(/const VERSION = '[^']*'/, "const VERSION = 'v2test'"));
    fs.writeFileSync(CSS, cssOriginal + '\n/* build-v2 */');

    await page.evaluate(async () => {
      const reg = await navigator.serviceWorker.getRegistration();
      await reg!.update();
    });
    await expect.poll(keysNow, { timeout: 60_000 }).toEqual(['hb-v2test']); // old cache deleted

    // The next load uses the new build and still works.
    await page.reload();
    await expect(button(page, 'Play')).toBeVisible();
    const css = await page.evaluate(async () => (await fetch('maplibre/maplibre-gl.css')).text());
    expect(css).toContain('build-v2');

    // The new cache is complete: it works offline too.
    await context.setOffline(true);
    await page.reload();
    await expect(button(page, 'Play')).toBeVisible();
  } finally {
    fs.writeFileSync(SW, swOriginal);
    fs.writeFileSync(CSS, cssOriginal);
  }
});
