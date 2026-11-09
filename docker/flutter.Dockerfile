# Pinned Flutter stable (see DECISIONS.md)
FROM ghcr.io/cirruslabs/flutter:3.41.9

RUN git config --global --add safe.directory '*' \
 && flutter config --no-analytics --enable-web \
 && flutter precache --web
WORKDIR /app
