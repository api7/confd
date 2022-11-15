ARG TARGETOS
ARG TARGETARCH
ARG VERSION
ARG PLATFORM=amd64
ARG ENABLE_PROXY=false

FROM --platform=$PLATFORM golang:1.19 as builder

RUN apk add --no-cache --virtual .builddeps git

WORKDIR /confd

COPY . .

RUN GIT_SHA=`git rev-parse --short HEAD || echo`
RUN if [ "$ENABLE_PROXY" = "true" ] ; then go env -w GOPROXY=https://goproxy.io,direct ; fi \
    && go env -w GO111MODULE=on \
    && CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH}  \
    go build -ldflags "-X main.GitSHA=${GIT_SHA} -X main.Version=${VERSION}" -o confd .

FROM debian:latest as prod

COPY --from=builder /confd/confd /usr/local/bin/confd

EXPOSE 9000

CMD ["/usr/local/bin/confd"]
