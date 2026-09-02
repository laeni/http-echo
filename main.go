package main

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/spf13/cobra"
)

const boundary = "========================================"

var (
	addr         string
	printMethod  bool
	printHeaders bool
	printBody    bool
	maxBodySize  int
)

// responseCapture wraps http.ResponseWriter to capture the status code and response body.
type responseCapture struct {
	http.ResponseWriter
	statusCode    int
	body          bytes.Buffer
	headerWritten bool
}

func (rc *responseCapture) WriteHeader(code int) {
	if !rc.headerWritten {
		rc.statusCode = code
		rc.headerWritten = true
	}
	rc.ResponseWriter.WriteHeader(code)
}

func (rc *responseCapture) Write(b []byte) (int, error) {
	if !rc.headerWritten {
		rc.statusCode = http.StatusOK
		rc.headerWritten = true
	}
	rc.body.Write(b)
	return rc.ResponseWriter.Write(b)
}

func main() {
	rootCmd := &cobra.Command{
		Use:   "http-echo",
		Short: "打印所有 HTTP 请求和响应",
		RunE: func(cmd *cobra.Command, args []string) error {
			mux := http.NewServeMux()
			mux.HandleFunc("/", handle)

			log.Printf("http-echo listening on %s", addr)
			return http.ListenAndServe(addr, mux)
		},
		SilenceUsage: true,
	}

	rootCmd.Flags().StringVar(&addr, "addr", ":8080", "监听地址")
	rootCmd.Flags().BoolVar(&printMethod, "method", true, "打印请求方法和路径")
	rootCmd.Flags().BoolVar(&printHeaders, "headers", true, "打印请求头和响应头")
	rootCmd.Flags().BoolVar(&printBody, "body", true, "打印请求体和响应体")
	rootCmd.Flags().IntVar(&maxBodySize, "max-body", 4096, "打印 Body 的最大字节数，0 表示不限制")

	if err := rootCmd.Execute(); err != nil {
		log.Fatal(err)
	}
}

func handle(w http.ResponseWriter, r *http.Request) {
	// Read and restore the request body so it remains available downstream.
	var reqBody []byte
	if r.Body != nil {
		reqBody, _ = io.ReadAll(r.Body)
		r.Body.Close()
		r.Body = io.NopCloser(bytes.NewReader(reqBody))
	}

	// Wrap the response writer to capture status code and response body.
	rc := &responseCapture{ResponseWriter: w, statusCode: http.StatusOK}

	// Echo: return the request body, preserving the original content type.
	if ct := r.Header.Get("Content-Type"); ct != "" {
		rc.Header().Set("Content-Type", ct)
	}
	rc.WriteHeader(http.StatusOK)
	rc.Write(reqBody)

	// Print the request and response details.
	var sb strings.Builder
	sb.WriteString("\n" + boundary + "\n")
	sb.WriteString(time.Now().Format("2006-01-02 15:04:05") + "\n")

	if printMethod {
		fmt.Fprintf(&sb, "[REQUEST] %s %s %s\n", r.Method, r.URL.RequestURI(), r.Proto)
	}
	if printHeaders {
		sb.WriteString("\nRequest Headers:\n")
		writeHeaders(&sb, r.Header)
	}
	if printBody {
		sb.WriteString("\nRequest Body:\n")
		sb.WriteString(formatBody(reqBody, maxBodySize))
		sb.WriteString("\n")
	}

	sb.WriteString("----------------------------------------\n")

	if printMethod {
		fmt.Fprintf(&sb, "[RESPONSE] %d %s\n", rc.statusCode, http.StatusText(rc.statusCode))
	}
	if printHeaders {
		sb.WriteString("\nResponse Headers:\n")
		writeHeaders(&sb, rc.Header())
	}
	if printBody {
		sb.WriteString("\nResponse Body:\n")
		sb.WriteString(formatBody(rc.body.Bytes(), maxBodySize))
		sb.WriteString("\n")
	}

	sb.WriteString(boundary + "\n")

	fmt.Print(sb.String())
}

func writeHeaders(sb *strings.Builder, h http.Header) {
	for k, vs := range h {
		for _, v := range vs {
			fmt.Fprintf(sb, "  %s: %s\n", k, v)
		}
	}
}

func formatBody(data []byte, maxLen int) string {
	if len(data) == 0 {
		return "(empty)"
	}
	s := string(data)
	if maxLen > 0 && len(s) > maxLen {
		return s[:maxLen] + fmt.Sprintf("\n... (%d bytes total, truncated)", len(data))
	}
	return s
}
