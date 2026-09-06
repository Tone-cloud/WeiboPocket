package main

import (
	"context"
	"encoding/json"
	"fmt"
)

// ==================== 搜索 API ====================

// SearchResult 搜索结果
type SearchResult struct {
	Type     string        `json:"type"` // status, user, topic
	Statuses []StatusInfo  `json:"statuses,omitempty"`
	Users    []SearchUser  `json:"users,omitempty"`
	Topics   []SearchTopic `json:"topics,omitempty"`
	Total    int           `json:"total"`
	HasMore  bool          `json:"has_more"`
}

// SearchUser 搜索用户
type SearchUser struct {
	ID           int64  `json:"id"`
	ScreenName   string `json:"screen_name"`
	AvatarHD     string `json:"avatar_hd"`
	Description  string `json:"description"`
	FollowersCnt int   `json:"followers_count"`
	Verified     bool   `json:"verified"`
	VerifiedReason string `json:"verified_reason"`
	FollowMe     bool   `json:"follow_me"`
	Following    bool   `json:"following"`
}

// SearchTopic 搜索话题
type SearchTopic struct {
	Title       string `json:"title"`
	ReadCount   string `json:"read_count"`
	DiscussionCount string `json:"discussion_count"`
	Desc        string `json:"desc"`
}

// SearchStatus 搜索微博
func (c *WeiboClient) SearchStatus(ctx context.Context, keyword string, page int) ([]StatusInfo, int, error) {
	params := map[string]string{
		"q":    keyword,
		"page": fmt.Sprintf("%d", page),
		"type": "1", // 综合
	}
	result, err := c.webGet(ctx, weiboAjaxBase+"/search/type", params)
	if err != nil {
		return nil, 0, fmt.Errorf("搜索微博失败: %w", err)
	}

	var resp struct {
		OK   int `json:"ok"`
		Data struct {
			Cards []struct {
				CardType int `json:"card_type"`
				CardGroup []struct {
					Mblog StatusInfo `json:"mblog"`
				} `json:"card_group"`
				Mblog *StatusInfo `json:"mblog,omitempty"`
			} `json:"cards"`
		} `json:"data"`
	}
	if err := json.Unmarshal(result, &resp); err != nil {
		return nil, 0, fmt.Errorf("解析搜索结果失败: %w", err)
	}

	statuses := make([]StatusInfo, 0)
	for _, card := range resp.Data.Cards {
		if card.CardType == 9 && card.Mblog != nil {
			statuses = append(statuses, *card.Mblog)
		}
		if card.CardType == 11 {
			for _, group := range card.CardGroup {
				if group.Mblog.ID != "" {
					statuses = append(statuses, group.Mblog)
				}
			}
		}
	}

	return statuses, len(statuses), nil
}

// SearchUser 搜索用户
func (c *WeiboClient) SearchUser(ctx context.Context, keyword string, page int) ([]SearchUser, int, error) {
	params := map[string]string{
		"q":    keyword,
		"page": fmt.Sprintf("%d", page),
		"type": "3", // 用户
	}
	result, err := c.webGet(ctx, weiboAjaxBase+"/search/type", params)
	if err != nil {
		return nil, 0, fmt.Errorf("搜索用户失败: %w", err)
	}

	var resp struct {
		OK   int `json:"ok"`
		Data struct {
			Cards []struct {
				CardType int `json:"card_type"`
				CardGroup []struct {
					User SearchUser `json:"user"`
				} `json:"card_group"`
			} `json:"cards"`
		} `json:"data"`
	}
	if err := json.Unmarshal(result, &resp); err != nil {
		return nil, 0, err
	}

	users := make([]SearchUser, 0)
	for _, card := range resp.Data.Cards {
		if card.CardType == 11 {
			for _, group := range card.CardGroup {
				if group.User.ID > 0 {
					users = append(users, group.User)
				}
			}
		}
	}

	return users, len(users), nil
}

// SearchType 综合搜索
func (c *WeiboClient) SearchType(ctx context.Context, keyword string, searchType string, page int) (*SearchResult, error) {
	result := &SearchResult{
		Type: searchType,
	}

	switch searchType {
	case "status", "1":
		statuses, total, err := c.SearchStatus(ctx, keyword, page)
		if err != nil {
			return nil, err
		}
		result.Statuses = statuses
		result.Total = total
	case "user", "3":
		users, total, err := c.SearchUser(ctx, keyword, page)
		if err != nil {
			return nil, err
		}
		result.Users = users
		result.Total = total
	default:
		// 默认综合搜索
		statuses, total, err := c.SearchStatus(ctx, keyword, page)
		if err != nil {
			return nil, err
		}
		result.Statuses = statuses
		result.Total = total
	}

	result.HasMore = result.Total > page*20
	return result, nil
}
