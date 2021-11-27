####################################################################################################
## Builder
####################################################################################################
FROM golang:1-alpine AS builder

ENV GO111MODULE=on

RUN apk add --no-cache \
    ca-certificates \
    build-base \
    git \
    tar

# Install Mage
RUN go get -u -d github.com/magefile/mage \
    && cd $GOPATH/src/github.com/magefile/mage \
    && go run bootstrap.go

WORKDIR /vikunja

ADD https://kolaente.dev/vikunja/api/archive/v0.18.1.tar.gz /tmp/vikunja.tar.gz
RUN tar xvfz /tmp/vikunja.tar.gz -C /tmp \
    && cp -r /tmp/api/. /vikunja

# Build Vikunja
RUN mage build:clean build

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
    CMD wget --spider --q http://localhost:3456/api/v1/info