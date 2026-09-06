# 微博口袋（WeiboPocket）编译教程

## 项目信息

| 项目 | 说明 |
|------|------|
| 项目根目录 | `C:\Users\aresi\Desktop\cc\WeiboPocket-main` |
| GitHub 仓库 | `https://github.com/Tone-cloud/WeiboPocket` |
| 插件 ID | `com.weibopocket.client` |
| 插件名称 | 微博口袋 |
| 设备平台 | ARM64（aarch64，有道词典笔 2 代 YDP02x） |
| 屏幕分辨率 | 320×170 触摸屏 |
| PenMods 框架 | `https://github.com/Lyrecoul/PenMods` |

---

## 一、Go Server 编译

Go SDK 路径：`C:\Users\aresi\go-sdk\go\bin\go.exe`（Go 1.22.5）

### 编译命令（PowerShell）

```powershell
$env:GOOS = "linux"
$env:GOARCH = "arm64"
$env:CGO_ENABLED = "0"
cd "C:\Users\aresi\Desktop\cc\WeiboPocket-main\go_server\main"
& "C:\Users\aresi\go-sdk\go\bin\go.exe" build -ldflags="-s -w" -trimpath -o "..\server" .
```

### 参数说明

| 参数 | 说明 |
|------|------|
| `GOOS=linux` | 目标系统 Linux |
| `GOARCH=arm64` | 目标架构 ARM64（词典笔是 ARM64） |
| `CGO_ENABLED=0` | 禁用 CGO，纯静态编译 |
| `-ldflags="-s -w"` | 去除调试符号，减小体积 |
| `-trimpath` | 去除编译路径信息 |

### 输出文件

```
C:\Users\aresi\Desktop\cc\WeiboPocket-main\go_server\server
```

约 6~8 MB（纯静态二进制，无外部依赖）。

### 项目现成脚本

项目根目录下有 `go_server/build.sh`（Linux/Mac 环境）：

```bash
cd go_server
./build.sh
```

Windows 环境可直接使用上面的 PowerShell 命令。

---

## 二、C++ 插件（.so）编译

目前通过 **GitHub Actions 自动编译**，不需要本地编译。

### 触发条件

推送代码到 `main` 分支，且修改了 `src/` 目录下的文件（C++ 源码）。

### 编译环境（GitHub Actions）

| 项目 | 说明 |
|------|------|
| 系统 | Ubuntu latest |
| 编译器 | `aarch64-dictpen-linux-gnu-g++`（ARM64 交叉编译器） |
| Qt 版本 | 5.15.2（专门为词典笔编译的版本） |
| 构建工具 | xmake |
| 目标架构 | arm64-v8a / aarch64-linux-gnu |

### 编译流程

1. 克隆 Qt 5.15.2 for aarch64
2. 克隆 GCC 交叉编译工具链（zigcc）
3. 配置 xmake 交叉编译环境
4. `xmake f -c --qt="/path/to/qt" --arch=arm64-v8a --toolchain=zigcc --cross=aarch64-linux-gnu.2.27 -m release`
5. `xmake` 编译
6. `aarch64-dictpen-linux-gnu-strip` 去除调试符号

### 下载编译产物

1. 打开 GitHub 仓库 → **Actions** 页面
2. 找到最新的成功的 **build** 工作流
3. 页面底部 **Artifacts** → 点击 `libweibo_plugin` 下载
4. 解压得到 `libweibo_plugin.so`（约 100~200 KB）

### 输出文件

```
build/linux/arm64-v8a/release/libweibo_plugin.so
```

### 本地编译（可选，需要 Linux 环境）

如果有 Linux 主机并配置好了交叉编译环境，可以本地编译：

```bash
# 安装 xmake
curl -fsSL https://xmake.io/shget.text | bash

# 配置交叉编译
xmake f -c \
  --qt="/path/to/qt-5.15.2-aarch64" \
  --arch=arm64-v8a \
  --toolchain=zigcc \
  --cross=aarch64-linux-gnu.2.27 \
  -m release -vD

# 编译
xmake
```

依赖的 Qt 交叉编译版本：`https://github.com/Redbeanw44602/aarch64-linux-qt-5.15.2`

---

## 三、打包部署

### 一键打包脚本

项目根目录下有 `package.sh`（Linux/Mac 环境），会自动编译并打包：

```bash
./package.sh
```

生成 `weibo_plugin.zip`。

### 手动打包

需要的文件：

```
weibo_plugin/
├── server                  # Go server 编译产物（第一步生成）
├── libweibo_plugin.so     # C++ 插件编译产物（第二步生成）
├── qml/                    # QML 前端（所有 .qml 文件 + 字体）
│   ├── main.qml
│   ├── Theme.qml
│   ├── qmldir
│   ├── LXGWWenKai-Regular.ttf
│   ├── components/
│   ├── pages/
│   └── js/
├── metadata.json           # 插件元数据
└── icon.png                # 插件图标
```

打包命令（PowerShell）：

```powershell
cd "C:\Users\aresi\Desktop\cc\WeiboPocket-main"

# 创建临时目录
mkdir weibo_plugin

# 复制文件
copy go_server\server weibo_plugin\
copy build\linux\arm64-v8a\release\libweibo_plugin.so weibo_plugin\
xcopy /E /I qml weibo_plugin\qml
copy metadata.json weibo_plugin\
copy icon.png weibo_plugin\

# 打包
Compress-Archive -Path weibo_plugin\* -DestinationPath weibo_plugin.zip

# 清理
Remove-Item -Recurse -Force weibo_plugin
```

### 部署到词典笔

通过 ADB 或文件管理器将 `weibo_plugin.zip` 解压到：

```
/userdisk/PenMods/plugins/weibo_plugin/
```

最终目录结构：

```
/userdisk/PenMods/plugins/weibo_plugin/
├── server                  # Go server
├── libweibo_plugin.so     # C++ 插件
├── qml/                    # QML 文件
├── metadata.json
└── icon.png
```

### 启用插件

1. 在 PenMods 插件管理中找到 **微博口袋**
2. 启用插件
3. 进入插件 / 重启设备完成更新

> 插件会自行拉起本地 Go 服务（默认 `127.0.0.1:8001`，与 BiliPocket 的 8000 端口区分）。

---

## 四、登录说明

微博使用 Cookie 登录，无需扫码：

1. 在浏览器登录微博（weibo.com）
2. 按 F12 打开开发者工具 → Application/应用 → Cookies
3. 复制以下字段的值：
   - `SUB`（必填）
   - `SUBP`
   - `SUHB`
   - `SSOLoginState`
   - `ALF`
   - `SCF`
   - `_T_WM`
   - `XSRF-TOKEN`
4. 组合成 Cookie 字符串：`SUB=xxx; SUBP=xxx; SUHB=xxx; ...`
5. 在插件「我的」页面点击「登录」，粘贴 Cookie 字符串

---

## 五、常见问题

### Q: Go 编译报错 `go: cannot find main module`

A: 确保在 `go_server/main` 目录下执行编译命令，该目录下有 `go.mod`。

### Q: 插件启动后闪退

A: 检查 `server` 文件是否有执行权限：
```bash
chmod +x /userdisk/PenMods/plugins/weibo_plugin/server
```

### Q: 热搜加载失败

A: 检查 Go 服务是否启动：
```bash
ps | grep server
```
或查看日志：插件会输出服务启动日志。

### Q: 超话签到提示未登录

A: 微博超话签到需要登录态，请先在「我的」页面导入 Cookie。

### Q: 视频无法播放

A: 词典笔需要安装 mpv 播放器（路径 `/userdisk/mpv/mpv`），BiliPocket 等插件通常已自带。

---

## 六、项目架构

```
  QML UI（qml/）
    ↓ 调用
  WeiboController / modules（src/，Qt/C++）
    ↓ HTTP
  本地 Go server（127.0.0.1:8001）
    ↓
  微博 API（weibo.com）
```

| 层级 | 路径 | 职责 |
|------|------|------|
| UI | `qml/` | 页面路由、交互、绑定展示 |
| 插件运行时 | `src/` | QML 类型注册、网络、模型、业务模块 |
| 本地 API | `go_server/main/` | Cookie/登录态、接口代理与归一化 |

入口契约见 `metadata.json`：
- `main_qml`: `qml/main.qml`
- `main_so`: `libweibo_plugin.so`

---

## 七、相关链接

| 项目 | 地址 |
|------|------|
| WeiboPocket 仓库 | `https://github.com/Tone-cloud/WeiboPocket` |
| PenMods 框架 | `https://github.com/Lyrecoul/PenMods` |
| Qt 5.15.2 aarch64 | `https://github.com/Redbeanw44602/aarch64-linux-qt-5.15.2` |
| xmake 构建工具 | `https://xmake.io/` |
| BiliPocket（参考项目） | 同作者的 B 站词典笔插件 |
