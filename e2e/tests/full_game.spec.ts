import { test, expect } from '@playwright/test';
import { button, offOrigin, openHome, playRound, startGame, trackRequests } from './helpers';

test('WebGL2 is available', async ({ page }) => {
  await page.goto('about:blank');
  const ok = await page.evaluate(() => !!document.createElement('canvas').getContext('webgl2'));
  expect(ok).toBe(true);
});

for (const rounds of [10, 25, 50]) {
  test(`full ${rounds} round game on the real map, no off-origin requests`, async ({ page, baseURL }) => {
    test.setTimeout(rounds === 50 ? 600_000 : 300_000);
    const urls = trackRequests(page);
    await openHome(page);
    await startGame(page, rounds);

    let sum = 0;
    for (let i = 1; i <= rounds; i++) {
      // vary the tap so distances (and points) differ between rounds
      sum += await playRound(page, i, rounds, 0.3 + 0.4 * ((i * 7) % 10) / 10, 0.3 + 0.4 * ((i * 3) % 10) / 10);
    }

    await expect(page.getByText('Game complete')).toBeVisible();
    const total = page.getByText(/^Total score: /);
    await expect(total).toBeVisible();
    const text = (await total.textContent()) ?? '';
    const shown = parseInt(text.replace(/^Total score: /, '').replace(/,/g, ''), 10);
    expect(shown).toBe(sum);
    await expect(page.getByText(new RegExp(`^Rounds: ${rounds}$`))).toBeVisible();
    await expect(page.getByText(/^Average per round: /)).toBeVisible();
    await expect(page.getByText(/^Best round: /)).toBeVisible();

    await button(page, 'Home').click();
    await expect(button(page, 'Play')).toBeVisible();

    const bad = offOrigin(urls, new URL(baseURL!).origin);
    expect(bad, `off-origin requests:\n${bad.join('\n')}`).toEqual([]);
  });
}
