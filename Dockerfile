# syntax=docker/dockerfile:1

# 构建阶段：编译静态链接的 http-echo 二进制。
FROM golang:1.26-alpine AS builder

WORKDIR /src

# 依赖清单单独复制，依赖未变更时复用缓存层。
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# TARGETOS、TARGETARCH 由 buildx 按目标平台注入。
ARG TARGETOS
ARG TARGETARCH
RUN CGO_ENABLED=0 GOOS="${TARGETOS:-linux}" GOARCH="${TARGETARCH}" \
    go build -trimpath -ldflags "-s -w" -o /out/http-echo .

# 运行阶段
FROM alpine:3.22

ARG VERSION=dev
ARG REVISION=
LABEL org.opencontainers.image.title="http-echo" \
      org.opencontainers.image.description="打印所有 HTTP 请求和响应的调试服务" \
      org.opencontainers.image.source="https://github.com/laeni/http-echo" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.licenses="MIT"

COPY --from=builder /out/http-echo /usr/local/bin/http-echo

USER 65534:65534
EXPOSE 8080

ENTRYPOINT ["http-echo"]
