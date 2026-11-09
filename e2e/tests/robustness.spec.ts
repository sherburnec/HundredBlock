import { test, expect, Page } from '@playwright/test';
import { button, openHome, playRound, startGame, tapMap } from './helpers';

async function playTen(page: Page) {
  await startGame(page, 10);
  for (let i = 1; i <= 10; i++) await playRound(page, i, 10, 0.3 + 0.04 * i, 0.5);
}

test('corrupt saved stats: notice shown, backup kept, new games still save', async ({ page, context }) => {
  test.setTimeout(180_000);
  await context.addInitScript(() => {
    try {
      if (!localStorage.getItem('hb.seeded')) {
        localStorage.setItem('hb.games.v1', '{broken');
        localStorage.setItem('hb.seeded', '1');
      }
    } catch {
      /* ignore */
    }
  });
  await openHome(page);
  await button(page, 'Stats').click();
  await expect(page.getByText(/could not be read/)).toBeVisible();
  await button(page, 'Back').click();

  await playTen(page);
  await expect(page.getByText('Saved to stats.').first()).toBeVisible();
  await button(page, 'Home').click();
  await button(page, 'Stats').click();
  await expect(page.getByText(/^10 rounds: /)).toBeVisible();
  const backup = await page.evaluate(() => localStorage.getItem('hb.games.v1.corrupt'));
  expect(backup).toBe('{broken');
});

test('storage disabled or full: the game is still playable and says stats could not be saved', async ({ page, context }) => {
  test.setTimeout(180_000);
  await context.addInitScript(() => {
    Storage.prototype.setItem = function () {
      throw new DOMException('quota', 'QuotaExceededError');
    };
  });
  await openHome(page);
  await playTen(page);
  await expect(page.getByText('Game complete')).toBeVisible();
  await expect(page.getByText(/could not be saved/).first()).toBeVisible();
});

test('rapid double tap on Lock in scores the round once', async ({ page }) => {
  await openHome(page);
  await startGame(page, 10);
  await expect
    .poll(async () => {
      await tapMap(page);
      return button(page, 'Lock in').isEnabled();
    }, { timeout: 60_000 })
    .toBe(true);
  await button(page, 'Lock in').dblclick({ delay: 0 });
  await expect(page.getByText(/^Round result\./)).toHaveCount(1);
  await button(page, 'Next round').click();
  await expect(page.getByText('Round 2 of 10')).toBeVisible(); // one round advanced, not two
});

test('the round timer pauses while the tab is hidden', async ({ page }) => {
  await openHome(page);
  await startGame(page, 10);
  await page.waitForTimeout(3000);
  const left = async () => {
    const t = (await page.getByText(/^Time left: \d+ seconds$/).textContent()) ?? '';
    return parseInt(t.replace(/\D/g, ''), 10);
  };
  const before = await left();
  await page.evaluate(() => {
    Object.defineProperty(document, 'visibilityState', { configurable: true, get: () => 'hidden' });
    document.dispatchEvent(new Event('visibilitychange'));
  });
  await page.waitForTimeout(6000);
  await page.evaluate(() => {
    Object.defineProperty(document, 'visibilityState', { configurable: true, get: () => 'visible' });
    document.dispatchEvent(new Event('visibilitychange'));
  });
  await page.waitForTimeout(1500);
  const after = await left();
  // About 7.5 s passed on the wall clock, but only about 1.5 s of it was visible.
  expect(before - after).toBeLessThanOrEqual(3);
  expect(after).toBeGreaterThan(0);
});
