ARG VIKUNJA_VERSION=0.18.1

####################################################################################################
## Builder
####################################################################################################
FROM golang:1-alpine AS builder

ARG VIKUNJA_VERSION

ENV GO111MODULE=on

RUN apk add --no-cache \
    ca-certificates \
    build-base \
    git \
    tar

# Install Mage
RUN git clone https://github.com/magefile/mage \
    && cd mage \
    && go run bootstrap.go

WORKDIR /vikunja

RUN git clone --depth 1 --branch v${VIKUNJA_VERSION} https://kolaente.dev/vikunja/api.git /tmp/vikunja \ 
    && cp -r /tmp/vikunja/. /vikunja

# Build Vikunja
RUN mage build:clean build

####################################################################################################
## Final image
####################################################################################################
FROM alpine:3.15

ARG VIKUNJA_VERSION
ENV VIKUNJA_SERVICE_ROOTPATH=/vikunja/

RUN apk add --no-cache \
    ca-certificates \
    tini \
    shadow \
    tzdata

WORKDIR /vikunja

COPY --from=builder /vikunja /vikunja

# Add an unprivileged user and set directory permissions
RUN adduser --disabled-password --gecos "" --no-create-home vikunja \
    && chown -R vikunja:vikunja /vikunja

# Make persistent data directory
RUN mkdir -p /vikunja/files \
    && chown -R vikunja:vikunja /vikunja/files

ENTRYPOINT ["/sbin/tini", "--"]

USER vikunja

CMD ["./vikunja"]

VOLUME /vikunja/files

EXPOSE 3456

STOPSIGNAL SIGTERM

HEALTHCHECK \
    --start-period=15s \
    --interval=1m \
    --timeout=5s \
    CMD wget --spider --q http://localhost:3456/api/v1/info || exit 1

# Image metadata
LABEL org.opencontainers.image.version=${VIKUNJA_VERSION}
LABEL org.opencontainers.image.title=Vikunja
LABEL org.opencontainers.image.description="The to-do app to organize your life. Vikunja is an open-source, self-hosted to-do list application for all platforms."
LABEL org.opencontainers.image.url=https://tasks.silkky.cloud
LABEL org.opencontainers.image.vendor="Silkky.Cloud"
LABEL org.opencontainers.image.licenses=Unlicense
LABEL org.opencontainers.image.source="https://github.com/silkkycloud/docker-vikunja"