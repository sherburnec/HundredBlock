import { test, expect } from '@playwright/test';
import { button, openHome, playRound, startGame, waitForPrecache } from './helpers';

test('works offline after first load (reload and a fresh page)', async ({ page, context }) => {
  await openHome(page);
  await waitForPrecache(page);
  await page.reload(); // now controlled by the service worker
  await expect(button(page, 'Play')).toBeVisible();

  await context.setOffline(true);
  await page.reload();
  await expect(button(page, 'Play')).toBeVisible();
  await startGame(page, 10);
  await playRound(page, 1, 10);

  const page2 = await context.newPage();
  await page2.goto('');
  await expect(button(page2, 'Play')).toBeVisible();
});
