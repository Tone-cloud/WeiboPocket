# 微博口袋（WeiboPocket）快速开始

## 项目位置
`C:\Users\aresi\Desktop\cc\WeiboPocket-main`

## 项目结构
```
WeiboPocket-main/
├── metadata.json          # 插件元数据
├── xmake.lua              # C++ 构建配置
├── package.sh             # 一键打包脚本
├── README.md              # 详细文档
├── icon.png               # 插件图标
├── go_server/             # Go 后端 API 服务
│   ├── build.sh           # Go 交叉编译脚本
│   └── main/              # 主服务源码（15个 .go 文件）
│       ├── main.go        # 入口
│       ├── routes.go      # 路由注册
│       ├── handlers.go    # 请求处理
│       ├── client.go      # 微博 API 客户端
│       ├── auth.go        # 认证/Cookie 管理
│       ├── config.go      # 配置常量
│       ├── http.go        # HTTP 辅助
│       ├── log.go         # 日志系统
│       ├── util.go        # 工具函数
│       ├── api_hot.go     # 热搜 API
│       ├── api_status.go  # 微博/评论 API
│       ├── api_supertopic.go # 超话 API
│       ├── api_video.go   # 视频 API
│       ├── api_search.go  # 搜索 API
│       └── api_user.go    # 用户 API
├── src/                   # C++ Qt 插件源码
│   ├── WeiboPlugin.cpp    # 插件入口/QML 类型注册
│   ├── WeiboController.h/cpp  # 主控制器
│   ├── WeiboModels.h/cpp      # 数据模型
│   ├── WeiboNetwork.h/cpp     # 网络客户端
│   ├── WeiboImageProvider.h/cpp # 图片提供者
│   ├── WeiboJsonUtils.h       # JSON 工具
│   ├── WeiboListFetch.hpp     # 列表获取模板
│   └── WeiboAsyncUtils.hpp    # 异步工具
└── qml/                   # QML UI 界面
    ├── main.qml           # 主入口/路由/底部导航
    ├── Theme.qml          # 主题（微博红色主题）
    ├── qmldir             # QML 模块定义
    ├── LXGWWenKai-Regular.ttf # 字体
    ├── components/        # 可复用组件（12个）
    │   ├── TitleBar.qml
    │   ├── StatusCard.qml
    │   ├── CommentCard.qml
    │   ├── HotSearchItem.qml
    │   ├── SuperTopicCard.qml
    │   ├── LoadingIndicator.qml
    │   ├── Toast.qml
    │   ├── IconButton.qml
    │   ├── ErrorOverlay.qml
    │   └── LoadMoreListView.qml
    ├── pages/             # 业务页面（9个）
    │   ├── HomePage.qml       # 首页-热搜榜
    │   ├── SuperTopicPage.qml # 超话签到
    │   ├── SearchPage.qml     # 搜索（微博/用户）
    │   ├── ProfilePage.qml    # 个人中心/登录
    │   ├── StatusDetailPage.qml # 微博详情
    │   ├── CommentsPage.qml   # 评论列表
    │   ├── VideoPlayerPage.qml # 视频播放
    │   ├── UserPage.qml       # 用户主页
    │   └── SettingsPage.qml   # 设置
    └── js/                # JavaScript 工具
        ├── RichText.js
        └── ImageUrl.js
```

## 已实现功能

### 1. 热搜查看
- 实时微博热搜榜（前50）
- 热度显示、新/热/沸标签
- 点击热搜词跳转搜索
- 下拉刷新

### 2. 超话签到
- 关注超话列表
- 单个超话签到
- 一键全部签到
- 签到状态显示、等级、连续签到天数

### 3. 微博详情
- 正文、图片、视频展示
- 转发内容显示
- 发布者信息
- 点赞、评论、转发计数
- 评论预览

### 4. 评论查看
- 一级评论列表
- 回复引用显示
- 评论点赞
- 分页加载更多

### 5. 视频播放
- 微博内嵌视频播放
- 本地 MediaPlayer 播放
- 播放/暂停控制
- 进度条、时间显示
- 自动获取视频播放地址

### 6. 搜索
- 微博搜索
- 用户搜索
- Tab 切换
- 搜索结果列表

### 7. 个人中心
- Cookie 导入登录
- 用户信息展示（头像、昵称、ID、微博数、关注数、粉丝数）
- 我的微博
- 退出登录
- 设置页面

## 构建说明

### Go 后端编译（Linux 交叉编译）
```bash
cd go_server/main
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -ldflags="-s -w" -trimpath -o ../server
```

### C++ 插件编译（需要 aarch64 Qt 环境）
```bash
xmake f -c --qt="/path/to/qt" --arch=arm64-v8a --toolchain=zigcc --cross=aarch64-linux-gnu.2.27 -m release -vD
xmake
```

### 一键打包
```bash
./package.sh
# 生成 weibo_plugin.zip
```

## 安装
1. 将 `weibo_plugin.zip` 解压到词典笔：
   `/userdisk/PenMods/plugins/weibo_plugin/`
2. 在 PenMods 插件管理中启用「微博口袋」
3. 进入插件，在「我的」页面导入微博 Cookie 登录

## 登录方式
在「我的」页面点击「登录」，粘贴从浏览器复制的微博 Cookie（包含 SUB、SUBP、SUHB 等字段）。

## 技术栈
- **后端**: Go 1.20+（HTTP 服务、微博 API 代理、Cookie 管理）
- **插件层**: C++17 / Qt 5.15（QML 类型注册、网络、数据模型）
- **UI 层**: QML / QtQuick（320x170 触摸屏优化）
- **构建**: xmake + zig 交叉工具链
- **目标平台**: arm64-v8a / aarch64-linux-gnu（有道词典笔 2 代）

## 与 BiliPocket 的对应关系
| BiliPocket | WeiboPocket |
|---|---|
| 推荐/热门 | 热搜榜 |
| 排行榜 | 热搜分类 |
| 视频详情 | 微博详情 |
| 评论 | 评论 |
| 播放 | 视频播放 |
| 动态 | 超话 |
| UP主主页 | 用户主页 |
| 个人中心 | 个人中心 |
| 扫码登录 | Cookie 导入登录 |
