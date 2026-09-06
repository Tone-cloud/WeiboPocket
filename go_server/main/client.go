package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"golang.org/x/time/rate"
)

// ==================== 客户端快照 ====================

type clientSnapshot struct {
	sub       string
	subP      string
	subB      string
	ssoLogin  string
	alf       string
	scf       string
	pctoken   string
	mWeiboPID string
	xsrfToken string
	wbPublish string
	cookie    string
	uid       string
	nickname  string
}

var emptyClientSnapshot clientSnapshot

type WeiboClient struct {
	mu           sync.RWMutex
	readLimiter  *rate.Limiter
	writeLimiter *rate.Limiter
	httpClient   *http.Client
	snapshot     atomic.Pointer[clientSnapshot]
}

func (c *WeiboClient) loadSnapshot() *clientSnapshot {
	s := c.snapshot.Load()
	if s == nil {
		return &emptyClientSnapshot
	}
	return s
}

// storeSnapshot 构建并存储新快照（必须在持有写锁时调用）
func (c *WeiboClient) storeSnapshotLocked(cs CookieStore, uid, nickname string) {
	s := &clientSnapshot{
		sub:       cs.Sub,
		subP:      cs.SubP,
		subB:      cs.SubB,
		ssoLogin:  cs.SSOLogin,
		alf:       cs.ALF,
		scf:       cs.SCF,
		pctoken:   cs.PCtoken,
		mWeiboPID: cs.MWeiboPID,
		xsrfToken: cs.XSRFToken,
		wbPublish: cs.WBPublish,
		uid:       uid,
		nickname:  nickname,
	}
	s.cookie = buildCookieStringFromStore(cs)
	c.snapshot.Store(s)
}

func (c *WeiboClient) loadCookieStore(cs CookieStore) {
	c.mu.Lock()
	s := &clientSnapshot{
		sub:       cs.Sub,
		subP:      cs.SubP,
		subB:      cs.SubB,
		ssoLogin:  cs.SSOLogin,
		alf:       cs.ALF,
		scf:       cs.SCF,
		pctoken:   cs.PCtoken,
		mWeiboPID: cs.MWeiboPID,
		xsrfToken: cs.XSRFToken,
		wbPublish: cs.WBPublish,
	}
	s.cookie = buildCookieStringFromStore(cs)
	c.snapshot.Store(s)
	c.mu.Unlock()
}

func (c *WeiboClient) getCookie() string {
	return c.loadSnapshot().cookie
}

func (c *WeiboClient) getUID() string {
	return c.loadSnapshot().uid
}

func (c *WeiboClient) setUID(uid string) {
	c.mu.Lock()
	s := c.loadSnapshot()
	ns := *s
	ns.uid = uid
	c.snapshot.Store(&ns)
	c.mu.Unlock()
}

func (c *WeiboClient) setNickname(nick string) {
	c.mu.Lock()
	s := c.loadSnapshot()
	ns := *s
	ns.nickname = nick
	c.snapshot.Store(&ns)
	c.mu.Unlock()
}

func (c *WeiboClient) isLoggedIn() bool {
	return c.loadSnapshot().sub != ""
}

// UpdateAuth 更新认证信息
func (c *WeiboClient) UpdateAuth(cs CookieStore) {
	c.mu.Lock()
	s := &clientSnapshot{
		sub:       cs.Sub,
		subP:      cs.SubP,
		subB:      cs.SubB,
		ssoLogin:  cs.SSOLogin,
		alf:       cs.ALF,
		scf:       cs.SCF,
		pctoken:   cs.PCtoken,
		mWeiboPID: cs.MWeiboPID,
		xsrfToken: cs.XSRFToken,
		wbPublish: cs.WBPublish,
		uid:       c.loadSnapshot().uid,
		nickname:  c.loadSnapshot().nickname,
	}
	s.cookie = buildCookieStringFromStore(cs)
	c.snapshot.Store(s)
	c.mu.Unlock()

	if err := saveCookies(cs); err != nil {
		logWarn("Cookie 持久化失败: %s", err.Error())
	} else {
		logInfo("已更新并持久化全局 Cookie")
	}
}

// ClearAuth 清理登录状态
func (c *WeiboClient) ClearAuth() {
	c.mu.Lock()
	c.snapshot.Store(&emptyClientSnapshot)
	c.mu.Unlock()

	if err := saveCookies(CookieStore{}); err != nil {
		logWarn("清理 Cookie 持久化失败: %s", err.Error())
	} else {
		logInfo("已清理登录状态并持久化")
	}
}

// ==================== 限速 ====================

func (c *WeiboClient) waitBeforeUpstream(ctx context.Context, method string) error {
	lim := c.readLimiter
	if method != http.MethodGet {
		lim = c.writeLimiter
	}
	return lim.Wait(ctx)
}

// ==================== 构造函数 ====================

func NewWeiboClient() *WeiboClient {
	transport := &http.Transport{
		Proxy: http.ProxyFromEnvironment,
		DialContext: (&net.Dialer{
			Timeout:   8 * time.Second,
			KeepAlive: 30 * time.Second,
		}).DialContext,
		ForceAttemptHTTP2:     true,
		MaxIdleConns:          100,
		MaxIdleConnsPerHost:   16,
		MaxConnsPerHost:       64,
		IdleConnTimeout:       90 * time.Second,
		TLSHandshakeTimeout:   10 * time.Second,
		ExpectContinueTimeout: 1 * time.Second,
		ResponseHeaderTimeout: 15 * time.Second,
	}
	c := &WeiboClient{
		readLimiter:  rate.NewLimiter(rate.Every(50*time.Millisecond), 5),
		writeLimiter: rate.NewLimiter(rate.Every(300*time.Millisecond), 2),
		httpClient: &http.Client{
			Timeout:   20 * time.Second,
			Transport: transport,
		},
	}
	// 发布初始空快照
	c.snapshot.Store(&emptyClientSnapshot)
	return c
}

func (c *WeiboClient) Init() {
	logInfo("初始化 Weibo 客户端...")
	if c.isLoggedIn() {
		logInfo("检测到已登录 Cookie，验证登录状态...")
		uid, nick, err := c.verifyLogin(context.Background())
		if err == nil && uid != "" {
			c.setUID(uid)
			c.setNickname(nick)
			logSuccess("登录验证成功: %s (uid=%s)", nick, uid)
		} else {
			logWarn("登录验证失败: %s", err.Error())
		}
	} else {
		logInfo("未检测到登录 Cookie，以游客模式运行")
	}
	logSuccess("客户端初始化完成")
}

// ==================== 请求头设置 ====================

func (c *WeiboClient) setHeaders(req *http.Request, mobile bool) {
	h := req.Header
	if mobile {
		h.Set("User-Agent", mobileUserAgent)
		h.Set("Referer", "https://m.weibo.cn/")
	} else {
		h.Set("User-Agent", defaultUserAgent)
		h.Set("Referer", defaultReferer)
	}
	h.Set("Accept", "application/json, text/plain, */*")
	h.Set("Accept-Language", "zh-CN,zh;q=0.9,en;q=0.8")
	if cookie := c.getCookie(); cookie != "" {
		h.Set("Cookie", cookie)
	}
	// XSRF Token（如果有）
	if xsrf := c.loadSnapshot().xsrfToken; xsrf != "" {
		h.Set("X-XSRF-TOKEN", xsrf)
	}
}

// ==================== 核心请求方法 ====================

func (c *WeiboClient) doRequest(ctx context.Context, apiURL string, params map[string]string, method string, mobile bool) (json.RawMessage, error) {
	startTime := time.Now()
	query := buildSortedQuery(params)
	fullURL := apiURL
	var bodyReader io.Reader

	switch method {
	case http.MethodGet:
		if query != "" {
			if strings.Contains(fullURL, "?") {
				fullURL += "&" + query
			} else {
				fullURL += "?" + query
			}
		}
	case http.MethodPost:
		bodyReader = strings.NewReader(query)
	default:
		return nil, fmt.Errorf("不支持的请求方法: %s", method)
	}

	req, err := http.NewRequestWithContext(ctx, method, fullURL, bodyReader)
	if err != nil {
		return nil, err
	}
	c.setHeaders(req, mobile)
	if method == http.MethodPost {
		req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	}

	if err := c.waitBeforeUpstream(ctx, method); err != nil {
		return nil, err
	}

	resp, err := c.httpClient.Do(req)
	duration := time.Since(startTime)
	if err != nil {
		logError("API 请求失败 (%dms): %s %s", duration.Milliseconds(), method, apiURL)
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	logDebug("API 响应 %s %s (%dms) status=%d", method, apiURL, duration.Milliseconds(), resp.StatusCode)

	if resp.StatusCode >= 400 {
		logWarn("上游返回错误状态 %d: %s", resp.StatusCode, truncateString(string(body), 300))
	}

	return json.RawMessage(body), nil
}

// webGet Web 端 GET 请求
func (c *WeiboClient) webGet(ctx context.Context, apiURL string, params map[string]string) (json.RawMessage, error) {
	return c.doRequest(ctx, apiURL, params, http.MethodGet, false)
}

// webPost Web 端 POST 请求
func (c *WeiboClient) webPost(ctx context.Context, apiURL string, params map[string]string) (json.RawMessage, error) {
	return c.doRequest(ctx, apiURL, params, http.MethodPost, false)
}

// mobileGet 移动端 GET 请求
func (c *WeiboClient) mobileGet(ctx context.Context, apiURL string, params map[string]string) (json.RawMessage, error) {
	return c.doRequest(ctx, apiURL, params, http.MethodGet, true)
}

// mobilePost 移动端 POST 请求
func (c *WeiboClient) mobilePost(ctx context.Context, apiURL string, params map[string]string) (json.RawMessage, error) {
	return c.doRequest(ctx, apiURL, params, http.MethodPost, true)
}

// rawGet 原始 GET 请求（返回 bytes）
func (c *WeiboClient) rawGet(ctx context.Context, fullURL string, mobile bool) ([]byte, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, fullURL, nil)
	if err != nil {
		return nil, err
	}
	c.setHeaders(req, mobile)

	if err := c.waitBeforeUpstream(ctx, http.MethodGet); err != nil {
		return nil, err
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	return io.ReadAll(resp.Body)
}

// ==================== 登录验证 ====================

func (c *WeiboClient) verifyLogin(ctx context.Context) (uid, nickname string, err error) {
	// 通过获取用户配置来验证登录
	result, err := c.webGet(ctx, weiboAjaxBase+"/profile/info", nil)
	if err != nil {
		return "", "", err
	}

	var resp struct {
		OK   int `json:"ok"`
		Data struct {
			User struct {
				ID       int64  `json:"id"`
				IDStr    string `json:"idstr"`
				NickName string `json:"screen_name"`
			} `json:"user"`
		} `json:"data"`
	}
	if err := json.Unmarshal(result, &resp); err != nil {
		return "", "", fmt.Errorf("解析登录信息失败: %w", err)
	}
	if resp.OK != 1 {
		return "", "", fmt.Errorf("登录状态无效")
	}
	uid = resp.Data.User.IDStr
	if uid == "" {
		uid = fmt.Sprintf("%d", resp.Data.User.ID)
	}
	nickname = resp.Data.User.NickName
	return uid, nickname, nil
}
