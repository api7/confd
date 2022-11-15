ARG TARGETOS
ARG TARGETARCH
ARG BUILDPLATFORM=amd64
ARG ENABLE_PROXY=false

FROM --platform=$BUILDPLATFORM golang:1.19 as builder

RUN apt-get update && apt-get install -y --no-install-recommends git

WORKDIR /confd

COPY . .

RUN if [ "$ENABLE_PROXY" = "true" ] ; then go env -w GOPROXY=https://goproxy.io,direct ; fi \
    && go env -w GO111MODULE=on \
    && GIT_SHA=`git rev-parse --short HEAD || echo` \
    && CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w -X main.GitSHA=${GIT_SHA}" -o confd .

FROM debian:latest as prod

COPY --from=builder /confd/confd /usr/local/bin/confd

RUN  apt-get update && apt-get install -y --no-install-recommends curl net-tools telnet procps

EXPOSE 9000

CMD ["/usr/local/bin/confd"]
