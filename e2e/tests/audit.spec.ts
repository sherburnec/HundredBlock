import { test, expect } from '@playwright/test';
import { button, offOrigin, openHome, startGame, tapMap, trackRequests } from './helpers';

// Network audit across every screen. Ko-fi is the only allowed outside hop, and only after a tap
// (it is never tapped here), so no popup may open and no request may leave the origin.
test('no requests leave the origin on any screen, and no popup opens', async ({ page, baseURL }) => {
  const urls = trackRequests(page);
  let popups = 0;
  page.on('popup', () => popups++);

  await openHome(page);
  await button(page, 'Stats').click();
  await expect(page.getByText('Best score').or(page.getByText(/No finished games yet/))).toBeVisible();
  await button(page, 'Back').click();
  await button(page, 'About').click();
  await expect(page.getByText(/Privacy/)).toBeVisible();
  await button(page, 'Back').click();

  await startGame(page, 10);
  await expect
    .poll(async () => {
      await tapMap(page);
      return button(page, 'Lock in').isEnabled();
    }, { timeout: 60_000 })
    .toBe(true);
  await button(page, 'Lock in').click();
  await expect(page.getByText(/^Round result\./)).toBeVisible();
  // pan and zoom the result map
  const vp = page.viewportSize()!;
  await page.mouse.move(vp.width / 2, vp.height / 2);
  await page.mouse.down();
  await page.mouse.move(vp.width / 2 + 100, vp.height / 2 + 40, { steps: 8 });
  await page.mouse.up();
  await page.mouse.wheel(0, -300);
  await page.waitForTimeout(800);
  await page.getByRole('button', { name: 'Quit game' }).click();
  await button(page, 'Quit').click();
  await expect(button(page, 'Play')).toBeVisible();

  const bad = offOrigin(urls, new URL(baseURL!).origin);
  expect(bad, `off-origin requests:\n${bad.join('\n')}`).toEqual([]);
  expect(popups).toBe(0);
});
