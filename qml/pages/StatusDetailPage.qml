import QtQuick 2.12
import WeiboPlugin 1.0
import "../components" as Components

Rectangle {
    id: statusDetailPage
    color: Theme.bgPrimary

    // ── 标题栏 ──
    Components.TitleBar {
        id: titleBar
        title: "微博详情"
        showBack: true
        onBackClicked: root.navigateBack()
    }

    // ── 内容滚动区 ──
    Flickable {
        id: contentFlick
        anchors.top: titleBar.bottom
        anchors.bottom: actionBar.top
        width: parent.width
        contentHeight: contentColumn.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentColumn
            width: parent.width
            spacing: 0

            // 微博卡片
            Components.StatusCard {
                width: parent.width
                statusId: controller.currentStatusId
                text: controller.currentStatusText
                userName: controller.currentStatusUser
                userAvatar: controller.currentStatusAvatar
                createdAt: ""
                repostsCount: controller.currentStatusReposts
                commentsCount: controller.currentStatusComments
                attitudesCount: controller.currentStatusLikes
                isLiked: controller.currentStatusLiked
                hasVideo: controller.currentStatusHasVideo
                videoCover: controller.currentStatusVideoCover
                videoDuration: controller.currentStatusVideoDuration
                showActionBar: false

                onLikeClicked: {
                    if (controller) {
                        controller.toggleStatusLike(controller.currentStatusId, !controller.currentStatusLiked)
                    }
                }
                onVideoClicked: {
                    root.navigateTo("video", {
                        statusId: controller.currentStatusId,
                        url: controller.currentStatusVideoUrl,
                        title: "",
                        cover: controller.currentStatusVideoCover
                    })
                }
                onImageClicked: {
                    if (controller) controller.viewer.prepareImageForViewer(url)
                }
            }

            // 分割线
            Rectangle {
                width: parent.width
                height: 4
                color: Theme.bgPrimary
            }

            // 评论区标题
            Rectangle {
                width: parent.width
                height: 24
                color: Theme.bgSecondary

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingLarge
                    anchors.rightMargin: Theme.spacingLarge

                    Text {
                        text: "评论 " + controller.currentStatusComments
                        font.pixelSize: Theme.fontNormal
                        font.family: Theme.fontFamily
                        font.bold: true
                        color: Theme.textPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "查看全部 ›"
                        font.pixelSize: Theme.fontTiny
                        font.family: Theme.fontFamily
                        color: Theme.textLink

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            onClicked: {
                                root.navigateTo("comments", {
                                    statusId: controller.currentStatusId,
                                    title: "评论"
                                })
                            }
                        }
                    }
                }
            }

            // 评论预览
            Repeater {
                model: controller ? controller.commentListModel() : null

                delegate: Components.CommentCard {
                    width: parent.width
                    commentId: String(model.id)
                    text: model.text
                    userName: model.userName
                    userAvatar: model.userAvatar
                    createdAt: model.createdAt
                    likeCount: model.likeCount
                    liked: model.liked
                    replyCount: model.replyCount
                    hasReplyTo: model.hasReplyTo
                    replyToText: model.replyToText
                    replyToUserName: model.replyToUserName
                    picUrl: model.picUrl

                    onLikeClicked: {
                        if (controller) controller.toggleCommentLike(String(model.id), !model.liked)
                    }
                    onImageClicked: {
                        if (controller) controller.viewer.prepareImageForViewer(url)
                    }
                }
            }

            // 底部留白
            Rectangle {
                width: parent.width
                height: Theme.spacingLarge
                color: "transparent"
            }
        }
    }

    // ── 底部操作栏 ──
    Rectangle {
        id: actionBar
        anchors.bottom: parent.bottom
        width: parent.width
        height: 32
        color: Theme.bgHeader
        z: 10

        Row {
            anchors.fill: parent

            // 评论
            Item {
                width: parent.width / 4
                height: parent.height

                Column {
                    anchors.centerIn: parent
                    spacing: 0

                    Canvas {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 15; height: 15
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.strokeStyle = Theme.textSecondary
                            ctx.lineWidth = 1.4
                            ctx.lineCap = "round"
                            ctx.lineJoin = "round"
                            ctx.beginPath()
                            ctx.arc(7.5, 6.5, 5, 0, Math.PI * 2)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(4.5, 10.5)
                            ctx.lineTo(2, 14)
                            ctx.lineTo(6.5, 11)
                            ctx.stroke()
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Theme.formatNumber(controller.currentStatusComments)
                        font.pixelSize: Theme.fontTiny
                        font.family: Theme.fontFamily
                        color: Theme.textTertiary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.navigateTo("comments", {
                            statusId: controller.currentStatusId,
                            title: "评论"
                        })
                    }
                }
            }

            // 转发
            Item {
                width: parent.width / 4
                height: parent.height

                Column {
                    anchors.centerIn: parent
                    spacing: 0

                    Canvas {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 15; height: 15
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.strokeStyle = Theme.textSecondary
                            ctx.lineWidth = 1.4
                            ctx.lineCap = "round"
                            ctx.lineJoin = "round"
                            ctx.beginPath()
                            ctx.moveTo(7, 2)
                            ctx.lineTo(12.5, 6.5)
                            ctx.lineTo(7, 11)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(11.5, 6.5)
                            ctx.lineTo(2.5, 6.5)
                            ctx.lineTo(2.5, 12.5)
                            ctx.stroke()
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Theme.formatNumber(controller.currentStatusReposts)
                        font.pixelSize: Theme.fontTiny
                        font.family: Theme.fontFamily
                        color: Theme.textTertiary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.showToast("转发功能开发中")
                }
            }

            // 点赞
            Item {
                width: parent.width / 4
                height: parent.height

                Column {
                    anchors.centerIn: parent
                    spacing: 0

                    Canvas {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 15; height: 15
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            if (controller.currentStatusLiked) {
                                ctx.fillStyle = Theme.primary
                                ctx.beginPath()
                                ctx.moveTo(7.5, 13)
                                ctx.bezierCurveTo(1, 9, 1, 3.5, 4.5, 2.5)
                                ctx.bezierCurveTo(6, 2, 7.5, 3, 7.5, 4.2)
                                ctx.bezierCurveTo(7.5, 3, 9, 2, 10.5, 2.5)
                                ctx.bezierCurveTo(14, 3.5, 14, 9, 7.5, 13)
                                ctx.fill()
                            } else {
                                ctx.strokeStyle = Theme.textSecondary
                                ctx.lineWidth = 1.4
                                ctx.beginPath()
                                ctx.moveTo(7.5, 12.5)
                                ctx.bezierCurveTo(2, 9, 2, 4, 4.5, 3)
                                ctx.bezierCurveTo(5.8, 2.5, 7.5, 3.3, 7.5, 4.5)
                                ctx.bezierCurveTo(7.5, 3.3, 9.2, 2.5, 10.5, 3)
                                ctx.bezierCurveTo(13, 4, 13, 9, 7.5, 12.5)
                                ctx.stroke()
                            }
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Theme.formatNumber(controller.currentStatusLikes)
                        font.pixelSize: Theme.fontTiny
                        font.family: Theme.fontFamily
                        color: controller.currentStatusLiked ? Theme.primary : Theme.textTertiary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (controller) {
                            controller.toggleStatusLike(controller.currentStatusId, !controller.currentStatusLiked)
                        }
                    }
                }
            }

            // 收藏
            Item {
                width: parent.width / 4
                height: parent.height

                Column {
                    anchors.centerIn: parent
                    spacing: 0

                    Canvas {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 15; height: 15
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.strokeStyle = Theme.textSecondary
                            ctx.lineWidth = 1.4
                            ctx.lineCap = "round"
                            ctx.lineJoin = "round"
                            ctx.beginPath()
                            ctx.moveTo(7.5, 13)
                            ctx.lineTo(2.5, 8.5)
                            ctx.bezierCurveTo(1, 7, 1, 4.5, 2.5, 3)
                            ctx.bezierCurveTo(4, 1.5, 6.5, 1.5, 7.5, 3)
                            ctx.bezierCurveTo(8.5, 1.5, 11, 1.5, 12.5, 3)
                            ctx.bezierCurveTo(14, 4.5, 14, 7, 12.5, 8.5)
                            ctx.lineTo(7.5, 13)
                            ctx.stroke()
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "收藏"
                        font.pixelSize: Theme.fontTiny
                        font.family: Theme.fontFamily
                        color: Theme.textTertiary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.showToast("收藏功能开发中")
                }
            }
        }

        // 顶部分割线
        Rectangle {
            width: parent.width; height: 1
            anchors.top: parent.bottom
            color: Theme.border
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
            statusDetailPage.openSystemImageViewer(localPath)
        }
    }

    Connections {
        target: root
        function onCurrentPageChanged() {
            if (root.currentPage === "detail" && root.detailStatusId !== "") {
                if (controller) {
                    controller.loadStatusDetail(root.detailStatusId)
                    controller.loadComments(root.detailStatusId, 1)
                }
            }
        }
    }
}
