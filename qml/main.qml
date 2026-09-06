import QtQuick 2.12
import WeiboPlugin 1.0
import "pages" as Pages
import "components" as Components

Rectangle {
    id: root
    width: 320
    height: 170
    color: Theme.bgPrimary
    clip: true

    signal backButtonClicked()

    WeiboController {
        id: controller
    }

    property var rootController: controller

    // ── 页面管理 ──
    property string currentPage: "home"
    property var pageStack: []
    property int navIndex: 0

    // 页面参数
    property string detailStatusId: ""
    property string commentsStatusId: ""
    property string commentsTitle: ""
    property string videoStatusId: ""
    property string videoUrl: ""
    property string videoTitle: ""
    property string videoCover: ""
    property string searchKeyword: ""
    property string profileUserId: ""
    property string profileUserName: ""
    property bool _animating: false

    // ── Toast 系统 ──
    property string toastText: ""
    property bool toastVisible: false

    function showToast(text) {
        toastText = text
        toastVisible = true
        toastTimer.restart()
    }

    Timer {
        id: toastTimer
        interval: 2000
        onTriggered: toastVisible = false
    }

    // ── 页面导航 ──
    function navigateTo(page, params) {
        if (currentPage !== page) {
            pageStack.push({ page: currentPage })
        }
        if (params) {
            if (params.statusId !== undefined) {
                detailStatusId = params.statusId
                commentsStatusId = params.statusId
                videoStatusId = params.statusId
            }
            if (params.title !== undefined) commentsTitle = params.title
            if (params.url !== undefined) videoUrl = params.url
            if (params.cover !== undefined) videoCover = params.cover
            if (params.userId !== undefined) profileUserId = params.userId
            if (params.userName !== undefined) profileUserName = params.userName
            if (params.keyword !== undefined) searchKeyword = params.keyword
        }
        currentPage = page
    }

    function navigateBack() {
        if (pageStack.length > 0) {
            var prev = pageStack.pop()
            currentPage = prev.page
        } else {
            // 返回首页
            navIndex = 0
            currentPage = "home"
        }
    }

    // ── 底部导航栏 ──
    Rectangle {
        id: navBar
        anchors.bottom: parent.bottom
        width: parent.width
        height: Theme.tabBarHeight
        color: Theme.bgHeader
        z: 20
        visible: ["home", "supertopic", "search", "profile"].indexOf(currentPage) >= 0

        Row {
            anchors.fill: parent

            Repeater {
                model: [
                    { icon: "🔥", title: "热搜", page: "home", index: 0 },
                    { icon: "⭐", title: "超话", page: "supertopic", index: 1 },
                    { icon: "🔍", title: "搜索", page: "search", index: 2 },
                    { icon: "👤", title: "我的", page: "profile", index: 3 }
                ]

                delegate: Rectangle {
                    width: parent.width / 4
                    height: parent.height
                    color: "transparent"

                    Column {
                        anchors.centerIn: parent
                        spacing: 1

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.icon
                            font.pixelSize: navIndex === modelData.index ? 16 : 14
                            opacity: navIndex === modelData.index ? 1 : 0.6
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.title
                            font.pixelSize: Theme.fontTiny
                            font.family: Theme.fontFamily
                            color: navIndex === modelData.index ? Theme.primary : Theme.textTertiary
                            font.bold: navIndex === modelData.index
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            navIndex = modelData.index
                            currentPage = modelData.page
                            pageStack = []
                        }
                    }
                }
            }
        }

        // 顶部分割线
        Rectangle {
            width: parent.width; height: 1
            anchors.top: parent.top
            color: Theme.border
        }
    }

    // ── 页面容器 ──
    Item {
        id: pageContainer
        anchors.fill: parent
        anchors.bottomMargin: navBar.visible ? Theme.tabBarHeight : 0

        // 首页 - 热搜
        Pages.HomePage {
            id: homePage
            visible: currentPage === "home"
            anchors.fill: parent
        }

        // 超话
        Pages.SuperTopicPage {
            id: superTopicPage
            visible: currentPage === "supertopic"
            anchors.fill: parent
        }

        // 搜索
        Pages.SearchPage {
            id: searchPage
            visible: currentPage === "search"
            anchors.fill: parent
        }

        // 个人中心
        Pages.ProfilePage {
            id: profilePage
            visible: currentPage === "profile"
            anchors.fill: parent
        }

        // 微博详情
        Pages.StatusDetailPage {
            id: statusDetailPage
            visible: currentPage === "detail"
            anchors.fill: parent
        }

        // 评论
        Pages.CommentsPage {
            id: commentsPage
            visible: currentPage === "comments"
            anchors.fill: parent
        }

        // 视频播放
        Pages.VideoPlayerPage {
            id: videoPlayerPage
            visible: currentPage === "video"
            anchors.fill: parent
        }

        // 用户主页
        Pages.UserPage {
            id: userPage
            visible: currentPage === "user"
            anchors.fill: parent
        }

        // 设置
        Pages.SettingsPage {
            id: settingsPage
            visible: currentPage === "settings"
            anchors.fill: parent
        }
    }

    // ── Toast 提示 ──
    Rectangle {
        id: toast
        anchors.centerIn: parent
        width: Math.min(200, toastText.implicitWidth + 24)
        height: 28
        radius: Theme.radiusMedium
        color: "#CC000000"
        visible: toastVisible
        z: 1000

        Text {
            anchors.centerIn: parent
            text: toastText
            font.pixelSize: Theme.fontSmall
            font.family: Theme.fontFamily
            color: "#FFFFFF"
            elide: Text.ElideRight
            width: parent.width - 16
            horizontalAlignment: Text.AlignHCenter
        }

        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    // ── 全局加载指示 ──
    Components.LoadingIndicator {
        anchors.centerIn: parent
        visible: controller.isLoading && !toastVisible
        z: 500
    }

    // ── 信号连接 ──
    Connections {
        target: controller
        function onToastMessage(message) {
            root.showToast(message)
        }
    }

    Component.onCompleted: {
        // 启动时检查登录状态
        if (controller) controller.checkLogin()
    }
}
