FROM --platform=${BUILDPLATFORM} golang:1.19 as builder

WORKDIR /confd

COPY . .

ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG ENABLE_PROXY=false

RUN apt-get update && apt-get install -y --no-install-recommends git

RUN if [ "$ENABLE_PROXY" = "true" ] ; then go env -w GOPROXY=https://goproxy.io,direct ; fi \
    && go env -w GO111MODULE=on

# Set the cross compilation arguments based on the TARGETPLATFORM which is
#  automatically set by the docker engine.
RUN case ${TARGETPLATFORM} in \
        "linux/amd64")  GOARCH=amd64  ;; \
        # arm64 and arm64v8 are equivilant in go and do not require a goarm
        # https://github.com/golang/go/wiki/GoArm
        "linux/arm64" | "linux/arm/v8")  GOARCH=arm64  ;; \
        "linux/ppc64le")  GOARCH=ppc64le  ;; \
        "linux/arm/v6") GOARCH=arm GOARM=6  ;; \
    esac \
    && printf "Building for arch ${GOARCH}\n" \
    && GIT_SHA=`git rev-parse --short HEAD || echo` \
    && GOARCH=${GOARCH} CGO_ENABLED=0 go build -ldflags="-s -w -X main.GitSHA=${GIT_SHA}" -o confd .

FROM debian:latest as prod

COPY --from=builder /confd/confd /usr/local/bin/confd

RUN  apt-get update && apt-get install -y --no-install-recommends curl net-tools telnet procps

EXPOSE 9000

CMD ["/usr/local/bin/confd"]
