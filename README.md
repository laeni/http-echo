# http-echo

打印所有 HTTP 请求和响应的调试服务。

收到请求后，将请求方法、路径、请求头、请求体，以及响应状态码、响应头、响应体输出到标准输出，同时将请求体原样回显作为响应。支持通过命令行选项控制各部分的打印。

## 安装

```bash
make build
```

产物为 `bin/http-echo`。`make help` 列出全部目标，常用的还有 `make test`、`make vet`、`make fmt`。

## 镜像

镜像推送到 `ccr.ccs.tencentyun.com/laeni/http-echo`。

```bash
make docker-build   # 构建本机架构镜像并加载到本地 Docker
make docker-push    # 构建 linux/amd64、linux/arm64 镜像并推送
```

推送使用 buildx，构建器不存在时自动创建。镜像标签取自仓库根目录的 `VERSION` 文件，另附 `latest` 标签。

| 变量 | 默认值 | 说明 |
|---|---|---|
| `REGISTRY` | `ccr.ccs.tencentyun.com/laeni` | 镜像仓库前缀 |
| `IMAGE` | `http-echo` | 镜像名 |
| `TAG` | `VERSION` 文件内容 | 镜像标签 |
| `EXTRA_TAGS` | `latest` | 追加标签，置空则仅推送 `TAG` |
| `PLATFORMS` | `linux/amd64,linux/arm64` | 推送目标平台 |
| `BUILDER` | `multiarch` | buildx 构建器名称 |

```bash
make docker-push TAG=v1.2.0
make docker-push IMG=harbor.example.com/library/http-echo TAG=dev EXTRA_TAGS=
```

运行镜像：

```bash
docker run --rm -p 8080:8080 ccr.ccs.tencentyun.com/laeni/http-echo:latest
```

或以 `docker-compose.yaml` 启动：

```bash
docker compose up -d
docker compose logs -f
```

`docker-compose.yaml` 中的镜像名、标签和端口分别由 `REGISTRY`、`TAG`、`PORT` 环境变量控制，镜像更新后执行 `docker compose pull && docker compose up -d`。

## 用法

```bash
http-echo [flags]
```

### 选项

| Flag | 默认值 | 说明 |
|---|---|---|
| `--addr` | `:8080` | 监听地址 |
| `--method` | `true` | 打印请求方法和路径 |
| `--headers` | `true` | 打印请求头和响应头 |
| `--body` | `true` | 打印请求体和响应体 |
| `--max-body` | `4096` | 打印 Body 的最大字节数，`0` 不限制 |
| `-h, --help` | — | 显示帮助 |

### 示例

全量打印（默认）：

```bash
http-echo --addr=:8080
```

只打印请求方法和路径：

```bash
http-echo --headers=false --body=false
```

不打印 Body：

```bash
http-echo --body=false
```

不限制 Body 打印长度：

```bash
http-echo --max-body=0
```

### 输出示例

```bash
curl -X POST 'http://localhost:8080/api/test?foo=bar' \
  -H "Content-Type: application/json" \
  -H "X-Custom-Header: hello" \
  -d '{"message":"world"}'
```

输出：

```
========================================
2026-09-02 20:19:48
[REQUEST] POST /api/test?foo=bar HTTP/1.1

Request Headers:
  Content-Type: application/json
  X-Custom-Header: hello
  Content-Length: 19
  User-Agent: curl/8.7.1
  Accept: */*

Request Body:
{"message":"world"}
----------------------------------------
[RESPONSE] 200 OK

Response Headers:
  Content-Type: application/json

Response Body:
{"message":"world"}
========================================
```

## 许可证

[MIT](LICENSE)
