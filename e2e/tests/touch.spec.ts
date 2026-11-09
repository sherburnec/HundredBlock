import { test, expect, Page } from '@playwright/test';
import { button, openHome, startGame } from './helpers';

test.use({ hasTouch: true, isMobile: true, viewport: { width: 1024, height: 768 } });

type Pt = { x: number; y: number };

async function touch(page: Page, type: string, pts: Pt[]) {
  const cdp = await page.context().newCDPSession(page);
  await cdp.send('Input.dispatchTouchEvent', { type, touchPoints: pts.map((p, i) => ({ ...p, id: i })) });
  await cdp.detach();
}

async function cdpSession(page: Page) {
  const cdp = await page.context().newCDPSession(page);
  return {
    send: (type: string, pts: Pt[]) =>
      cdp.send('Input.dispatchTouchEvent', { type, touchPoints: pts.map((p, i) => ({ ...p, id: i })) }),
  };
}

test('touch: tap places a marker, drag pans without placing one, pinch does not zoom the page', async ({ page }) => {
  test.setTimeout(180_000);
  await openHome(page);
  await startGame(page, 10);
  await page.waitForTimeout(6000); // let the map finish loading
  const lock = button(page, 'Lock in');
  await expect(lock).toBeDisabled();

  const before = await page.screenshot();

  // one-finger drag: pans the map, must not place a marker, must not scroll the page
  const s = await cdpSession(page);
  const start = { x: 600, y: 400 };
  await s.send('touchStart', [start]);
  for (let i = 1; i <= 12; i++) await s.send('touchMove', [{ x: start.x - i * 20, y: start.y + i * 10 }]);
  await s.send('touchEnd', []);
  await page.waitForTimeout(700);
  await expect(lock).toBeDisabled();
  const afterDrag = await page.screenshot();
  expect(Buffer.compare(before, afterDrag)).not.toBe(0); // the map moved
  expect(await page.evaluate(() => [window.scrollX, window.scrollY])).toEqual([0, 0]);

  // two-finger pinch (spread): zooms the map, never the page
  const a = { x: 500, y: 400 };
  const b = { x: 560, y: 400 };
  await s.send('touchStart', [a, b]);
  for (let i = 1; i <= 10; i++) {
    await s.send('touchMove', [{ x: a.x - i * 15, y: a.y }, { x: b.x + i * 15, y: b.y }]);
  }
  await s.send('touchEnd', []);
  await page.waitForTimeout(700);
  expect(await page.evaluate(() => window.visualViewport!.scale)).toBe(1);
  expect(await page.evaluate(() => [window.scrollX, window.scrollY])).toEqual([0, 0]);
  await expect(lock).toBeDisabled(); // a pinch is not a tap either
  const afterPinch = await page.screenshot();
  expect(Buffer.compare(afterDrag, afterPinch)).not.toBe(0);

  // a tap places the marker
  await page.touchscreen.tap(520, 380);
  await expect(lock).toBeEnabled();
});

test('touch: a downward pull at the top of the page does not scroll or refresh it', async ({ page }) => {
  await openHome(page);
  await startGame(page, 10);
  await page.waitForTimeout(4000);
  const s = await cdpSession(page);
  await s.send('touchStart', [{ x: 500, y: 90 }]);
  for (let i = 1; i <= 10; i++) await s.send('touchMove', [{ x: 500, y: 90 + i * 40 }]);
  await s.send('touchEnd', []);
  await page.waitForTimeout(500);
  expect(await page.evaluate(() => [window.scrollX, window.scrollY])).toEqual([0, 0]);
  await expect(page.getByText('Round 1 of 10')).toBeVisible(); // still the same page, not reloaded
});
