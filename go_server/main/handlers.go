package main

import (
	"encoding/json"
	"io"
	"net/http"
	"net/url"
)

// ==================== 路由处理函数 ====================

func handleRoot(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		writeJSON(w, 404, map[string]interface{}{
			"code":    -404,
			"message": "接口不存在",
			"data":    nil,
		})
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code":    0,
		"message": "Weibo API Server 运行中",
		"data": map[string]interface{}{
			"version":   "1.0.0",
			"endpoints": rootEndpoints,
		},
	})
}

// ==================== 热搜 ====================

func handleHotSearch(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	limit, _ := getIntQuery(w, q, "limit", 1, 50, true)
	items, err := getClient().GetHotSearch(r.Context(), limit)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": map[string]interface{}{
			"list":  items,
			"total": len(items),
		},
	})
}

func handleHotSearchCategories(w http.ResponseWriter, r *http.Request) {
	categories, err := getClient().GetHotSearchCategories(r.Context())
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": categories,
	})
}

// ==================== 微博详情 ====================

func handleStatusShow(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	id, ok := requireQuery(w, q, "id")
	if !ok {
		return
	}
	status, err := getClient().GetStatusShow(r.Context(), id)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": status,
	})
}

func handleStatusLikeToggle(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	id, ok := requireQuery(w, q, "id")
	if !ok {
		return
	}
	likeVal, _ := getIntQuery(w, q, "like", 0, 1, true)
	like := likeVal == 1
	result, err := getClient().ToggleStatusLike(r.Context(), id, like)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": map[string]interface{}{
			"liked": result,
		},
	})
}

// ==================== 评论 ====================

func handleStatusComments(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	id, ok := requireQuery(w, q, "id")
	if !ok {
		return
	}
	page, _ := getIntQuery(w, q, "page", 1, 1, true)
	count, _ := getIntQuery(w, q, "count", 1, 20, true)
	comments, total, err := getClient().GetStatusComments(r.Context(), id, page, count)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": map[string]interface{}{
			"list":  comments,
			"total": total,
			"page":  page,
			"count": count,
		},
	})
}

func handleCommentReplies(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	statusID, ok := requireQuery(w, q, "status_id")
	if !ok {
		return
	}
	commentID, ok := requireQuery(w, q, "comment_id")
	if !ok {
		return
	}
	page, _ := getIntQuery(w, q, "page", 1, 1, true)
	count, _ := getIntQuery(w, q, "count", 1, 20, true)
	replies, total, err := getClient().GetCommentReplies(r.Context(), statusID, commentID, page, count)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": map[string]interface{}{
			"list":  replies,
			"total": total,
		},
	})
}

func handleCommentLikeToggle(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	id, ok := requireQuery(w, q, "id")
	if !ok {
		return
	}
	likeVal, _ := getIntQuery(w, q, "like", 0, 1, true)
	like := likeVal == 1
	result, err := getClient().ToggleCommentLike(r.Context(), id, like)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": map[string]interface{}{
			"liked": result,
		},
	})
}

// ==================== 超话 ====================

func handleSuperTopicList(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	page, _ := getIntQuery(w, q, "page", 1, 1, true)
	topics, total, err := getClient().GetSuperTopicList(r.Context(), page)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": map[string]interface{}{
			"list":  topics,
			"total": total,
		},
	})
}

func handleSuperTopicCheckin(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	topicID, ok := requireQuery(w, q, "topic_id")
	if !ok {
		return
	}
	result, err := getClient().SuperTopicCheckin(r.Context(), topicID)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": result,
	})
}

func handleSuperTopicCheckinStatus(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	topicID, ok := requireQuery(w, q, "topic_id")
	if !ok {
		return
	}
	result, err := getClient().GetSuperTopicCheckinStatus(r.Context(), topicID)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": result,
	})
}

func handleSuperTopicBatchCheckin(w http.ResponseWriter, r *http.Request) {
	results, err := getClient().BatchCheckin(r.Context())
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": map[string]interface{}{
			"results": results,
			"total":   len(results),
		},
	})
}

// ==================== 视频 ====================

func handleVideoInfo(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	statusID, ok := requireQuery(w, q, "status_id")
	if !ok {
		return
	}
	video, err := getClient().GetVideoInfo(r.Context(), statusID)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": video,
	})
}

func handleVideoPlayURL(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	statusID, ok := requireQuery(w, q, "status_id")
	if !ok {
		return
	}
	quality := q.Get("quality")
	if quality == "" {
		quality = "sd"
	}
	result, err := getClient().GetVideoPlayURL(r.Context(), statusID, quality)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": result,
	})
}

// ==================== 搜索 ====================

func handleSearchType(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	keyword, ok := requireQuery(w, q, "q")
	if !ok {
		return
	}
	searchType := q.Get("type")
	if searchType == "" {
		searchType = "status"
	}
	page, _ := getIntQuery(w, q, "page", 1, 1, true)
	result, err := getClient().SearchType(r.Context(), keyword, searchType, page)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": result,
	})
}

func handleSearchStatus(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	keyword, ok := requireQuery(w, q, "q")
	if !ok {
		return
	}
	page, _ := getIntQuery(w, q, "page", 1, 1, true)
	statuses, total, err := getClient().SearchStatus(r.Context(), keyword, page)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": map[string]interface{}{
			"list":  statuses,
			"total": total,
		},
	})
}

func handleSearchUser(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	keyword, ok := requireQuery(w, q, "q")
	if !ok {
		return
	}
	page, _ := getIntQuery(w, q, "page", 1, 1, true)
	users, total, err := getClient().SearchUser(r.Context(), keyword, page)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": map[string]interface{}{
			"list":  users,
			"total": total,
		},
	})
}

// ==================== 用户 ====================

func handleUserInfo(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	uid, ok := requireQuery(w, q, "uid")
	if !ok {
		return
	}
	user, err := getClient().GetUserInfo(r.Context(), uid)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": user,
	})
}

func handleUserStatuses(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	uid, ok := requireQuery(w, q, "uid")
	if !ok {
		return
	}
	page, _ := getIntQuery(w, q, "page", 1, 1, true)
	statuses, total, err := getClient().GetUserStatuses(r.Context(), uid, page)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": map[string]interface{}{
			"list":  statuses,
			"total": total,
		},
	})
}

func handleUserFollowers(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	uid, ok := requireQuery(w, q, "uid")
	if !ok {
		return
	}
	page, _ := getIntQuery(w, q, "page", 1, 1, true)
	users, total, err := getClient().GetUserFollowers(r.Context(), uid, page)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": map[string]interface{}{
			"list":  users,
			"total": total,
		},
	})
}

func handleUserFriends(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	uid, ok := requireQuery(w, q, "uid")
	if !ok {
		return
	}
	page, _ := getIntQuery(w, q, "page", 1, 1, true)
	users, total, err := getClient().GetUserFriends(r.Context(), uid, page)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": map[string]interface{}{
			"list":  users,
			"total": total,
		},
	})
}

func handleUserFollowToggle(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	uid, ok := requireQuery(w, q, "uid")
	if !ok {
		return
	}
	followVal, _ := getIntQuery(w, q, "follow", 0, 1, true)
	follow := followVal == 1
	result, err := getClient().ToggleFollow(r.Context(), uid, follow)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": map[string]interface{}{
			"following": result,
		},
	})
}

// ==================== 登录 ====================

func handleLoginInfo(w http.ResponseWriter, r *http.Request) {
	result, err := getClient().GetLoginInfo(r.Context())
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": result,
	})
}

func handleLoginImport(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]interface{}{
			"code":    405,
			"message": "method not allowed",
			"data":    nil,
		})
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		writeError(w, 400, "读取请求体失败")
		return
	}

	// 支持三种格式：form-encoded、JSON 对象、原始 Cookie 字符串
	var cs CookieStore
	cookieStr := string(body)

	// 1. 尝试解析为 form-encoded
	if form, err := url.ParseQuery(string(body)); err == nil {
		if formCookie := form.Get("cookie"); formCookie != "" {
			cs = parseCookieString(formCookie)
		} else if form.Get("SUB") != "" {
			cs = CookieStore{
				Sub:       form.Get("SUB"),
				SubP:      form.Get("SUBP"),
				SubB:      form.Get("SUHB"),
				SSOLogin:  form.Get("SSOLoginState"),
				ALF:       form.Get("ALF"),
				SCF:       form.Get("SCF"),
				PCtoken:   form.Get("_T_WM"),
				MWeiboPID: form.Get("M_WEIBOCN_PARAMS"),
				XSRFToken: form.Get("XSRF-TOKEN"),
				WBPublish: form.Get("wb_publish_v3"),
			}
		}
	}

	// 2. 如果 form 解析失败或没有 cookie 字段，尝试 JSON
	if cs.Sub == "" {
		var payload map[string]string
		if json.Unmarshal(body, &payload) == nil {
			cs = CookieStore{
				Sub:       payload["SUB"],
				SubP:      payload["SUBP"],
				SubB:      payload["SUHB"],
				SSOLogin:  payload["SSOLoginState"],
				ALF:       payload["ALF"],
				SCF:       payload["SCF"],
				PCtoken:   payload["_T_WM"],
				MWeiboPID: payload["M_WEIBOCN_PARAMS"],
				XSRFToken: payload["XSRF-TOKEN"],
				WBPublish: payload["wb_publish_v3"],
			}
		}
	}

	// 3. 如果都失败，作为原始 Cookie 字符串解析
	if cs.Sub == "" && cookieStr != "" {
		cs = parseCookieString(cookieStr)
	}

	if cs.Sub == "" {
		writeError(w, 400, "SUB cookie 不能为空")
		return
	}

	globalClient.UpdateAuth(cs)

	// 验证登录
	uid, nick, err := globalClient.verifyLogin(r.Context())
	if err == nil && uid != "" {
		globalClient.setUID(uid)
		globalClient.setNickname(nick)
	}

	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": map[string]interface{}{
			"sub":       cs.Sub != "",
			"uid":       globalClient.getUID(),
			"nickname":  globalClient.loadSnapshot().nickname,
		},
	})
}

func handleLogout(w http.ResponseWriter, r *http.Request) {
	getClient().ClearAuth()
	writeJSON(w, 200, map[string]interface{}{
		"code":    0,
		"message": "logout",
		"data":    nil,
	})
}

// ==================== 我的微博 ====================

func handleProfileStatuses(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	page, _ := getIntQuery(w, q, "page", 1, 1, true)
	statuses, total, err := getClient().GetMyStatuses(r.Context(), page)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]interface{}{
		"code": 0,
		"data": map[string]interface{}{
			"list":  statuses,
			"total": total,
		},
	})
}
