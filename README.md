# 微博口袋（WeiboPocket）

适用于 **有道词典笔 2 代（YDP02x）** + PenMods

面向 `320×170` 触摸屏设计，以插件形式运行在 PenMods 插件系统中。

| 项目 | 说明 |
|------|------|
| 插件 ID | `com.weibopocket.client` |
| 当前版本 | `1.0.0` |
| 作者 | WeiboPocket |
| 安装路径 | `/userdisk/PenMods/plugins/weibo_plugin/` |

---

## 功能

- **热搜榜**：实时微博热搜，支持点击查看相关微博
- **超话签到**：关注超话列表、一键签到、签到状态查看
- **微博详情**：正文、图片、视频、发布者信息
- **评论查看**：一级评论、回复查看与点赞
- **视频播放**：微博内嵌视频本地播放
- **搜索**：关键词搜索微博/用户
- **个人中心**：登录状态、我的微博、关注列表
- **登录**：Cookie 导入登录

---

## 安装 / 更新

1. 从 Release 或自行打包得到 `weibo_plugin.zip`
2. 解压到词典笔：

```text
/userdisk/PenMods/plugins/weibo_plugin/
```

3. 目录中应包含：

```text
weibo_plugin/
├── libweibo_plugin.so   # Qt/C++ 插件
├── qml/                 # QML 界面
├── metadata.json        # 插件入口元数据
├── icon.png
└── server                # 本地 Go API 服务
```

4. 在 PenMods 插件管理中启用 **微博口袋**，进入插件 / 重启设备完成更新。

> 插件会自行拉起本地 Go 服务（默认 `127.0.0.1:8001`）。

---

## 架构概览

```text
  QML UI
    ↓ 调用
WeiboController / modules (Qt/C++)
    ↓ HTTP
本地 Go server (127.0.0.1:8001)
    ↓
微博 API
```

| 层级 | 路径 | 职责 |
|------|------|------|
| UI | `qml/` | 页面路由、交互、绑定展示 |
| 插件运行时 | `src/` | QML 类型注册、网络、模型、业务模块 |
| 本地 API | `go_server/main` | Cookie / 登录态、接口代理与归一化 |

入口契约见 `metadata.json`：

- `main_qml`: `qml/main.qml`
- `main_so`: `libweibo_plugin.so`

---

## 开发构建

> 交叉编译目标为 `arm64-v8a` / `aarch64-linux-gnu`。

### 环境

- Linux 主机
- [xmake](https://xmake.io/) `v3.0.9`
- [Qt（aarch64）开发框架](https://github.com/Redbeanw44602/aarch64-linux-qt-5.15.2)与 zig 交叉工具链
- Go 1.20+（构建 sidecar）

### 配置并编译插件

```bash
xmake f -c \
  --qt="/path/to/qt" \
  --arch=arm64-v8a \
  --toolchain=zigcc \
  --cross=aarch64-linux-gnu.2.27 \
  -m release -vD

xmake
```

产物：

```text
build/linux/arm64-v8a/release/libweibo_plugin.so
```

### 编译 Go 服务

```bash
cd go_server/main && GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -ldflags="-s -w" -trimpath -o ../server
```

### 一键打包

```bash
./package.sh
```

### 本地调试服务

```bash
cd go_server/main && PORT=8001 DEBUG=true go run .
```

---

## 目录结构

```text
weibo_plugin/
├── qml/                 # QML 页面与组件
│   ├── main.qml         # 路由 / 返回栈 / 页面保活
│   ├── pages/           # 业务页面
│   └── components/      # 可复用组件
├── src/                 # Qt/C++ 插件
│   ├── WeiboController.* # QML 边界与启动逻辑
│   ├── WeiboModels.*     # 列表模型与解析
│   ├── WeiboNetwork.*    # 本地 API 客户端
│   └── modules/          # hot / supertopic / status / comment …
├── go_server/
│   └── main/            # 本地 API 服务
├── metadata.json
├── icon.png
├── xmake.lua
└── package.sh
```

---

## 注意事项 / 声明

- 本插件依赖 PenMods 插件机制，**不是**独立桌面客户端。
- 登录 Cookie 与本地服务仅在设备本地使用；请妥善保管设备与账号。
- 使用第三方客户端访问微博接口可能违反平台规则，风险自负。
- 仅用于学习和测试，请于下载后24小时内删除，所用API皆从官方网站收集，不提供任何破解内容。
