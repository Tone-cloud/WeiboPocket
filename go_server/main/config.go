package main

// ==================== 配置常量 ====================

const (
	// 微博 Web 端 API 基础地址
	weiboWebBase  = "https://weibo.com"
	weiboAjaxBase = "https://weibo.com/ajax"
	weiboMBase    = "https://m.weibo.cn"
	weiboHuatiBase = "https://i.huati.weibo.com"

	// 默认服务端口
	defaultPort = "8001"
)

const (
	defaultUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
	defaultReferer   = "https://weibo.com/"
	mobileUserAgent  = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
)

// Cookie 存储文件路径（相对于插件目录）
const cookieStoreFile = "weibo_cookies.json"

// ==================== 接口列表 ====================

var rootEndpoints = []string{
	"/hot/search - 微博热搜榜",
	"/hot/search/categories - 热搜分类",
	"/statuses/show - 微博详情",
	"/statuses/comments - 微博评论",
	"/statuses/comments/replies - 评论回复",
	"/statuses/like/toggle - 微博点赞",
	"/comment/like/toggle - 评论点赞",
	"/supertopic/list - 关注超话列表",
	"/supertopic/checkin - 超话签到",
	"/supertopic/checkin/status - 超话签到状态",
	"/video/info - 视频信息",
	"/video/playurl - 视频播放地址",
	"/search/type - 综合搜索",
	"/search/status - 搜索微博",
	"/search/user - 搜索用户",
	"/user/info - 用户信息",
	"/user/statuses - 用户微博列表",
	"/user/followers - 粉丝列表",
	"/user/friends - 关注列表",
	"/login/info - 登录信息",
	"/login/import - 导入登录Cookie",
	"/logout - 退出登录",
	"/profile/statuses - 我的微博",
}

var startupEndpoints = []string{
	"GET  /hot/search             - 微博热搜榜",
	"GET  /hot/search/categories  - 热搜分类",
	"GET  /statuses/show          - 微博详情",
	"GET  /statuses/comments      - 微博评论",
	"GET  /statuses/comments/replies - 评论回复",
	"GET  /statuses/like/toggle   - 微博点赞切换",
	"GET  /comment/like/toggle    - 评论点赞切换",
	"GET  /supertopic/list        - 关注超话列表",
	"GET  /supertopic/checkin     - 超话签到",
	"GET  /supertopic/checkin/status - 超话签到状态",
	"GET  /video/info             - 视频信息",
	"GET  /video/playurl          - 视频播放地址",
	"GET  /search/type            - 综合搜索",
	"GET  /search/status          - 搜索微博",
	"GET  /search/user            - 搜索用户",
	"GET  /user/info              - 用户信息",
	"GET  /user/statuses          - 用户微博列表",
	"GET  /user/followers         - 粉丝列表",
	"GET  /user/friends           - 关注列表",
	"GET  /login/info             - 登录信息",
	"POST /login/import           - 导入登录Cookie",
	"GET  /logout                 - 退出登录",
	"GET  /profile/statuses       - 我的微博",
}
