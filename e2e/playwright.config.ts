import { defineConfig } from '@playwright/test';

// BASE_URL is the served app, e.g. http://serve/ or http://serve/hundred-block/
const baseURL = (process.env.BASE_URL ?? 'http://localhost/').replace(/\/?$/, '/');

export default defineConfig({
  testDir: './tests',
  timeout: 120_000,
  workers: 1,
  reporter: [['list']],
  use: {
    baseURL,
    launchOptions: {
      args: [
        '--use-angle=swiftshader',
        '--use-gl=angle',
        '--enable-unsafe-swiftshader',
        '--ignore-gpu-blocklist',
        '--enable-webgl',
      ],
    },
  },
  projects: [{ name: 'chromium', use: { browserName: 'chromium' } }],
});
