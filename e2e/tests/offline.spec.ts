import { test, expect } from '@playwright/test';
import { button, openHome, playRound, startGame, waitForPrecache } from './helpers';

test('offline: reload, a full game, Stats and About all work with the network off', async ({ page, context }) => {
  test.setTimeout(240_000);
  await openHome(page);
  await waitForPrecache(page);
  await page.reload(); // now controlled by the service worker
  await expect(button(page, 'Play')).toBeVisible();

  await context.setOffline(true);
  await page.reload();
  await expect(button(page, 'Play')).toBeVisible();

  await startGame(page, 10);
  let sum = 0;
  for (let i = 1; i <= 10; i++) sum += await playRound(page, i, 10, 0.3 + 0.04 * i, 0.5);
  await expect(page.getByText('Game complete')).toBeVisible();
  await expect(page.getByText(/^Total score: /)).toContainText(sum.toLocaleString('en-US'));
  await expect(page.getByText('Saved to stats.').first()).toBeVisible();
  await button(page, 'Home').click();

  await button(page, 'Stats').click();
  await expect(page.getByText(/^10 rounds: /)).toBeVisible();
  await button(page, 'Back').click();
  await button(page, 'About').click();
  await expect(page.getByText(/© OpenStreetMap contributors/)).toBeVisible();
  await button(page, 'Back').click();

  // A second, fresh page in the same offline context still loads and plays.
  const page2 = await context.newPage();
  await page2.goto('');
  await expect(button(page2, 'Play')).toBeVisible({ timeout: 60_000 });
  await startGame(page2, 10);
  await playRound(page2, 1, 10);
});
