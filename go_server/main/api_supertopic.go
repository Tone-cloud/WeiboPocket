package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/url"
)

// ==================== 超话 API ====================

// SuperTopic 超话信息
type SuperTopic struct {
	ID          string `json:"id"`
	Title       string `json:"title"`
	TitleURL    string `json:"title_url"`
	CoverPic    string `json:"cover_pic"`
	Desc1       string `json:"desc1"`
	Desc2       string `json:"desc2"`
	DescText    string `json:"desc_text"`
	ReadCount   string `json:"read_count"`
	PostCount   string `json:"post_count"`
	FollowCount string `json:"follow_count"`
	Rank        int    `json:"rank"`
	IsSigned    bool   `json:"is_signed"`
	SignStatus  string `json:"sign_status"`
	Level       int    `json:"level"`
	LevelName   string `json:"level_name"`
	Continuous  int    `json:"continuous_sign"`
	TopicID     string `json:"topic_id"`
	TopicOID    string `json:"topic_oid"`
}

// GetSuperTopicList 获取关注的超话列表
func (c *WeiboClient) GetSuperTopicList(ctx context.Context, page int) ([]SuperTopic, int, error) {
	if !c.isLoggedIn() {
		return nil, 0, fmt.Errorf("需要登录才能查看超话列表")
	}

	uid := c.getUID()
	if uid == "" {
		return nil, 0, fmt.Errorf("无法获取用户ID")
	}

	// 使用移动端接口获取超话列表
	params := map[string]string{
		"uid":  uid,
		"page": fmt.Sprintf("%d", page),
	}
	result, err := c.mobileGet(ctx, weiboMBase+"/api/container/getIndex", params)
	if err != nil {
		// 备用：使用 web 端 profile 接口
		params2 := map[string]string{
			"uid":    uid,
			"pageid": "231093_-_selffollowed",
		}
		result, err = c.webGet(ctx, weiboAjaxBase+"/profile/topicContent", params2)
		if err != nil {
			return nil, 0, fmt.Errorf("获取超话列表失败: %w", err)
		}
	}

	var resp struct {
		OK   int `json:"ok"`
		Data struct {
			CardListInfo struct {
				Total int `json:"total"`
			} `json:"cardlistInfo"`
			Cards []struct {
				CardType int `json:"card_type"`
				CardGroup []struct {
					Pic     string `json:"pic"`
					TitleSub string `json:"title_sub"`
					Desc1   string `json:"desc1"`
					Desc2   string `json:"desc2"`
					Scheme  string `json:"scheme"`
				} `json:"card_group"`
			} `json:"cards"`
		} `json:"data"`
	}
	if err := json.Unmarshal(result, &resp); err != nil {
		return nil, 0, fmt.Errorf("解析超话列表失败: %w", err)
	}

	topics := make([]SuperTopic, 0)
	total := resp.Data.CardListInfo.Total

	for _, card := range resp.Data.Cards {
		if card.CardType != 11 {
			continue
		}
		for i, group := range card.CardGroup {
			topic := SuperTopic{
				Rank:       i + 1,
				Title:      group.TitleSub,
				CoverPic:   group.Pic,
				Desc1:      group.Desc1,
				Desc2:      group.Desc2,
				TitleURL:   group.Scheme,
			}
			// 从 scheme 中提取 topic_id
			if u, err := url.Parse(group.Scheme); err == nil {
				topic.TopicID = u.Query().Get("id")
			}
			topics = append(topics, topic)
		}
	}

	return topics, total, nil
}

// SuperTopicCheckin 超话签到
func (c *WeiboClient) SuperTopicCheckin(ctx context.Context, topicID string) (map[string]interface{}, error) {
	if !c.isLoggedIn() {
		return nil, fmt.Errorf("需要登录才能签到")
	}

	// 方法1: 使用 web 端签到接口
	params := map[string]string{
		"ajwvr": "6",
		"api":   "http://i.huati.weibo.com/aj/super/checkin",
		"texta": "签到",
		"textb": "已签到",
		"status": "0",
		"id":     topicID,
	}
	result, err := c.webPost(ctx, weiboWebBase+"/p/aj/general/button", params)
	if err != nil {
		// 方法2: 直接调用超话签到接口
		params2 := map[string]string{
			"id": topicID,
		}
		result, err = c.webPost(ctx, weiboHuatiBase+"/aj/super/checkin", params2)
		if err != nil {
			return nil, fmt.Errorf("签到失败: %w", err)
		}
	}

	var resp map[string]interface{}
	if err := json.Unmarshal(result, &resp); err != nil {
		return nil, fmt.Errorf("解析签到响应失败: %w", err)
	}

	// 检查签到结果
	code, _ := resp["code"].(string)
	if code == "100000" || code == "1" {
		return map[string]interface{}{
			"success": true,
			"message": "签到成功",
			"data":    resp,
		}, nil
	}

	// 可能已经签到
	msg, _ := resp["msg"].(string)
	return map[string]interface{}{
		"success": false,
		"message": msg,
		"data":    resp,
	}, nil
}

// GetSuperTopicCheckinStatus 获取超话签到状态
func (c *WeiboClient) GetSuperTopicCheckinStatus(ctx context.Context, topicID string) (map[string]interface{}, error) {
	if !c.isLoggedIn() {
		return nil, fmt.Errorf("需要登录")
	}

	// 获取超话详情页来检查签到状态
	params := map[string]string{
		"id": topicID,
	}
	result, err := c.webGet(ctx, weiboHuatiBase+"/aj/super/info", params)
	if err != nil {
		return nil, fmt.Errorf("获取签到状态失败: %w", err)
	}

	var resp map[string]interface{}
	if err := json.Unmarshal(result, &resp); err != nil {
		return nil, err
	}

	return resp, nil
}

// BatchCheckin 批量签到所有关注超话
func (c *WeiboClient) BatchCheckin(ctx context.Context) ([]map[string]interface{}, error) {
	topics, _, err := c.GetSuperTopicList(ctx, 1)
	if err != nil {
		return nil, err
	}

	results := make([]map[string]interface{}, 0, len(topics))
	for _, topic := range topics {
		if topic.TopicID == "" {
			continue
		}
		result, err := c.SuperTopicCheckin(ctx, topic.TopicID)
		entry := map[string]interface{}{
			"topic_id": topic.TopicID,
			"title":    topic.Title,
		}
		if err != nil {
			entry["success"] = false
			entry["message"] = err.Error()
		} else {
			entry["success"] = result["success"]
			entry["message"] = result["message"]
		}
		results = append(results, entry)
	}
	return results, nil
}
