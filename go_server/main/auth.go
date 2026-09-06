package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
)

// ==================== Cookie 存储 ====================

// CookieStore 持久化的微博登录态
type CookieStore struct {
	Sub       string `json:"SUB"`
	SubP      string `json:"SUBP"`
	SubB      string `json:"SUHB"`
	SSOLogin  string `json:"SSOLoginState"`
	ALF       string `json:"ALF"`
	SCF       string `json:"SCF"`
	PCtoken   string `json:"_T_WM"`
	MWeiboPID string `json:"M_WEIBOCN_PARAMS"`
	XSRFToken string `json:"XSRF-TOKEN"`
	WBPublish string `json:"wb_publish_v3"`
}

var (
	cookieStorePath string
	cookieStoreMu   sync.Mutex
)

func initCookieStorePath() {
	// 优先使用环境变量指定的路径，否则使用当前目录
	if p := os.Getenv("COOKIE_STORE_PATH"); p != "" {
		cookieStorePath = p
		return
	}
	exePath, err := os.Executable()
	if err == nil {
		cookieStorePath = filepath.Join(filepath.Dir(exePath), cookieStoreFile)
	} else {
		cookieStorePath = cookieStoreFile
	}
}

func loadCookies() (CookieStore, error) {
	cookieStoreMu.Lock()
	defer cookieStoreMu.Unlock()

	if cookieStorePath == "" {
		initCookieStorePath()
	}

	data, err := os.ReadFile(cookieStorePath)
	if err != nil {
		return CookieStore{}, fmt.Errorf("读取 Cookie 文件失败: %w", err)
	}

	var cs CookieStore
	if err := json.Unmarshal(data, &cs); err != nil {
		return CookieStore{}, fmt.Errorf("解析 Cookie 文件失败: %w", err)
	}
	return cs, nil
}

func saveCookies(cs CookieStore) error {
	cookieStoreMu.Lock()
	defer cookieStoreMu.Unlock()

	if cookieStorePath == "" {
		initCookieStorePath()
	}

	data, err := json.MarshalIndent(cs, "", "  ")
	if err != nil {
		return fmt.Errorf("序列化 Cookie 失败: %w", err)
	}

	if err := os.WriteFile(cookieStorePath, data, 0600); err != nil {
		return fmt.Errorf("写入 Cookie 文件失败: %w", err)
	}
	return nil
}

// ==================== 认证辅助 ====================

// buildCookieString 根据 CookieStore 拼接 Cookie 头
func buildCookieStringFromStore(cs CookieStore) string {
	var parts []string
	add := func(name, value string) {
		if value != "" {
			parts = append(parts, name+"="+value)
		}
	}
	add("SUB", cs.Sub)
	add("SUBP", cs.SubP)
	add("SUHB", cs.SubB)
	add("SSOLoginState", cs.SSOLogin)
	add("ALF", cs.ALF)
	add("SCF", cs.SCF)
	add("_T_WM", cs.PCtoken)
	add("M_WEIBOCN_PARAMS", cs.MWeiboPID)
	add("XSRF-TOKEN", cs.XSRFToken)
	add("wb_publish_v3", cs.WBPublish)
	return strings.Join(parts, "; ")
}

// parseCookieString 从 Cookie 头字符串解析为 CookieStore
func parseCookieString(cookieStr string) CookieStore {
	cs := CookieStore{}
	parts := strings.Split(cookieStr, ";")
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		kv := strings.SplitN(part, "=", 2)
		if len(kv) != 2 {
			continue
		}
		key := strings.TrimSpace(kv[0])
		value := strings.TrimSpace(kv[1])
		switch key {
		case "SUB":
			cs.Sub = value
		case "SUBP":
			cs.SubP = value
		case "SUHB":
			cs.SubB = value
		case "SSOLoginState":
			cs.SSOLogin = value
		case "ALF":
			cs.ALF = value
		case "SCF":
			cs.SCF = value
		case "_T_WM":
			cs.PCtoken = value
		case "M_WEIBOCN_PARAMS":
			cs.MWeiboPID = value
		case "XSRF-TOKEN":
			cs.XSRFToken = value
		case "wb_publish_v3":
			cs.WBPublish = value
		}
	}
	return cs
}

// isLoggedIn 检查是否已登录
func (cs CookieStore) isLoggedIn() bool {
	return cs.Sub != ""
}

// getUID 从 SUB cookie 中尝试提取 UID（SUB 格式通常包含 %26 分隔的字段）
func (cs CookieStore) getUID() string {
	if cs.Sub == "" {
		return ""
	}
	// SUB cookie 格式: SUB=_2A25...; 其中可能包含 uid
	// 尝试从 SUBP 中提取
	if cs.SubP != "" {
		// SUBP 格式: 0033WrSXqPxfM72-Ws9jqgMF55529P9D9W...
		// 不直接包含 uid，需要通过 API 获取
	}
	return ""
}
