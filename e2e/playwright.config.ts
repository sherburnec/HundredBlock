import { defineConfig } from '@playwright/test';

// BASE_URL is the served app, e.g. http://localhost/ or http://localhost/hundred-block/
const baseURL = (process.env.BASE_URL ?? 'http://localhost/').replace(/\/?$/, '/');

export default defineConfig({
  testDir: './tests',
  timeout: 120_000,
  workers: 1,
  reporter: [['list']],
  use: { baseURL, screenshot: 'only-on-failure' },
  projects: [
    {
      name: 'chromium',
      use: {
        browserName: 'chromium',
        launchOptions: {
          // Software WebGL2 so the map runs in headless Chromium.
          args: [
            '--use-angle=swiftshader',
            '--use-gl=angle',
            '--enable-unsafe-swiftshader',
            '--ignore-gpu-blocklist',
            '--enable-webgl',
          ],
        },
      },
    },
    {
      // WebKit runs the viewport/layout matrix only: Playwright's WebKit cannot emulate offline
      // with a service worker, and touch is Chromium-driven via CDP.
      name: 'webkit',
      testMatch: /viewport\.spec\.ts/,
      use: { browserName: 'webkit' },
    },
  ],
});
