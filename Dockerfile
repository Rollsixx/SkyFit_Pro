# ────────────────────────────────────────────────────────────────────────────
# Stage 1 — Build Flutter Web
# ─────────────────────────────────────────────────────────────────────────────
FROM debian:bookworm-slim AS build-env

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip xz-utils zip libglu1-mesa ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV FLUTTER_VERSION=3.22.2
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN git clone --depth 1 --branch ${FLUTTER_VERSION} \
    https://github.com/flutter/flutter.git ${FLUTTER_HOME}

RUN flutter precache --web

WORKDIR /app
COPY . .
RUN flutter pub get

# All secrets injected at build time via --build-arg → --dart-define
# Values come from GCP Secret Manager via cloudbuild.yaml — never hardcoded
ARG OPENWEATHER_API_KEY
ARG EMAILJS_SERVICE_ID
ARG EMAILJS_TEMPLATE_ID
ARG EMAILJS_PUBLIC_KEY
ARG FIREBASE_API_KEY
ARG FIREBASE_PROJECT_ID
ARG FIREBASE_MESSAGING_SENDER_ID
ARG FIREBASE_APP_ID

RUN flutter build web --release \
    --dart-define=OPENWEATHER_API_KEY=${OPENWEATHER_API_KEY} \
    --dart-define=EMAILJS_SERVICE_ID=${EMAILJS_SERVICE_ID} \
    --dart-define=EMAILJS_TEMPLATE_ID=${EMAILJS_TEMPLATE_ID} \
    --dart-define=EMAILJS_PUBLIC_KEY=${EMAILJS_PUBLIC_KEY} \
    --dart-define=FIREBASE_API_KEY=${FIREBASE_API_KEY} \
    --dart-define=FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID} \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID} \
    --dart-define=FIREBASE_APP_ID=${FIREBASE_APP_ID}

# ─────────────────────────────────────────────────────────────────────────────
# Stage 2 — Serve with Nginx
# ─────────────────────────────────────────────────────────────────────────────
FROM nginx:1.27-alpine AS serve

RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Cloud Run listens on port 8080
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]