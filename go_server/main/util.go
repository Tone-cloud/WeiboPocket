package main

import (
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"
)

// ==================== 工具函数 ====================

// buildSortedQuery 将参数 map 转为排序后的 query string
func buildSortedQuery(params map[string]string) string {
	if len(params) == 0 {
		return ""
	}
	keys := make([]string, 0, len(params))
	for k := range params {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	var parts []string
	for _, k := range keys {
		v := params[k]
		if v == "" {
			continue
		}
		parts = append(parts, url.QueryEscape(k)+"="+url.QueryEscape(v))
	}
	return strings.Join(parts, "&")
}

// int64ToString 安全转换
func int64ToString(v int64) string {
	return strconv.FormatInt(v, 10)
}

// stringToInt64 安全转换
func stringToInt64(s string) int64 {
	v, err := strconv.ParseInt(s, 10, 64)
	if err != nil {
		return 0
	}
	return v
}

// formatTime 格式化时间戳
func formatTime(ts int64) string {
	if ts <= 0 {
		return ""
	}
	t := time.Unix(ts, 0)
	return t.Format("2006-01-02 15:04:05")
}

// relativeTime 相对时间
func relativeTime(ts int64) string {
	if ts <= 0 {
		return ""
	}
	now := time.Now().Unix()
	diff := now - ts
	if diff < 60 {
		return "刚刚"
	}
	if diff < 3600 {
		return fmt.Sprintf("%d分钟前", diff/60)
	}
	if diff < 86400 {
		return fmt.Sprintf("%d小时前", diff/3600)
	}
	if diff < 86400*7 {
		return fmt.Sprintf("%d天前", diff/86400)
	}
	return formatTime(ts)
}

// md5Hash 计算 MD5
func md5Hash(s string) string {
	h := md5.New()
	h.Write([]byte(s))
	return hex.EncodeToString(h.Sum(nil))
}

// extractJSONField 从 JSON 中安全提取字段
func extractJSONField(data map[string]interface{}, key string) interface{} {
	if v, ok := data[key]; ok {
		return v
	}
	return nil
}

// getStringField 安全获取字符串字段
func getStringField(data map[string]interface{}, key string) string {
	if v, ok := data[key]; ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return ""
}

// getIntField 安全获取整数字段
func getIntField(data map[string]interface{}, key string) int {
	if v, ok := data[key]; ok {
		switch n := v.(type) {
		case float64:
			return int(n)
		case int:
			return n
		case json.Number:
			i, _ := n.Int64()
			return int(i)
		}
	}
	return 0
}

// getInt64Field 安全获取 int64 字段
func getInt64Field(data map[string]interface{}, key string) int64 {
	if v, ok := data[key]; ok {
		switch n := v.(type) {
		case float64:
			return int64(n)
		case int64:
			return n
		case int:
			return int64(n)
		case json.Number:
			i, _ := n.Int64()
			return i
		}
	}
	return 0
}

// getBoolField 安全获取布尔字段
func getBoolField(data map[string]interface{}, key string) bool {
	if v, ok := data[key]; ok {
		if b, ok := v.(bool); ok {
			return b
		}
	}
	return false
}

// getMapField 安全获取 map 字段
func getMapField(data map[string]interface{}, key string) map[string]interface{} {
	if v, ok := data[key]; ok {
		if m, ok := v.(map[string]interface{}); ok {
			return m
		}
	}
	return nil
}

// getArrayField 安全获取数组字段
func getArrayField(data map[string]interface{}, key string) []interface{} {
	if v, ok := data[key]; ok {
		if a, ok := v.([]interface{}); ok {
			return a
		}
	}
	return nil
}

// truncateText 截断文本
func truncateText(s string, maxLen int) string {
	runes := []rune(s)
	if len(runes) <= maxLen {
		return s
	}
	return string(runes[:maxLen]) + "..."
}

// stripHTML 简单去除 HTML 标签
func stripHTML(s string) string {
	result := s
	// 去除 <br> 等
	result = strings.ReplaceAll(result, "<br>", "\n")
	result = strings.ReplaceAll(result, "<br/>", "\n")
	result = strings.ReplaceAll(result, "<br />", "\n")
	// 简单去除其他标签
	for {
		start := strings.Index(result, "<")
		if start < 0 {
			break
		}
		end := strings.Index(result[start:], ">")
		if end < 0 {
			break
		}
		result = result[:start] + result[start+end+1:]
	}
	return strings.TrimSpace(result)
}
