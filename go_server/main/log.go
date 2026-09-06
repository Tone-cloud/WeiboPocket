package main

import (
	"fmt"
	"os"
	"sync"
	"time"
)

// ==================== 日志系统 ====================

var (
	debugEnabled      = os.Getenv("DEBUG") == "true"
	accessLogEnabled  = true
	asyncLogQueue     = make(chan logEntry, 4096)
	asyncLogShutdown  = make(chan struct{})
	asyncLogWaitGroup sync.WaitGroup
)

const asyncLogShutdownTimeout = 2 * time.Second

type logEntry struct {
	level   string
	message string
}

func init() {
	asyncLogWaitGroup.Add(1)
	go asyncLogWorker()
}

func asyncLogWorker() {
	defer asyncLogWaitGroup.Done()
	for {
		select {
		case entry := <-asyncLogQueue:
			writeLog(entry.level, entry.message)
		case <-asyncLogShutdown:
			// 排空队列
			for {
				select {
				case entry := <-asyncLogQueue:
					writeLog(entry.level, entry.message)
				default:
					return
				}
			}
		}
	}
}

func asyncLogFlush(timeout time.Duration) error {
	close(asyncLogShutdown)
	done := make(chan struct{})
	go func() {
		asyncLogWaitGroup.Wait()
		close(done)
	}()
	select {
	case <-done:
		return nil
	case <-time.After(timeout):
		return fmt.Errorf("日志刷新超时")
	}
}

func writeLog(level, message string) {
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	fmt.Printf("[%s] [%s] %s\n", timestamp, level, message)
}

func enqueueLog(level, format string, args ...interface{}) {
	msg := fmt.Sprintf(format, args...)
	select {
	case asyncLogQueue <- logEntry{level: level, message: msg}:
	default:
		// 队列满时直接写，避免丢失
		writeLog(level, msg)
	}
}

func logInfo(format string, args ...interface{}) {
	enqueueLog("INFO", format, args...)
}

func logWarn(format string, args ...interface{}) {
	enqueueLog("WARN", format, args...)
}

func logError(format string, args ...interface{}) {
	enqueueLog("ERROR", format, args...)
}

func logSuccess(format string, args ...interface{}) {
	enqueueLog("SUCCESS", format, args...)
}

func logDebug(format string, args ...interface{}) {
	if debugEnabled {
		enqueueLog("DEBUG", format, args...)
	}
}

func logPlain(format string, args ...interface{}) {
	fmt.Printf(format+"\n", args...)
}

func logRequest(method, path string, params map[string]string) {
	if !accessLogEnabled {
		return
	}
	paramStr := ""
	for k, v := range params {
		if paramStr != "" {
			paramStr += "&"
		}
		paramStr += k + "=" + v
	}
	if paramStr != "" {
		logDebug("请求 %s %s?%s", method, path, paramStr)
	} else {
		logDebug("请求 %s %s", method, path)
	}
}

func logResponse(path string, code int, duration time.Duration) {
	if !accessLogEnabled {
		return
	}
	if code == 0 {
		logDebug("响应 %s 成功 (%dms)", path, duration.Milliseconds())
	} else {
		logWarn("响应 %s 业务错误 code=%d (%dms)", path, code, duration.Milliseconds())
	}
}

func logUpstreamBusinessError(apiURL string, body []byte) {
	if !debugEnabled {
		return
	}
	// 简单检测上游业务错误
	if len(body) > 0 && body[0] == '{' {
		// 不做完整解析，只在 debug 模式记录
		logDebug("上游响应 %s: %s", apiURL, truncateString(string(body), 500))
	}
}

func truncateString(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen] + "..."
}
