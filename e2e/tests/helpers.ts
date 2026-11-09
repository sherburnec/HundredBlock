import { Page, expect } from '@playwright/test';

export async function waitForMap(page: Page) {
  await page.waitForFunction(() => (window as any).__hb?.mapLoaded === true, null, {
    timeout: 60_000,
  });
}

/** Wait until our service worker is active, controlling the page, and precache is complete. */
export async function waitForPrecache(page: Page) {
  await page.waitForFunction(
    async () => {
      const reg = await navigator.serviceWorker.getRegistration();
      if (!reg || !reg.active || reg.active.state !== 'activated') return false;
      const keys = (await caches.keys()).filter((k) => k.startsWith('hb-'));
      if (keys.length !== 1) return false;
      const n = (await (await caches.open(keys[0])).keys()).length;
      return n > 10;
    },
    null,
    { timeout: 90_000 },
  );
}

export async function tapMap(page: Page, fx = 0.5, fy = 0.5) {
  const vp = page.viewportSize()!;
  await page.mouse.click(vp.width * fx, vp.height * fy);
}

export async function hb(page: Page, key: string) {
  return page.evaluate((k) => (window as any).__hb?.[k], key);
}

export function offOrigin(urls: string[], origin: string) {
  return urls.filter((u) => !(u.startsWith(origin) || u.startsWith('data:') || u.startsWith('blob:')));
}

export { expect };
