# http-echo

打印所有 HTTP 请求和响应的调试服务。

收到请求后，将请求方法、路径、请求头、请求体，以及响应状态码、响应头、响应体输出到标准输出，同时将请求体原样回显作为响应。支持通过命令行选项控制各部分的打印。

## 安装

```bash
go build -o http-echo .
```

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
