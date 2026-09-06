package main

import "net/http"

// ==================== 路由注册 ====================

func setupRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/", handleRoot)

	// 热搜
	mux.HandleFunc("/hot/search", handleHotSearch)
	mux.HandleFunc("/hot/search/categories", handleHotSearchCategories)

	// 微博详情
	mux.HandleFunc("/statuses/show", handleStatusShow)
	mux.HandleFunc("/statuses/like/toggle", handleStatusLikeToggle)

	// 评论
	mux.HandleFunc("/statuses/comments", handleStatusComments)
	mux.HandleFunc("/statuses/comments/replies", handleCommentReplies)
	mux.HandleFunc("/comment/like/toggle", handleCommentLikeToggle)

	// 超话
	mux.HandleFunc("/supertopic/list", handleSuperTopicList)
	mux.HandleFunc("/supertopic/checkin", handleSuperTopicCheckin)
	mux.HandleFunc("/supertopic/checkin/status", handleSuperTopicCheckinStatus)
	mux.HandleFunc("/supertopic/checkin/batch", handleSuperTopicBatchCheckin)

	// 视频
	mux.HandleFunc("/video/info", handleVideoInfo)
	mux.HandleFunc("/video/playurl", handleVideoPlayURL)

	// 搜索
	mux.HandleFunc("/search/type", handleSearchType)
	mux.HandleFunc("/search/status", handleSearchStatus)
	mux.HandleFunc("/search/user", handleSearchUser)

	// 用户
	mux.HandleFunc("/user/info", handleUserInfo)
	mux.HandleFunc("/user/statuses", handleUserStatuses)
	mux.HandleFunc("/user/followers", handleUserFollowers)
	mux.HandleFunc("/user/friends", handleUserFriends)
	mux.HandleFunc("/user/follow/toggle", handleUserFollowToggle)

	// 登录
	mux.HandleFunc("/login/info", handleLoginInfo)
	mux.HandleFunc("/login/import", handleLoginImport)
	mux.HandleFunc("/logout", handleLogout)

	// 个人中心
	mux.HandleFunc("/profile/statuses", handleProfileStatuses)
}
