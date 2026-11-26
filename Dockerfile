ARG IMG_TAG=latest
ARG PLATFORM="linux/amd64"
ARG GO_VERSION=1.26.7

FROM --platform=${PLATFORM} golang:${GO_VERSION}-alpine as builder
WORKDIR /src/app/
COPY go.mod go.sum* ./
RUN go mod download
COPY . .

ENV PACKAGES curl make git libc-dev bash gcc linux-headers eudev-dev python3
RUN apk add --no-cache $PACKAGES
RUN set -eux; apk add --no-cache ca-certificates build-base;

ARG VERSION=""
ARG TARGET_GOOS=linux
ARG TARGET_GOARCH=amd64
ARG LEDGER_ENABLED=true
ARG CGO_ENABLED=1
RUN if [ "$TARGET_GOOS" = "darwin" ]; then \
      CGO_ENABLED=0 GOOS=$TARGET_GOOS GOARCH=$TARGET_GOARCH LEDGER_ENABLED=false make build; \
    else \
      CGO_ENABLED=$CGO_ENABLED GOOS=$TARGET_GOOS GOARCH=$TARGET_GOARCH \
        LEDGER_ENABLED=$LEDGER_ENABLED LINK_STATICALLY=true LDFLAGS=-buildid=$VERSION make build; \
    fi

FROM scratch AS artifact
COPY --from=builder /src/app/build/bcnad /usr/local/bin/bcnad

# Add to a distroless container
FROM --platform=${PLATFORM} gcr.io/distroless/cc:$IMG_TAG
ARG IMG_TAG
COPY --from=builder /src/app/build/bcnad /usr/local/bin/bcnad

EXPOSE 26656 26657 1317 9090

ENTRYPOINT ["bcnad"]