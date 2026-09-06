package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"runtime/debug"
	"strconv"
	"strings"
	"sync"
	"time"
)

// ==================== HTTP 辅助函数 ====================

func writeJSON(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(statusCode)
	encoder := json.NewEncoder(w)
	encoder.SetEscapeHTML(false)
	encoder.Encode(data)
}

func writeError(w http.ResponseWriter, statusCode int, message string) {
	writeJSON(w, statusCode, map[string]interface{}{
		"code":    -1,
		"message": message,
		"data":    nil,
	})
}

func wrapResult(raw json.RawMessage) map[string]interface{} {
	var result map[string]interface{}
	if err := json.Unmarshal(raw, &result); err != nil {
		start := bytes.IndexByte(raw, '{')
		end := bytes.LastIndexByte(raw, '}')
		if start >= 0 && end > start {
			trimmed := raw[start : end+1]
			if json.Unmarshal(trimmed, &result) == nil {
				raw = trimmed
			} else {
				logWarn("wrapResult JSON 解析失败: %s, raw=%s", err.Error(), truncateString(string(raw), 300))
				return map[string]interface{}{
					"code":    -1,
					"message": "上游返回非 JSON",
					"data":    nil,
				}
			}
		} else {
			logWarn("wrapResult JSON 解析失败: %s, raw=%s", err.Error(), truncateString(string(raw), 300))
			return map[string]interface{}{
				"code":    -1,
				"message": "解析响应失败",
				"data":    nil,
			}
		}
	}

	code := 0
	if c, ok := result["code"].(float64); ok {
		code = int(c)
	}
	message := ""
	if m, ok := result["msg"].(string); ok {
		message = m
	} else if m, ok := result["message"].(string); ok {
		message = m
	}
	var data interface{}
	if d, ok := result["data"]; ok {
		data = d
	}

	return map[string]interface{}{
		"code":    code,
		"message": message,
		"data":    data,
	}
}

func intParam(val string, min int, defaultVal int, hasMin bool) (int, error) {
	if val == "" {
		return defaultVal, nil
	}
	n, err := strconv.Atoi(val)
	if err != nil {
		return 0, fmt.Errorf("参数必须为整数，收到: %s", val)
	}
	if hasMin && n < min {
		return 0, fmt.Errorf("参数不得小于 %d，收到: %d", min, n)
	}
	return n, nil
}

func getIntQuery(w http.ResponseWriter, q url.Values, name string, min, def int, hasMin bool) (int, bool) {
	n, err := intParam(q.Get(name), min, def, hasMin)
	if err != nil {
		writeError(w, 400, err.Error())
		return 0, false
	}
	return n, true
}

func requireQuery(w http.ResponseWriter, q url.Values, name string) (string, bool) {
	v := strings.TrimSpace(q.Get(name))
	if v == "" {
		logWarn("%s 缺失", name)
		writeError(w, 400, name+" 为必填参数")
		return "", false
	}
	return v, true
}

func getPageParams(w http.ResponseWriter, q url.Values, defaultPS int) (pn, ps int, ok bool) {
	pn, ok = getIntQuery(w, q, "page", 1, 1, true)
	if !ok {
		return 0, 0, false
	}
	ps, ok = getIntQuery(w, q, "count", 1, defaultPS, true)
	if !ok {
		return 0, 0, false
	}
	return pn, ps, true
}

func writeJSONBytes(w http.ResponseWriter, statusCode int, data []byte) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(statusCode)
	_, _ = w.Write(data)
}

func handleAPI(w http.ResponseWriter, action string, call func(*WeiboClient) (json.RawMessage, error)) {
	result, err := call(getClient())
	if err != nil {
		logError("处理 %s 请求失败: %s", action, err.Error())
		writeError(w, 500, err.Error())
		return
	}

	trimmed := bytes.TrimSpace(result)
	if len(trimmed) > 0 && trimmed[0] == '{' && trimmed[len(trimmed)-1] == '}' && json.Valid(trimmed) {
		writeJSONBytes(w, 200, trimmed)
		return
	}

	writeJSON(w, 200, wrapResult(result))
}

// ==================== 全局客户端 ====================

var globalClient *WeiboClient

func getClient() *WeiboClient {
	return globalClient
}

// ==================== 日志中间件 ====================

type loggingResponseWriter struct {
	http.ResponseWriter
	statusCode  int
	bodyHead    []byte
	headBudget  int
	wroteHeader bool
}

func (lrw *loggingResponseWriter) Write(b []byte) (int, error) {
	if !lrw.wroteHeader {
		lrw.wroteHeader = true
	}
	if lrw.headBudget > 0 {
		n := lrw.headBudget
		if n > len(b) {
			n = len(b)
		}
		lrw.bodyHead = append(lrw.bodyHead, b[:n]...)
		lrw.headBudget -= n
	}
	return lrw.ResponseWriter.Write(b)
}

func (lrw *loggingResponseWriter) WriteHeader(code int) {
	if lrw.wroteHeader {
		return
	}
	lrw.wroteHeader = true
	lrw.statusCode = code
	lrw.ResponseWriter.WriteHeader(code)
}

func (lrw *loggingResponseWriter) Flush() {
	if f, ok := lrw.ResponseWriter.(http.Flusher); ok {
		f.Flush()
	}
}

func (lrw *loggingResponseWriter) Unwrap() http.ResponseWriter {
	return lrw.ResponseWriter
}

const loggingHeadBudget = 512

var loggingRWPool = sync.Pool{
	New: func() any {
		return &loggingResponseWriter{
			bodyHead: make([]byte, 0, loggingHeadBudget),
		}
	},
}

func extractResponseCodeFromHead(body []byte) int {
	if len(body) == 0 {
		return -1
	}
	var resp struct {
		Code int `json:"code"`
	}
	if err := json.Unmarshal(body, &resp); err != nil {
		return -1
	}
	return resp.Code
}

func isJSONContentType(contentType string) bool {
	return strings.Contains(contentType, "application/json")
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		startTime := time.Now()

		if accessLogEnabled {
			params := make(map[string]string)
			for k, v := range r.URL.Query() {
				if len(v) > 0 {
					params[k] = v[0]
				}
			}
			logRequest(r.Method, r.URL.Path, params)
		}

		lrw := loggingRWPool.Get().(*loggingResponseWriter)
		lrw.ResponseWriter = w
		lrw.statusCode = 200
		lrw.bodyHead = lrw.bodyHead[:0]
		lrw.headBudget = loggingHeadBudget
		lrw.wroteHeader = false

		next.ServeHTTP(lrw, r)

		duration := time.Since(startTime)
		code := extractResponseCodeFromHead(lrw.bodyHead)
		statusCode := lrw.statusCode
		contentType := lrw.Header().Get("Content-Type")
		if code == -1 && statusCode >= 200 && statusCode < 300 && !isJSONContentType(contentType) {
			code = 0
		}

		lrw.ResponseWriter = nil
		loggingRWPool.Put(lrw)

		logResponse(r.URL.Path, code, duration)
	})
}

func recoverMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if rec := recover(); rec != nil {
				if rec == http.ErrAbortHandler {
					panic(rec)
				}
				stack := debug.Stack()
				logError("处理请求时 panic: %s %s err=%v\n%s", r.Method, r.URL.Path, rec, string(stack))
				defer func() { _ = recover() }()
				writeError(w, http.StatusInternalServerError, "internal server error")
			}
		}()
		next.ServeHTTP(w, r)
	})
}
