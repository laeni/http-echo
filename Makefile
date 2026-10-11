# http-echo 构建文件。
#
# 镜像推送到 ccr.ccs.tencentyun.com/laeni/http-echo，可覆盖下列变量：
#   REGISTRY   镜像仓库前缀，默认 ccr.ccs.tencentyun.com/laeni
#   IMAGE      镜像名，默认 http-echo
#   TAG        镜像标签，默认取 VERSION 文件内容
#   EXTRA_TAGS 追加标签，默认 latest；置空则仅推送 TAG
#   PLATFORMS  推送目标平台，默认 linux/amd64,linux/arm64
#   BUILDER    buildx 构建器名称，默认 multiarch

SHELL := /bin/sh

REGISTRY  ?= ccr.ccs.tencentyun.com/laeni
IMAGE     ?= http-echo
IMG       ?= $(REGISTRY)/$(IMAGE)
# 镜像标签以仓库根目录的 VERSION 文件为唯一来源。
TAG       ?= $(shell cat VERSION 2>/dev/null)
REVISION  ?= $(shell git rev-parse HEAD 2>/dev/null)
EXTRA_TAGS ?= latest

PLATFORMS ?= linux/amd64,linux/arm64
BUILDER   ?= multiarch

# 本机架构，docker-build 据此加载本地镜像。
HOST_ARCH := $(shell uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/')
LOCAL_PLATFORM ?= linux/$(HOST_ARCH)

BUILD_ARGS = --build-arg VERSION=$(TAG) --build-arg REVISION=$(REVISION)
IMAGE_TAGS = -t $(IMG):$(TAG) $(foreach t,$(EXTRA_TAGS),-t $(IMG):$(t))

.DEFAULT_GOAL := help
.PHONY: help build test fmt vet tidy run image-name buildx-setup docker-build docker-push clean

help: ## 显示可用目标
	@awk -F':.*## ' '/^[a-zA-Z0-9_-]+:.*## /{printf "  %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## 编译当前平台二进制到 bin/
	@mkdir -p bin
	go build -trimpath -ldflags "-s -w" -o bin/http-echo .

test: ## 运行测试
	go test ./...

fmt: ## 格式化代码
	go fmt ./...

vet: ## 静态检查
	go vet ./...

tidy: ## 整理依赖
	go mod tidy

run: ## 本地运行，可用 ARGS 传参
	go run . $(ARGS)

image-name: ## 打印本次构建的镜像名
	@echo $(IMG):$(TAG)

buildx-setup: ## 创建缺失的 buildx 构建器
	@docker buildx inspect $(BUILDER) >/dev/null 2>&1 || \
		docker buildx create --name $(BUILDER) --driver docker-container >/dev/null

docker-build: buildx-setup ## 构建本机架构镜像并加载到本地
	docker buildx build --builder $(BUILDER) --platform $(LOCAL_PLATFORM) --load $(BUILD_ARGS) $(IMAGE_TAGS) .

docker-push: buildx-setup ## 构建多架构镜像并推送
	docker buildx build --builder $(BUILDER) --platform $(PLATFORMS) --push $(BUILD_ARGS) $(IMAGE_TAGS) .

clean: ## 清理构建产物
	rm -rf bin
