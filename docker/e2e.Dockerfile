# Playwright image tag must match @playwright/test in e2e/package.json
FROM mcr.microsoft.com/playwright:v1.49.1-noble
RUN apt-get update && apt-get install -y --no-install-recommends python3 && rm -rf /var/lib/apt/lists/*
WORKDIR /work
# node_modules lives in /work/node_modules so the bind mount of ./e2e does not hide it
COPY e2e/package.json /work/package.json
RUN npm install --no-audit --no-fund
WORKDIR /work/e2e
