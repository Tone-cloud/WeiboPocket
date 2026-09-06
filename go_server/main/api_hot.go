package main

import (
	"context"
	"encoding/json"
	"fmt"
)

// ==================== 热搜 API ====================

// HotSearchItem 热搜条目
type HotSearchItem struct {
	Rank       int    `json:"rank"`
	Word       string `json:"word"`
	HotNum     int64  `json:"hot_num"`
	HotNumStr  string `json:"hot_num_str"`
	Category   string `json:"category"`
	IconDesc   string `json:"icon_desc"`
	IsNew      bool   `json:"is_new"`
	IsHot      bool   `json:"is_hot"`
	IsBoil     bool   `json:"is_boil"`
	IsRec      bool   `json:"is_rec"`
	Note       string `json:"note"`
	TopicFlag  int    `json:"topic_flag"`
	LabelName  string `json:"label_name"`
	URL        string `json:"url"`
}

// GetHotSearch 获取微博热搜榜
func (c *WeiboClient) GetHotSearch(ctx context.Context, limit int) ([]HotSearchItem, error) {
	result, err := c.webGet(ctx, weiboAjaxBase+"/side/hotSearch", nil)
	if err != nil {
		return nil, fmt.Errorf("获取热搜失败: %w", err)
	}

	var resp struct {
		OK   int `json:"ok"`
		Data struct {
			Realtime []struct {
				Word      string `json:"word"`
				Num       int64  `json:"num"`
				Category  string `json:"category"`
				IconDesc  string `json:"icon_desc"`
				IsNew     int    `json:"is_new"`
				IsHot     int    `json:"is_hot"`
				IsBoil    int    `json:"is_boil"`
				IsRec     int    `json:"is_rec"`
				Note      string `json:"note"`
				TopicFlag int    `json:"topic_flag"`
				LabelName string `json:"label_name"`
				WordScheme string `json:"word_scheme"`
			} `json:"realtime"`
		} `json:"data"`
	}
	if err := json.Unmarshal(result, &resp); err != nil {
		return nil, fmt.Errorf("解析热搜响应失败: %w", err)
	}

	if resp.OK != 1 {
		return nil, fmt.Errorf("热搜接口返回错误")
	}

	items := make([]HotSearchItem, 0, len(resp.Data.Realtime))
	for i, item := range resp.Data.Realtime {
		if limit > 0 && i >= limit {
			break
		}
		hotItem := HotSearchItem{
			Rank:      i + 1,
			Word:      item.Word,
			HotNum:    item.Num,
			HotNumStr: formatHotNum(item.Num),
			Category:  item.Category,
			IconDesc:  item.IconDesc,
			IsNew:     item.IsNew == 1,
			IsHot:     item.IsHot == 1,
			IsBoil:    item.IsBoil == 1,
			IsRec:     item.IsRec == 1,
			Note:      item.Note,
			TopicFlag: item.TopicFlag,
			LabelName: item.LabelName,
			URL:       "https://s.weibo.com/weibo?q=" + item.Word,
		}
		items = append(items, hotItem)
	}

	return items, nil
}

// GetHotSearchCategories 获取热搜分类
func (c *WeiboClient) GetHotSearchCategories(ctx context.Context) ([]map[string]interface{}, error) {
	result, err := c.webGet(ctx, weiboAjaxBase+"/side/hotSearch", nil)
	if err != nil {
		return nil, err
	}

	var resp struct {
		OK   int `json:"ok"`
		Data struct {
			Categories []struct {
				Title   string `json:"title"`
				Channel string `json:"channel"`
				IconURL string `json:"icon_url"`
			} `json:"hot_topic_category"`
		} `json:"data"`
	}
	if err := json.Unmarshal(result, &resp); err != nil {
		return nil, err
	}

	categories := make([]map[string]interface{}, 0)
	for _, cat := range resp.Data.Categories {
		categories = append(categories, map[string]interface{}{
			"title":    cat.Title,
			"channel":  cat.Channel,
			"icon_url": cat.IconURL,
		})
	}
	return categories, nil
}

// formatHotNum 格式化热度数字
func formatHotNum(num int64) string {
	if num >= 100000000 {
		return fmt.Sprintf("%.1f亿", float64(num)/100000000)
	}
	if num >= 10000 {
		return fmt.Sprintf("%.1f万", float64(num)/10000)
	}
	return fmt.Sprintf("%d", num)
}
