import { test, expect } from '@playwright/test';
import { hb, offOrigin, tapMap, waitForMap } from './helpers';

test('WebGL2 is available', async ({ page }) => {
  await page.goto('about:blank');
  const ok = await page.evaluate(() => !!document.createElement('canvas').getContext('webgl2'));
  expect(ok).toBe(true);
});

test('no third-party requests while driving the map', async ({ page, baseURL }) => {
  const urls: string[] = [];
  page.on('request', (r) => urls.push(r.url()));
  await page.goto('');
  await waitForMap(page);
  await tapMap(page);
  await expect.poll(() => hb(page, 'markerPlaced')).toBe(true);
  const vp = page.viewportSize()!;
  await page.mouse.move(vp.width / 2, vp.height / 2);
  await page.mouse.down();
  await page.mouse.move(vp.width / 2 + 120, vp.height / 2 + 60, { steps: 10 });
  await page.mouse.up();
  await page.mouse.wheel(0, -400);
  await page.waitForTimeout(1500);
  const origin = new URL(baseURL!).origin;
  const bad = offOrigin(urls, origin);
  expect(bad, `off-origin requests:\n${bad.join('\n')}`).toEqual([]);
});
