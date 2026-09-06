package main

import (
	"context"
	"encoding/json"
	"fmt"
)

// ==================== 视频 API ====================

// VideoInfo 视频信息
type VideoInfo struct {
	StatusID    string  `json:"status_id"`
	Title       string  `json:"title"`
	Description string  `json:"description"`
	CoverURL    string  `json:"cover_url"`
	StreamURL   string  `json:"stream_url"`
	StreamURLHd string  `json:"stream_url_hd"`
	Duration    float64 `json:"duration"`
	DurationStr string  `json:"duration_str"`
	Width       int     `json:"width"`
	Height      int     `json:"height"`
	PlayCount   string  `json:"play_count"`
	User        StatusUser `json:"user"`
}

// GetVideoInfo 从微博中提取视频信息
func (c *WeiboClient) GetVideoInfo(ctx context.Context, statusID string) (*VideoInfo, error) {
	status, err := c.GetStatusShow(ctx, statusID)
	if err != nil {
		return nil, err
	}

	if status.PageInfo == nil || status.PageInfo.MediaInfo == nil {
		return nil, fmt.Errorf("该微博不包含视频")
	}

	video := &VideoInfo{
		StatusID:    statusID,
		Title:       status.PageInfo.Title,
		Description: status.TextRaw,
		CoverURL:    status.PageInfo.PicURL,
		StreamURL:   status.PageInfo.MediaInfo.StreamURL,
		StreamURLHd: status.PageInfo.MediaInfo.StreamURLHd,
		Duration:    status.PageInfo.MediaInfo.Duration,
		DurationStr: formatDuration(status.PageInfo.MediaInfo.Duration),
		Width:       status.PageInfo.MediaInfo.Width,
		Height:      status.PageInfo.MediaInfo.Height,
		PlayCount:   status.PageInfo.PlayCount,
		User:        status.User,
	}

	return video, nil
}

// GetVideoPlayURL 获取视频播放地址
func (c *WeiboClient) GetVideoPlayURL(ctx context.Context, statusID string, quality string) (map[string]interface{}, error) {
	video, err := c.GetVideoInfo(ctx, statusID)
	if err != nil {
		return nil, err
	}

	playURL := video.StreamURL
	if quality == "hd" && video.StreamURLHd != "" {
		playURL = video.StreamURLHd
	}

	return map[string]interface{}{
		"status_id":      statusID,
		"play_url":       playURL,
		"play_url_hd":    video.StreamURLHd,
		"play_url_sd":    video.StreamURL,
		"cover_url":      video.CoverURL,
		"duration":       video.Duration,
		"duration_str":   video.DurationStr,
		"width":          video.Width,
		"height":         video.Height,
		"title":          video.Title,
		"quality":        quality,
		"available_qualities": []string{"sd", "hd"},
	}, nil
}

// formatDuration 格式化时长
func formatDuration(seconds float64) string {
	if seconds <= 0 {
		return "00:00"
	}
	mins := int(seconds) / 60
	secs := int(seconds) % 60
	if mins >= 60 {
		hours := mins / 60
		mins = mins % 60
		return fmt.Sprintf("%02d:%02d:%02d", hours, mins, secs)
	}
	return fmt.Sprintf("%02d:%02d", mins, secs)
}

// GetVideoByURL 通过视频 URL 获取播放地址（备用方法）
func (c *WeiboClient) GetVideoByURL(ctx context.Context, videoURL string) (map[string]interface{}, error) {
	// 微博视频 URL 通常格式: https://weibo.com/tv/show/1034:xxx
	// 或者通过 page_info 获取
	// 这里直接返回原始 URL（微博视频无防盗链）
	return map[string]interface{}{
		"play_url": videoURL,
		"note":     "微博视频无防盗链，可直接播放",
	}, nil
}
