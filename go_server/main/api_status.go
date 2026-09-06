package main

import (
	"context"
	"encoding/json"
	"fmt"
)

// ==================== 微博（Status）API ====================

// StatusInfo 微博详情
type StatusInfo struct {
	ID          string `json:"id"`
	IDStr       string `json:"idstr"`
	Mid         string `json:"mid"`
	Text        string `json:"text"`
	TextRaw     string `json:"text_raw"`
	Source      string `json:"source"`
	CreatedAt   string `json:"created_at"`
	CreatedTs   int64  `json:"created_timestamp"`
	RepostsCnt  int    `json:"reposts_count"`
	CommentsCnt int    `json:"comments_count"`
	AttitudesCnt int   `json:"attitudes_count"`
	IsLiked     bool   `json:"is_liked"`
	IsFavorited bool   `json:"is_favorited"`
	PicIDs      []string `json:"pic_ids"`
	Pics        []StatusPic `json:"pics"`
	User        StatusUser `json:"user"`
	Retweeted   *StatusInfo `json:"retweeted_status"`
	PageInfo    *PageInfo `json:"page_info"`
	URLScheme   string `json:"url_scheme"`
}

// StatusPic 微博图片
type StatusPic struct {
	PID       string `json:"pid"`
	URL       string `json:"url"`
	LargeURL  string `json:"large_url"`
	Geo       struct {
		Width  int `json:"width"`
		Height int `json:"height"`
	} `json:"geo"`
}

// StatusUser 微博用户
type StatusUser struct {
	ID           int64  `json:"id"`
	IDStr        string `json:"idstr"`
	ScreenName   string `json:"screen_name"`
	ProfileURL   string `json:"profile_url"`
	AvatarHD     string `json:"avatar_hd"`
	AvatarLarge  string `json:"avatar_large"`
	Description  string `json:"description"`
	FollowersCnt int   `json:"followers_count"`
	FriendsCnt   int    `json:"friends_count"`
	StatusesCnt  int    `json:"statuses_count"`
	Gender       string `json:"gender"`
	Verified     bool   `json:"verified"`
	VerifiedReason string `json:"verified_reason"`
}

// PageInfo 页面信息（视频等）
type PageInfo struct {
	Type         string `json:"type"`
	Title        string `json:"title"`
	Content1     string `json:"content1"`
	Content2     string `json:"content2"`
	URLs         map[string]string `json:"urls"`
	MediaInfo    *MediaInfo `json:"media_info"`
	PicURL       string `json:"page_pic"`
	VideoWidth   int    `json:"width"`
	VideoHeight  int    `json:"height"`
	Duration     string `json:"duration"`
	PlayCount    string `json:"play_count"`
}

// MediaInfo 媒体信息
type MediaInfo struct {
	StreamURL   string `json:"stream_url"`
	StreamURLHd string `json:"stream_url_hd"`
	Duration    float64 `json:"duration"`
	Width       int    `json:"width"`
	Height      int    `json:"height"`
}

// GetStatusShow 获取微博详情
func (c *WeiboClient) GetStatusShow(ctx context.Context, id string) (*StatusInfo, error) {
	params := map[string]string{
		"id": id,
	}
	result, err := c.webGet(ctx, weiboAjaxBase+"/statuses/show", params)
	if err != nil {
		return nil, fmt.Errorf("获取微博详情失败: %w", err)
	}

	var resp struct {
		OK   int         `json:"ok"`
		Data interface{} `json:"data"`
	}
	// 直接解析为 StatusInfo
	var status StatusInfo
	if err := json.Unmarshal(result, &status); err != nil {
		return nil, fmt.Errorf("解析微博详情失败: %w", err)
	}

	if status.ID == "" && status.IDStr == "" {
		// 尝试从 data 字段解析
		var wrapper struct {
			OK   int        `json:"ok"`
			Data StatusInfo `json:"data"`
		}
		if err := json.Unmarshal(result, &wrapper); err == nil && wrapper.Data.ID != "" {
			return &wrapper.Data, nil
		}
		return nil, fmt.Errorf("微博详情解析为空")
	}

	return &status, nil
}

// ToggleStatusLike 微博点赞/取消点赞
func (c *WeiboClient) ToggleStatusLike(ctx context.Context, id string, like bool) (bool, error) {
	if !c.isLoggedIn() {
		return false, fmt.Errorf("需要登录才能点赞")
	}

	action := "like"
	if !like {
		action = "unlike"
	}

	params := map[string]string{
		"id": id,
	}
	var result json.RawMessage
	var err error
	if like {
		result, err = c.webPost(ctx, weiboAjaxBase+"/statuses/like", params)
	} else {
		result, err = c.webPost(ctx, weiboAjaxBase+"/statuses/unlike", params)
	}
	if err != nil {
		return false, fmt.Errorf("点赞操作失败: %w", err)
	}

	var resp struct {
		OK int `json:"ok"`
	}
	if err := json.Unmarshal(result, &resp); err != nil {
		return false, err
	}
	if resp.OK != 1 {
		return false, fmt.Errorf("点赞操作返回错误")
	}
	return like, nil
}

// GetStatusComments 获取微博评论
func (c *WeiboClient) GetStatusComments(ctx context.Context, id string, page, count int) ([]CommentItem, int, error) {
	params := map[string]string{
		"id":    id,
		"page":  fmt.Sprintf("%d", page),
		"count": fmt.Sprintf("%d", count),
	}
	result, err := c.webGet(ctx, weiboAjaxBase+"/comments/buildComments", params)
	if err != nil {
		// 备用接口
		result, err = c.webGet(ctx, weiboAjaxBase+"/statuses/comments", params)
		if err != nil {
			return nil, 0, fmt.Errorf("获取评论失败: %w", err)
		}
	}

	var resp struct {
		OK   int `json:"ok"`
		Data struct {
			TotalNumber int `json:"total_number"`
			Data        []struct {
				ID           int64  `json:"id"`
				IDStr        string `json:"idstr"`
				Text         string `json:"text"`
				Source       string `json:"source"`
				CreatedAt    string `json:"created_at"`
				LikeCount    int    `json:"like_count"`
				Liked        bool   `json:"liked"`
				ReplyCount   int    `json:"reply_count"`
				User         CommentUser `json:"user"`
				ReplyComment *struct {
					ID   int64  `json:"id"`
					Text string `json:"text"`
					User CommentUser `json:"user"`
				} `json:"reply_comment"`
			} `json:"data"`
		} `json:"data"`
	}
	if err := json.Unmarshal(result, &resp); err != nil {
		return nil, 0, fmt.Errorf("解析评论响应失败: %w", err)
	}

	comments := make([]CommentItem, 0, len(resp.Data.Data))
	for _, c := range resp.Data.Data {
		item := CommentItem{
			ID:         c.ID,
			IDStr:      c.IDStr,
			Text:       stripHTML(c.Text),
			Source:     c.Source,
			CreatedAt:  c.CreatedAt,
			LikeCount:  c.LikeCount,
			Liked:      c.Liked,
			ReplyCount: c.ReplyCount,
			User: CommentUser{
				ID:         c.User.ID,
				ScreenName: c.User.ScreenName,
				AvatarHD:   c.User.AvatarHD,
			},
		}
		if c.ReplyComment != nil {
			item.ReplyTo = &ReplyInfo{
				ID:   c.ReplyComment.ID,
				Text: stripHTML(c.ReplyComment.Text),
				User: CommentUser{
					ID:         c.ReplyComment.User.ID,
					ScreenName: c.ReplyComment.User.ScreenName,
				},
			}
		}
		comments = append(comments, item)
	}

	return comments, resp.Data.TotalNumber, nil
}

// CommentItem 评论条目
type CommentItem struct {
	ID         int64       `json:"id"`
	IDStr      string      `json:"idstr"`
	Text       string      `json:"text"`
	Source     string      `json:"source"`
	CreatedAt  string      `json:"created_at"`
	LikeCount  int         `json:"like_count"`
	Liked      bool        `json:"liked"`
	ReplyCount int         `json:"reply_count"`
	User       CommentUser `json:"user"`
	ReplyTo    *ReplyInfo  `json:"reply_to,omitempty"`
}

// CommentUser 评论用户
type CommentUser struct {
	ID         int64  `json:"id"`
	ScreenName string `json:"screen_name"`
	AvatarHD   string `json:"avatar_hd"`
}

// ReplyInfo 回复信息
type ReplyInfo struct {
	ID   int64       `json:"id"`
	Text string      `json:"text"`
	User CommentUser `json:"user"`
}

// GetCommentReplies 获取评论回复
func (c *WeiboClient) GetCommentReplies(ctx context.Context, statusID, commentID string, page, count int) ([]CommentItem, int, error) {
	params := map[string]string{
		"id":      commentID,
		"mid":     statusID,
		"page":    fmt.Sprintf("%d", page),
		"count":   fmt.Sprintf("%d", count),
		"is_big":  "0",
		"max_id":  "0",
	}
	result, err := c.webGet(ctx, weiboAjaxBase+"/comments/buildComments", params)
	if err != nil {
		return nil, 0, fmt.Errorf("获取评论回复失败: %w", err)
	}

	var resp struct {
		OK   int `json:"ok"`
		Data struct {
			TotalNumber int `json:"total_number"`
			Data        []struct {
				ID          int64  `json:"id"`
				IDStr       string `json:"idstr"`
				Text        string `json:"text"`
				Source      string `json:"source"`
				CreatedAt   string `json:"created_at"`
				LikeCount   int    `json:"like_count"`
				Liked       bool   `json:"liked"`
				User        CommentUser `json:"user"`
			} `json:"data"`
		} `json:"data"`
	}
	if err := json.Unmarshal(result, &resp); err != nil {
		return nil, 0, err
	}

	replies := make([]CommentItem, 0, len(resp.Data.Data))
	for _, r := range resp.Data.Data {
		replies = append(replies, CommentItem{
			ID:        r.ID,
			IDStr:     r.IDStr,
			Text:      stripHTML(r.Text),
			Source:    r.Source,
			CreatedAt: r.CreatedAt,
			LikeCount: r.LikeCount,
			Liked:     r.Liked,
			User:      r.User,
		})
	}
	return replies, resp.Data.TotalNumber, nil
}

// ToggleCommentLike 评论点赞/取消点赞
func (c *WeiboClient) ToggleCommentLike(ctx context.Context, commentID string, like bool) (bool, error) {
	if !c.isLoggedIn() {
		return false, fmt.Errorf("需要登录")
	}

	params := map[string]string{
		"id": commentID,
	}
	var result json.RawMessage
	var err error
	if like {
		result, err = c.webPost(ctx, weiboAjaxBase+"/comments/like", params)
	} else {
		result, err = c.webPost(ctx, weiboAjaxBase+"/comments/unlike", params)
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
