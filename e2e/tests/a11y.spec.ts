import { test, expect, Page } from '@playwright/test';
import { button, openHome, playRound, startGame } from './helpers';

/** Every button on screen has a non-empty accessible name. */
async function expectNamedButtons(page: Page, where: string) {
  const names = await page.evaluate(() =>
    Array.from(document.querySelectorAll('flt-semantics[role="button"]')).map(
      (n) => (n.getAttribute('aria-label') || n.textContent || '').trim(),
    ),
  );
  expect(names.length, `${where}: has buttons`).toBeGreaterThan(0);
  for (const n of names) expect(n, `${where}: unnamed button`).not.toBe('');
}

test('screens expose named buttons, headings and the prompt to assistive tech', async ({ page }) => {
  test.setTimeout(180_000);
  await openHome(page);
  await expectNamedButtons(page, 'home');
  await button(page, 'Stats').click();
  await expect(page.getByRole('button', { name: 'Back' })).toBeVisible();
  await expectNamedButtons(page, 'stats');
  await button(page, 'Back').click();
  await button(page, 'About').click();
  await expectNamedButtons(page, 'about');
  await button(page, 'Back').click();

  await button(page, 'Play').click();
  await expectNamedButtons(page, 'length');
  await button(page, '10 rounds').click();
  await expect(page.getByText('Round 1 of 10')).toBeVisible();
  await expectNamedButtons(page, 'round');
  // the prompt and the countdown are readable text
  await expect(page.getByText(/^Find .+/)).toBeVisible();
  await expect(page.getByText(/^Time left: \d+ seconds$/)).toBeVisible();
  await expect(page.getByLabel('Street map. Tap to place your marker.')).toHaveCount(1);
  await playRound(page, 1, 10);
  await expectNamedButtons(page, 'next round');
});

test('works with reduced motion requested', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await openHome(page);
  await startGame(page, 10);
  await playRound(page, 1, 10);
  await expect(page.getByText('Round 2 of 10')).toBeVisible();
});
