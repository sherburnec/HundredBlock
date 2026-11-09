FROM python:3.12.8-slim-bookworm
RUN pip install --no-cache-dir duckdb==2.0.0 shapely==2.2.0 pytest==9.2.0 jsonschema==4.26.0
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
