# syntax=docker/dockerfile:1

FROM python:3.12-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim AS runtime
ARG APP_VERSION=0.0.0
LABEL org.opencontainers.image.title="fastapi-app" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.source="https://github.com/Alagani/app_repository"

# Pull latest Debian security patches at build time rather than waiting on
# the upstream python:3.12-slim image to be rebuilt with them.
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

RUN addgroup --system --gid 1000 app && adduser --system --uid 1000 --ingroup app app
WORKDIR /app

COPY --from=builder /install /usr/local
COPY app ./app

# Numeric UID:GID, not the username — Kubernetes' runAsNonRoot check reads
# the image's declared user literally; a name (e.g. "app") can't be
# verified as non-root without running the container, and kubelet refuses
# to start it (CreateContainerConfigError: "image has non-numeric user").
USER 1000:1000
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/healthz')" || exit 1

ENTRYPOINT ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
