import { test, expect } from '@playwright/test';
import { openHome, startGame, tapMap, button } from './helpers';

test('map pan/zoom frame times with the real city (indicative, software GL)', async ({ page }, info) => {
  await openHome(page);
  await startGame(page, 10);
  await expect
    .poll(
      async () => {
        await tapMap(page);
        return button(page, 'Lock in').isEnabled();
      },
      { timeout: 60_000, intervals: [300, 500, 1000] },
    )
    .toBe(true);
  await page.evaluate(() => {
    const w = window as any;
    w.__frames = [];
    let last = performance.now();
    const loop = (t: number) => {
      w.__frames.push(t - last);
      last = t;
      requestAnimationFrame(loop);
    };
    requestAnimationFrame(loop);
  });
  const vp = page.viewportSize()!;
  const cx = vp.width / 2;
  const cy = vp.height / 2;
  for (let i = 0; i < 4; i++) {
    await page.mouse.move(cx, cy);
    await page.mouse.down();
    await page.mouse.move(cx + 200, cy + 100, { steps: 30 });
    await page.mouse.move(cx, cy, { steps: 30 });
    await page.mouse.up();
    await page.mouse.wheel(0, -300);
    await page.waitForTimeout(400);
    await page.mouse.wheel(0, 300);
    await page.waitForTimeout(400);
  }
  const frames: number[] = await page.evaluate(() => (window as any).__frames.slice(5));
  const s = [...frames].sort((a, b) => a - b);
  const median = s[Math.floor(s.length / 2)];
  const p95 = s[Math.floor(s.length * 0.95)];
  const line = `frames=${s.length} median=${median.toFixed(1)}ms p95=${p95.toFixed(1)}ms`;
  console.log('PERF ' + line);
  info.annotations.push({ type: 'perf', description: line });
  expect(median).toBeLessThan(100); // sanity bound only; real numbers are logged
});
