import QtQuick 2.12
import WeiboPlugin 1.0
import "../components" as Components

Rectangle {
    id: commentsPage
    color: Theme.bgPrimary

    property string currentStatusId: ""
    property int currentPage: 1

    // ── 标题栏 ──
    Components.TitleBar {
        id: titleBar
        title: root.commentsTitle !== "" ? root.commentsTitle : "评论"
        showBack: true
        onBackClicked: root.navigateBack()
    }

    // ── 评论列表 ──
    ListView {
        id: commentsListView
        anchors.top: titleBar.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: 200

        model: controller ? controller.commentListModel() : null

        delegate: Components.CommentCard {
            width: commentsListView.width
            commentId: String(model.id)
            text: model.text
            userName: model.userName
            userAvatar: model.userAvatar
            createdAt: model.createdAt
            source: model.source
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
            onReplyClicked: {
                root.showToast("回复功能开发中")
            }
            onUserClicked: {
                root.navigateTo("user", {
                    userId: "",
                    userName: model.userName
                })
            }
            onImageClicked: {
                if (controller) controller.viewer.prepareImageForViewer(url)
            }
        }

        // 加载更多
        onAtYEndChanged: {
            if (atYEnd && !controller.isLoading) {
                currentPage++
                if (controller && currentStatusId !== "") {
                    controller.loadComments(currentStatusId, currentPage)
                }
            }
        }
    }

    // ── 加载指示 ──
    Components.LoadingIndicator {
        anchors.centerIn: parent
        visible: controller.isLoading && controller.commentListModel().rowCount() === 0
    }

    // ── 空状态 ──
    Components.ErrorOverlay {
        anchors.fill: parent
        visible: !controller.isLoading && controller.commentListModel().rowCount() === 0
        errorText: "暂无评论，快来抢沙发"
        retryText: "刷新"
        onRetry: {
            currentPage = 1
            if (controller && currentStatusId !== "") {
                controller.commentListModel().clear()
                controller.loadComments(currentStatusId, 1)
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
            commentsPage.openSystemImageViewer(localPath)
        }
    }

    Connections {
        target: root
        function onCurrentPageChanged() {
            if (root.currentPage === "comments" && root.commentsStatusId !== "") {
                currentStatusId = root.commentsStatusId
                currentPage = 1
                if (controller) {
                    controller.commentListModel().clear()
                    controller.loadComments(currentStatusId, 1)
                }
            }
        }
    }
}
