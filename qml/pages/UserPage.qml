import QtQuick 2.12
import WeiboPlugin 1.0
import "../components" as Components

Rectangle {
    id: userPage
    color: Theme.bgPrimary

    property string currentUserId: ""
    property string currentUserName: ""
    property int userTabIndex: 0

    // ── 标题栏 ──
    Components.TitleBar {
        id: titleBar
        title: currentUserName !== "" ? currentUserName : "用户主页"
        showBack: true
        onBackClicked: root.navigateBack()
    }

    // ── 用户信息区 ──
    Rectangle {
        id: userInfoArea
        anchors.top: titleBar.bottom
        width: parent.width
        height: 64
        color: Theme.bgHeader

        Row {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingLarge
            anchors.rightMargin: Theme.spacingLarge
            spacing: Theme.spacingMedium

            Rectangle {
                width: 44
                height: 44
                radius: Theme.radiusRound
                color: Theme.bgTertiary
                clip: true
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.fill: parent
                    source: ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    id: userAvatar
                }
            }

            Column {
                width: parent.width - 44 - Theme.spacingMedium - 60
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingTiny

                Text {
                    id: userNameText
                    text: currentUserName
                    font.pixelSize: Theme.fontLarge
                    font.family: Theme.fontFamily
                    font.bold: true
                    color: Theme.textPrimary
                }

                Text {
                    id: userDescText
                    text: "加载中..."
                    font.pixelSize: Theme.fontTiny
                    font.family: Theme.fontFamily
                    color: Theme.textTertiary
                    elide: Text.ElideRight
                    width: parent.width
                }

                Row {
                    spacing: Theme.spacingLarge

                    Text {
                        id: userStatusesText
                        text: "0 微博"
                        font.pixelSize: Theme.fontTiny
                        font.family: Theme.fontFamily
                        color: Theme.textSecondary
                    }
                    Text {
                        id: userFollowingText
                        text: "0 关注"
                        font.pixelSize: Theme.fontTiny
                        font.family: Theme.fontFamily
                        color: Theme.textSecondary
                    }
                    Text {
                        id: userFollowersText
                        text: "0 粉丝"
                        font.pixelSize: Theme.fontTiny
                        font.family: Theme.fontFamily
                        color: Theme.textSecondary
                    }
                }
            }

            // 关注按钮
            Rectangle {
                id: followBtn
                width: 52
                height: 24
                radius: Theme.radiusMedium
                color: Theme.primary
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: currentUserId !== "" && currentUserId !== controller.userId

                Text {
                    id: followBtnText
                    anchors.centerIn: parent
                    text: "关注"
                    font.pixelSize: Theme.fontTiny
                    font.family: Theme.fontFamily
                    color: "#FFFFFF"
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (controller) {
                            var isFollowing = followBtnText.text === "已关注"
                            controller.toggleFollow(currentUserId, !isFollowing)
                            followBtnText.text = isFollowing ? "关注" : "已关注"
                            followBtn.color = isFollowing ? Theme.primary : Theme.bgTertiary
                            followBtnText.color = isFollowing ? "#FFFFFF" : Theme.textSecondary
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

    // ── Tab 切换 ──
    Rectangle {
        id: tabBar
        anchors.top: userInfoArea.bottom
        width: parent.width
        height: 26
        color: Theme.bgHeader

        Row {
            anchors.fill: parent

            Repeater {
                model: ["微博", "相册", "信息"]

                delegate: Rectangle {
                    width: parent.width / 3
                    height: parent.height

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: Theme.fontSmall
                        font.family: Theme.fontFamily
                        color: userTabIndex === index ? Theme.primary : Theme.textSecondary
                        font.bold: userTabIndex === index
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 20
                        height: 2
                        color: userTabIndex === index ? Theme.primary : "transparent"
                        radius: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: userTabIndex = index
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

    // ── 微博列表 ──
    ListView {
        id: userStatusListView
        anchors.top: tabBar.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        visible: userTabIndex === 0
        cacheBuffer: 200

        model: controller ? controller.userStatusModel() : null

        delegate: Components.StatusCard {
            width: userStatusListView.width
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

    // ── 相册占位 ──
    Rectangle {
        anchors.top: tabBar.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        visible: userTabIndex === 1
        color: Theme.bgPrimary

        Text {
            anchors.centerIn: parent
            text: "相册功能开发中"
            font.pixelSize: Theme.fontSmall
            font.family: Theme.fontFamily
            color: Theme.textTertiary
        }
    }

    // ── 信息占位 ──
    Rectangle {
        anchors.top: tabBar.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        visible: userTabIndex === 2
        color: Theme.bgPrimary

        Text {
            anchors.centerIn: parent
            text: "用户信息功能开发中"
            font.pixelSize: Theme.fontSmall
            font.family: Theme.fontFamily
            color: Theme.textTertiary
        }
    }

    // ── 加载指示 ──
    Components.LoadingIndicator {
        anchors.centerIn: parent
        visible: controller.isLoading
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
            userPage.openSystemImageViewer(localPath)
        }
    }

    Connections {
        target: root
        function onCurrentPageChanged() {
            if (root.currentPage === "user" && root.profileUserId !== "") {
                currentUserId = root.profileUserId
                currentUserName = root.profileUserName
                userTabIndex = 0
                if (controller) {
                    controller.userStatusModel().clear()
                    controller.loadUserStatuses(currentUserId, 1)
                }
            }
        }
    }
}
