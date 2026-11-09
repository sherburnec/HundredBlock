import { Page, expect } from '@playwright/test';

/** Wait until our service worker is active and the precache is complete. */
export async function waitForPrecache(page: Page) {
  await page.waitForFunction(
    async () => {
      const reg = await navigator.serviceWorker.getRegistration();
      if (!reg || !reg.active || reg.active.state !== 'activated') return false;
      const keys = (await caches.keys()).filter((k) => k.startsWith('hb-'));
      if (keys.length !== 1) return false;
      const n = (await (await caches.open(keys[0])).keys()).length;
      return n > 10;
    },
    null,
    { timeout: 90_000 },
  );
}

export function offOrigin(urls: string[], origin: string) {
  return urls.filter((u) => !(u.startsWith(origin) || u.startsWith('data:') || u.startsWith('blob:')));
}

/** Records every request the page makes. */
export function trackRequests(page: Page) {
  const urls: string[] = [];
  page.on('request', (r) => urls.push(r.url()));
  return urls;
}

export const button = (page: Page, name: string | RegExp) =>
  page.getByRole('button', { name, exact: typeof name === 'string' });

export async function openHome(page: Page) {
  await page.goto('');
  await expect(button(page, 'Play')).toBeVisible({ timeout: 60_000 });
}

export async function startGame(page: Page, rounds: number) {
  await button(page, 'Play').click();
  await button(page, `${rounds} rounds`).click();
  await expect(page.getByText(`Round 1 of ${rounds}`)).toBeVisible();
}

/** Tap the map area (between the header and the bottom bar). */
export async function tapMap(page: Page, fx = 0.5, fy = 0.5) {
  const vp = page.viewportSize()!;
  await page.mouse.click(vp.width * fx, 70 + (vp.height - 70 - 90) * fy);
}

/** Place a marker, lock in, return the points shown. */
export async function playRound(page: Page, i: number, rounds: number, fx = 0.5, fy = 0.5) {
  await expect(page.getByText(`Round ${i} of ${rounds}`)).toBeVisible();
  const lock = button(page, 'Lock in');
  // The map may still be loading: keep tapping until a marker is accepted.
  await expect
    .poll(
      async () => {
        await tapMap(page, fx, fy);
        return lock.isEnabled();
      },
      { timeout: 60_000, intervals: [300, 500, 1000] },
    )
    .toBe(true);
  await lock.click();
  const result = page.getByText(/^Round result\./);
  await expect(result).toBeVisible();
  const label = (await result.textContent()) ?? '';
  const m = label.match(/([\d,]+) points\.$/);
  expect(m, `result text: ${label}`).not.toBeNull();
  const points = parseInt(m![1].replace(/,/g, ''), 10);
  await button(page, i === rounds ? 'Finish' : 'Next round').click();
  return points;
}

export { expect };
