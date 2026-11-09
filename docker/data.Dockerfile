FROM python:3.12.8-slim-bookworm
RUN pip install --no-cache-dir pytest==8.3.4
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1
