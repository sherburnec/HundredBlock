# Pinned Flutter stable (see DECISIONS.md)
FROM ghcr.io/cirruslabs/flutter:3.41.9

# Android components that Gradle would otherwise download into the throwaway container
# on every `docker compose run --rm android` (pinned to what Flutter 3.41.9 asks for).
RUN yes | sdkmanager --licenses >/dev/null 2>&1 || true \
 && sdkmanager "ndk;28.2.13676358" "build-tools;35.0.0" "cmake;3.22.1" "platforms;android-35" >/dev/null

RUN git config --global --add safe.directory '*' \
 && flutter config --no-analytics --enable-web \
 && flutter precache --web --android
WORKDIR /app
