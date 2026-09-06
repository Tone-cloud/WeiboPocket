import QtQuick 2.12
import WeiboPlugin 1.0
import "../components" as Components

Rectangle {
    id: searchPage
    color: Theme.bgPrimary

    property string currentKeyword: ""
    property int searchTab: 0 // 0=微博, 1=用户

    // ── 搜索栏 ──
    Rectangle {
        id: searchBar
        width: parent.width
        height: 34
        color: Theme.bgHeader

        Row {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingLarge
            anchors.rightMargin: Theme.spacingLarge
            spacing: Theme.spacingMedium

            // 返回按钮
            Canvas {
                width: 18; height: 18
                anchors.verticalCenter: parent.verticalCenter
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = Theme.textPrimary
                    ctx.lineWidth = 2
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()
                    ctx.moveTo(13, 3)
                    ctx.lineTo(5, 9)
                    ctx.lineTo(13, 15)
                    ctx.stroke()
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    onClicked: {
                        root.navIndex = 0
                        root.currentPage = "home"
                        root.pageStack = []
                    }
                }
            }

            // 搜索框
            Rectangle {
                width: parent.width - 18 - Theme.spacingMedium - 40
                height: 24
                radius: Theme.radiusRound
                color: Theme.bgInput
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingSmall

                    Canvas {
                        width: 12; height: 12
                        anchors.verticalCenter: parent.verticalCenter
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.strokeStyle = Theme.textTertiary
                            ctx.lineWidth = 1.3
                            ctx.lineCap = "round"
                            ctx.beginPath()
                            ctx.arc(5, 5, 4, 0, Math.PI * 2)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(8, 8)
                            ctx.lineTo(11, 11)
                            ctx.stroke()
                        }
                    }

                    Text {
                        text: currentKeyword !== "" ? currentKeyword : "搜索微博、用户"
                        font.pixelSize: Theme.fontSmall
                        font.family: Theme.fontFamily
                        color: currentKeyword !== "" ? Theme.textPrimary : Theme.textTertiary
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        width: parent.width - 20
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: virtualKeyboard.open(currentKeyword)
                }
            }

            // 搜索按钮
            Text {
                text: "搜索"
                font.pixelSize: Theme.fontSmall
                font.family: Theme.fontFamily
                color: Theme.primary
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    onClicked: virtualKeyboard.open(currentKeyword)
                }
            }
        }

        // 底部分割线
        Rectangle {
            width: parent.width; height: 1
            anchors.bottom: parent.bottom
            color: Theme.border
        }
    }

    // ── Tab 切换 ──
    Rectangle {
        id: tabBar
        anchors.top: searchBar.bottom
        width: parent.width
        height: 26
        color: Theme.bgHeader

        Row {
            anchors.fill: parent

            Repeater {
                model: ["微博", "用户"]

                delegate: Rectangle {
                    width: parent.width / 2
                    height: parent.height

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: Theme.fontNormal
                        font.family: Theme.fontFamily
                        color: searchTab === index ? Theme.primary : Theme.textSecondary
                        font.bold: searchTab === index
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 24
                        height: 2
                        color: searchTab === index ? Theme.primary : "transparent"
                        radius: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            searchTab = index
                            if (currentKeyword !== "") doSearch()
                        }
                    }
                }
            }
        }

        // 底部分割线
        Rectangle {
            width: parent.width; height: 1
            anchors.bottom: parent.bottom
            color: Theme.border
        }
    }

    // ── 微博搜索结果 ──
    ListView {
        id: statusResultView
        anchors.top: tabBar.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        visible: searchTab === 0
        cacheBuffer: 200

        model: controller ? controller.searchStatusModel() : null

        delegate: Components.StatusCard {
            width: statusResultView.width
            statusId: model.id
            text: model.text
            userName: model.userName
            userAvatar: model.userAvatar
            createdAt: model.createdAt
            repostsCount: model.repostsCount
            commentsCount: model.commentsCount
            attitudesCount: model.attitudesCount
            isLiked: model.isLiked
            picCount: model.picCount
            firstPic: model.firstPic
            hasVideo: model.hasVideo
            videoTitle: model.videoTitle
            videoCover: model.videoCover
            hasRetweeted: model.hasRetweeted
            retweetedText: model.retweetedText
            retweetedUserName: model.retweetedUserName

            onClicked: {
                root.navigateTo("detail", { statusId: model.id })
            }
            onVideoClicked: {
                root.navigateTo("video", {
                    statusId: model.id,
                    url: "",
                    title: model.videoTitle,
                    cover: model.videoCover
                })
            }
            onImageClicked: {
                if (controller) controller.viewer.prepareImageForViewer(url)
            }
        }
    }

    // ── 用户搜索结果 ──
    ListView {
        id: userResultView
        anchors.top: tabBar.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        visible: searchTab === 1
        cacheBuffer: 200

        model: controller ? controller.searchUserModel() : null

        delegate: Rectangle {
            width: userResultView.width
            height: 50
            color: Theme.bgCard

            Row {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingLarge
                anchors.rightMargin: Theme.spacingLarge
                spacing: Theme.spacingMedium

                Rectangle {
                    width: 36
                    height: 36
                    radius: Theme.radiusRound
                    color: Theme.bgTertiary
                    clip: true
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.fill: parent
                        source: model.avatarHd !== "" ? "image://weibo/" + encodeURIComponent(model.avatarHd) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                Column {
                    width: parent.width - 36 - Theme.spacingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingTiny

                    Row {
                        spacing: Theme.spacingSmall

                        Text {
                            text: model.screenName
                            font.pixelSize: Theme.fontNormal
                            font.family: Theme.fontFamily
                            font.bold: true
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                            width: parent.width - 30
                        }

                        Rectangle {
                            width: 26
                            height: 13
                            radius: Theme.radiusTiny
                            color: Theme.info
                            visible: model.verified

                            Text {
                                anchors.centerIn: parent
                                text: "V"
                                font.pixelSize: Theme.fontTiny
                                color: "white"
                                font.bold: true
                            }
                        }
                    }

                    Text {
                        text: model.description !== "" ? model.description : "暂无简介"
                        font.pixelSize: Theme.fontTiny
                        font.family: Theme.fontFamily
                        color: Theme.textTertiary
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: Theme.formatNumber(model.followersCount) + " 粉丝"
                        font.pixelSize: Theme.fontTiny
                        font.family: Theme.fontFamily
                        color: Theme.textTertiary
                    }
                }
            }

            // 底部分割线
            Rectangle {
                width: parent.width - Theme.spacingLarge * 2
                height: 1
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.hairline
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.navigateTo("user", {
                        userId: String(model.id),
                        userName: model.screenName
                    })
                }
            }
        }
    }

    // ── 加载指示 ──
    Components.LoadingIndicator {
        anchors.centerIn: parent
        visible: controller.isLoading
    }

    // ── 初始提示 ──
    Rectangle {
        anchors.fill: parent
        visible: currentKeyword === "" && !controller.isLoading
        color: Theme.bgPrimary

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacingLarge

            Canvas {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 40; height: 40
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = Theme.textTertiary
                    ctx.lineWidth = 2.5
                    ctx.lineCap = "round"
                    ctx.beginPath()
                    ctx.arc(17, 17, 12, 0, Math.PI * 2)
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.moveTo(26, 26)
                    ctx.lineTo(36, 36)
                    ctx.stroke()
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "输入关键词搜索"
                font.pixelSize: Theme.fontSmall
                font.family: Theme.fontFamily
                color: Theme.textTertiary
            }
        }
    }

    // ── 虚拟键盘 ──
    Components.VirtualKeyboardInput {
        id: virtualKeyboard
        onAccepted: {
            var keyword = content.trim()
            if (keyword !== "") {
                currentKeyword = keyword
                doSearch()
            }
        }
    }

    // ── 系统图片查看器 ──
    function openSystemImageViewer(localPath) {
        if (!localPath) return
        if (typeof imageViewer !== "undefined" && imageViewer) {
            imageViewer.open(localPath)
            id_pop_container.show("qrc:/qml/audiopages/FileManagerImageViewer.qml")
        } else {
            root.showToast("图片查看器不可用")
        }
    }

    Components.PopupStack { id: id_pop_container }

    Connections {
        target: controller
        ignoreUnknownSignals: true
        function onCommentImageReadyForViewer(localPath) {
            searchPage.openSystemImageViewer(localPath)
        }
    }

    function doSearch() {
        var keyword = currentKeyword.trim()
        if (keyword === "") return
        if (controller) {
            if (searchTab === 0) {
                controller.searchStatus(keyword, 1)
            } else {
                controller.searchUser(keyword, 1)
            }
        }
    }

    function searchWithKeyword(keyword) {
        currentKeyword = keyword
        doSearch()
    }

    Connections {
        target: root
        function onCurrentPageChanged() {
            if (root.currentPage === "search" && root.searchKeyword !== "") {
                searchWithKeyword(root.searchKeyword)
                root.searchKeyword = ""
            }
        }
    }
}
