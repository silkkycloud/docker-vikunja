####################################################################################################
## Builder
####################################################################################################
FROM golang:1-alpine AS builder

ENV GO111MODULE=on

RUN apk add --no-cache \
    ca-certificates \
    build-base \
    git

RUN --mount=type=cache,target=/tmp/git_cache \
    git clone --depth 1 --branch v0.18.1 https://kolaente.dev/vikunja/api.git /tmp/git_cache/vikunja; \
    cd /tmp/git_cache/vikunja \ 
    && cp -r ./ /tmp/vikunja

WORKDIR /vikunja

RUN cp -r /tmp/vikunja/. /vikunja/. \
    && rm -rf /tmp/vikunja

# Build Vikunja
RUN go install github.com/magefile/mage \
    && mage build:clean build

####################################################################################################
## Final image
####################################################################################################
FROM alpine:3.14

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
    CMD wget --spider --q http://localhost:3456/api/v1/info