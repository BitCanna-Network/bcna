ARG IMG_TAG=latest
ARG PLATFORM="linux/amd64"
ARG GO_VERSION="1.24.13"
ARG RUNNER_IMAGE="gcr.io/distroless/static"

FROM --platform=${PLATFORM} golang:${GO_VERSION}-alpine3.20 as builder
WORKDIR /src/app/
COPY go.mod go.sum* ./
RUN go mod download
COPY . .

# From https://github.com/CosmWasm/wasmd/blob/master/Dockerfile
# For more details see https://github.com/CosmWasm/wasmvm#builds-of-libwasmvm
ARG ARCH=x86_64
# See https://github.com/CosmWasm/wasmvm/releases
ADD https://github.com/CosmWasm/wasmvm/releases/download/v2.1.5/libwasmvm_muslc.aarch64.a /lib/libwasmvm_muslc.aarch64.a
ADD https://github.com/CosmWasm/wasmvm/releases/download/v2.1.5/libwasmvm_muslc.x86_64.a /lib/libwasmvm_muslc.x86_64.a
#ADD https://github.com/CosmWasm/wasmvm/releases/download/v2.1.5/libwasmvmstatic_darwin.a /lib/libwasmvm_muslc.darwin.a
RUN sha256sum /lib/libwasmvm_muslc.aarch64.a | grep 1bad0e3f9b72603082b8e48307c7a319df64ca9e26976ffc7a3c317a08fe4b1a
RUN sha256sum /lib/libwasmvm_muslc.x86_64.a | grep c6612d17d82b0997696f1076f6d894e339241482570b9142f29b0d8f21b280bf
#RUN sha256sum /lib/libwasmvm_muslc.darwin.a | grep f7361db078218eb31ebaeab71a6c242034a3709886848596078d132ac7e08e36
RUN cp /lib/libwasmvm_muslc.${ARCH}.a /lib/libwasmvm_muslc.a

ENV PACKAGES curl make git libc-dev bash gcc linux-headers eudev-dev python3
RUN apk add --no-cache $PACKAGES
RUN set -eux; apk add --no-cache ca-certificates build-base;

ARG VERSION=""
RUN BUILD_TAGS=muslc LINK_STATICALLY=true LDFLAGS=-buildid=$VERSION make build

# Add to a distroless container
ARG PLATFORM="linux/amd64"
FROM --platform=${PLATFORM} gcr.io/distroless/cc:$IMG_TAG
ARG IMG_TAG
COPY --from=builder /src/app/build/bcnad /usr/local/bin/bcnad

EXPOSE 26656 26657 1317 9090

ENTRYPOINT ["bcnad"]