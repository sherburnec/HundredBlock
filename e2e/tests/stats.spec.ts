import { test, expect } from '@playwright/test';
import { button, offOrigin, openHome, playRound, startGame, trackRequests } from './helpers';

test('stats persist across reload, export is valid, About shows attribution, no Ko-fi at launch', async ({
  page,
  baseURL,
}) => {
  test.setTimeout(240_000);
  const urls = trackRequests(page);
  await openHome(page);
  await expect(page.getByText('Support on Ko-fi')).toHaveCount(0);

  await startGame(page, 10);
  let sum = 0;
  for (let i = 1; i <= 10; i++) {
    sum += await playRound(page, i, 10, 0.35 + 0.03 * i, 0.4);
    // The Ko-fi prompt never shows after a short session.
    await expect(page.getByText('Support on Ko-fi')).toHaveCount(0);
  }
  await expect(page.getByText('Saved to stats.').first()).toBeVisible(); // live regions also announce
  await button(page, 'Home').click();

  // Stats survive a reload.
  await page.reload();
  await expect(button(page, 'Play')).toBeVisible({ timeout: 60_000 });
  await expect(page.getByText('Support on Ko-fi')).toHaveCount(0);
  await button(page, 'Stats').click();
  await expect(page.getByText('Best score')).toBeVisible();
  await expect(page.getByText(/^10 rounds: /)).toBeVisible();
  await expect(page.getByText(new RegExp(`^Game g_0001\\. .*10 rounds: ${sum.toLocaleString('en-US')} total`))).toBeVisible();

  // Export downloads a valid version 1 file.
  const [download] = await Promise.all([
    page.waitForEvent('download'),
    button(page, 'Export stats (JSON)').click(),
  ]);
  expect(download.suggestedFilename()).toMatch(/^hundred-block-stats-\d{4}-\d{2}-\d{2}\.json$/);
  const stream = await download.createReadStream();
  const chunks: Buffer[] = [];
  for await (const c of stream) chunks.push(c as Buffer);
  const doc = JSON.parse(Buffer.concat(chunks).toString('utf8'));
  expect(doc.version).toBe(1);
  expect(typeof doc.exportedAt).toBe('string');
  expect(doc.games).toHaveLength(1);
  const g = doc.games[0];
  expect(g).toMatchObject({ id: 'g_0001', city: 'burbank', tier: 'tier1', rounds: 10, totalScore: sum });
  expect(g.roundResults).toHaveLength(10);
  for (const r of g.roundResults) {
    expect(typeof r.prompt).toBe('string');
    expect(typeof r.seconds).toBe('number');
    expect(Number.isInteger(r.points)).toBe(true);
  }
  expect(g.roundResults.reduce((a: number, r: { points: number }) => a + r.points, 0)).toBe(sum);

  // About: attribution built from the pack, privacy note.
  await button(page, 'Back').click();
  await button(page, 'About').click();
  await expect(page.getByText(/© OpenStreetMap contributors/)).toBeVisible();
  await expect(page.getByText(/Overture Maps Foundation/).first()).toBeVisible();
  await expect(page.getByText(/No accounts, no analytics and no tracking/)).toBeVisible();

  const bad = offOrigin(urls, new URL(baseURL!).origin);
  expect(bad, `off-origin requests:\n${bad.join('\n')}`).toEqual([]);
});
