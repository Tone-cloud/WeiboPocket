package main

import (
	"context"
	"encoding/json"
	"fmt"
)

// ==================== 用户 API ====================

// UserInfo 用户详细信息
type UserInfo struct {
	ID            int64  `json:"id"`
	IDStr         string `json:"idstr"`
	ScreenName    string `json:"screen_name"`
	ProfileURL    string `json:"profile_url"`
	AvatarHD      string `json:"avatar_hd"`
	AvatarLarge   string `json:"avatar_large"`
	Description   string `json:"description"`
	Location      string `json:"location"`
	Gender        string `json:"gender"`
	FollowersCnt  int    `json:"followers_count"`
	FriendsCnt    int    `json:"friends_count"`
	StatusesCnt   int    `json:"statuses_count"`
	FavouritesCnt int    `json:"favourites_count"`
	Verified      bool   `json:"verified"`
	VerifiedType  int    `json:"verified_type"`
	VerifiedReason string `json:"verified_reason"`
	VerifiedTrade string `json:"verified_trade"`
	CreatedAt     string `json:"created_at"`
	Following     bool   `json:"following"`
	FollowMe      bool   `json:"follow_me"`
	BiFollowersCnt int   `json:"bi_followers_count"`
}

// GetUserInfo 获取用户信息
func (c *WeiboClient) GetUserInfo(ctx context.Context, uid string) (*UserInfo, error) {
	params := map[string]string{
		"uid": uid,
	}
	result, err := c.webGet(ctx, weiboAjaxBase+"/profile/info", params)
	if err != nil {
		return nil, fmt.Errorf("获取用户信息失败: %w", err)
	}

	var resp struct {
		OK   int `json:"ok"`
		Data struct {
			User UserInfo `json:"user"`
		} `json:"data"`
	}
	if err := json.Unmarshal(result, &resp); err != nil {
		return nil, fmt.Errorf("解析用户信息失败: %w", err)
	}

	if resp.OK != 1 {
		return nil, fmt.Errorf("用户信息接口返回错误")
	}

	return &resp.Data.User, nil
}

// GetUserStatuses 获取用户微博列表
func (c *WeiboClient) GetUserStatuses(ctx context.Context, uid string, page int) ([]StatusInfo, int, error) {
	params := map[string]string{
		"uid":   uid,
		"page":  fmt.Sprintf("%d", page),
		"feature": "0",
	}
	result, err := c.webGet(ctx, weiboAjaxBase+"/statuses/mymblog", params)
	if err != nil {
		return nil, 0, fmt.Errorf("获取用户微博失败: %w", err)
	}

	var resp struct {
		OK   int `json:"ok"`
		Data struct {
			Total int `json:"total"`
			List  []StatusInfo `json:"list"`
		} `json:"data"`
	}
	if err := json.Unmarshal(result, &resp); err != nil {
		return nil, 0, fmt.Errorf("解析用户微博失败: %w", err)
	}

	return resp.Data.List, resp.Data.Total, nil
}

// GetMyStatuses 获取我的微博
func (c *WeiboClient) GetMyStatuses(ctx context.Context, page int) ([]StatusInfo, int, error) {
	uid := c.getUID()
	if uid == "" {
		return nil, 0, fmt.Errorf("需要登录")
	}
	return c.GetUserStatuses(ctx, uid, page)
}

// GetUserFollowers 获取粉丝列表
func (c *WeiboClient) GetUserFollowers(ctx context.Context, uid string, page int) ([]SearchUser, int, error) {
	params := map[string]string{
		"uid":  uid,
		"page": fmt.Sprintf("%d", page),
	}
	result, err := c.webGet(ctx, weiboAjaxBase+"/friendships/followers", params)
	if err != nil {
		return nil, 0, fmt.Errorf("获取粉丝列表失败: %w", err)
	}

	var resp struct {
		OK   int `json:"ok"`
		Data struct {
			TotalNumber int `json:"total_number"`
			Users       []SearchUser `json:"users"`
		} `json:"data"`
	}
	if err := json.Unmarshal(result, &resp); err != nil {
		return nil, 0, err
	}

	return resp.Data.Users, resp.Data.TotalNumber, nil
}

// GetUserFriends 获取关注列表
func (c *WeiboClient) GetUserFriends(ctx context.Context, uid string, page int) ([]SearchUser, int, error) {
	params := map[string]string{
		"uid":  uid,
		"page": fmt.Sprintf("%d", page),
	}
	result, err := c.webGet(ctx, weiboAjaxBase+"/friendships/friends", params)
	if err != nil {
		return nil, 0, fmt.Errorf("获取关注列表失败: %w", err)
	}

	var resp struct {
		OK   int `json:"ok"`
		Data struct {
			TotalNumber int `json:"total_number"`
			Users       []SearchUser `json:"users"`
		} `json:"data"`
	}
	if err := json.Unmarshal(result, &resp); err != nil {
		return nil, 0, err
	}

	return resp.Data.Users, resp.Data.TotalNumber, nil
}

// ToggleFollow 关注/取消关注用户
func (c *WeiboClient) ToggleFollow(ctx context.Context, uid string, follow bool) (bool, error) {
	if !c.isLoggedIn() {
		return false, fmt.Errorf("需要登录")
	}

	params := map[string]string{
		"uid": uid,
	}
	var result json.RawMessage
	var err error
	if follow {
		result, err = c.webPost(ctx, weiboAjaxBase+"/friendships/create", params)
	} else {
		result, err = c.webPost(ctx, weiboAjaxBase+"/friendships/destroy", params)
	}
	if err != nil {
		return false, err
	}

	var resp struct {
		OK int `json:"ok"`
	}
	if err := json.Unmarshal(result, &resp); err != nil {
		return false, err
	}
	return resp.OK == 1, nil
}

// GetLoginInfo 获取登录信息
func (c *WeiboClient) GetLoginInfo(ctx context.Context) (map[string]interface{}, error) {
	if !c.isLoggedIn() {
		return map[string]interface{}{
			"logged_in": false,
		}, nil
	}

	uid := c.getUID()
	if uid == "" {
		// 尝试验证登录
		uid, nick, err := c.verifyLogin(ctx)
		if err != nil {
			return map[string]interface{}{
				"logged_in": false,
				"error":     err.Error(),
			}, nil
		}
		c.setUID(uid)
		c.setNickname(nick)
	}

	userInfo, err := c.GetUserInfo(ctx, c.getUID())
	if err != nil {
		return map[string]interface{}{
			"logged_in": true,
			"uid":       c.getUID(),
			"nickname":  c.loadSnapshot().nickname,
		}, nil
	}

	return map[string]interface{}{
		"logged_in": true,
		"uid":       userInfo.IDStr,
		"nickname":  userInfo.ScreenName,
		"avatar":    userInfo.AvatarHD,
		"description": userInfo.Description,
		"followers_count": userInfo.FollowersCnt,
		"friends_count":   userInfo.FriendsCnt,
		"statuses_count":  userInfo.StatusesCnt,
		"verified":        userInfo.Verified,
	}, nil
}
