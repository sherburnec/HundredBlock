import { test, expect } from '@playwright/test';
import { hb, tapMap, waitForMap, waitForPrecache } from './helpers';

test('works offline after first load (reload and a fresh page)', async ({ page, context }) => {
  await page.goto('');
  await waitForMap(page);
  await waitForPrecache(page);
  await page.reload(); // now controlled by the service worker
  await waitForMap(page);

  await context.setOffline(true);
  await page.reload();
  await waitForMap(page);
  await tapMap(page);
  await expect.poll(() => hb(page, 'markerPlaced')).toBe(true);

  const page2 = await context.newPage();
  await page2.goto('');
  await waitForMap(page2);
  await tapMap(page2);
  await expect.poll(() => hb(page2, 'markerPlaced')).toBe(true);
});
