import { defineConfig } from '@playwright/test';

// BASE_URL is the served app, e.g. http://localhost/ or http://localhost/hundred-block/
const baseURL = (process.env.BASE_URL ?? 'http://localhost/').replace(/\/?$/, '/');

const projects = [
  {
    name: 'chromium',
    use: {
      browserName: 'chromium' as const,
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
  },
];
// WebKit is opt-in (WEBKIT=1): headless WebKit on Linux may lack WebGL2.
if (process.env.WEBKIT === '1') {
  projects.push({ name: 'webkit', use: { browserName: 'webkit' as never, launchOptions: { args: [] } } });
}

export default defineConfig({
  testDir: './tests',
  timeout: 120_000,
  workers: 1,
  reporter: [['list']],
  use: { baseURL, screenshot: 'only-on-failure' },
  projects,
});
