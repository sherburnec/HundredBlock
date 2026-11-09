FROM mcr.microsoft.com/playwright:v1.49.1-noble
WORKDIR /work/e2e
RUN apt-get update && apt-get install -y --no-install-recommends python3 && rm -rf /var/lib/apt/lists/*
