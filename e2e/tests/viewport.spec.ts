import * as fs from 'fs';
import { test, expect } from '@playwright/test';
import { button, openHome, startGame, tapMap } from './helpers';

const sizes: [string, number, number][] = [
  ['1024x768', 1024, 768],
  ['1280x800', 1280, 800],
  ['1440x960', 1440, 960],
  ['768x1024-portrait', 768, 1024],
  ['390x844-phone', 390, 844],
];

fs.mkdirSync('/work/e2e/screenshots', { recursive: true });

for (const [name, width, height] of sizes) {
  test(`layout at ${name}`, async ({ page, browserName }) => {
    test.setTimeout(180_000);
    await page.setViewportSize({ width, height });
    await openHome(page);
    await page.waitForTimeout(1500); // let the canvas repaint before the picture
    await page.screenshot({ path: `/work/e2e/screenshots/${browserName}-${name}-home.png` });
    const overflow = () =>
      page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
    expect(await overflow()).toBeLessThanOrEqual(0);

    await startGame(page, 10);
    await expect
      .poll(async () => {
        await tapMap(page);
        return button(page, 'Lock in').isEnabled();
      }, { timeout: 60_000 })
      .toBe(true);
    await page.waitForTimeout(4000);
    await page.screenshot({ path: `/work/e2e/screenshots/${browserName}-${name}-round.png` });

    // prompt sits above the map, inside the viewport
    const prompt = await page.getByText(/^Find /).boundingBox();
    expect(prompt, 'prompt visible').not.toBeNull();
    expect(prompt!.y).toBeGreaterThanOrEqual(0);
    expect(prompt!.y + prompt!.height).toBeLessThan(height * 0.3);
    expect(prompt!.x + prompt!.width).toBeLessThanOrEqual(width);

    // Lock in is reachable and at least 48 px tall; Quit too
    const lock = await button(page, 'Lock in').boundingBox();
    expect(lock).not.toBeNull();
    expect(lock!.y + lock!.height).toBeLessThanOrEqual(height);
    expect(lock!.x + lock!.width).toBeLessThanOrEqual(width);
    expect(lock!.height).toBeGreaterThanOrEqual(48);
    const quit = await page.getByRole('button', { name: 'Quit game' }).boundingBox();
    expect(quit!.height).toBeGreaterThanOrEqual(48);
    expect(quit!.width).toBeGreaterThanOrEqual(48);

    await button(page, 'Lock in').click();
    await expect(page.getByText(/^Round result\./)).toBeVisible();
    await page.waitForTimeout(4000);
    await page.screenshot({ path: `/work/e2e/screenshots/${browserName}-${name}-result.png` });
    const next = await button(page, 'Next round').boundingBox();
    expect(next!.height).toBeGreaterThanOrEqual(48);
    expect(next!.y + next!.height).toBeLessThanOrEqual(height);
    expect(await overflow()).toBeLessThanOrEqual(0);
  });
}
