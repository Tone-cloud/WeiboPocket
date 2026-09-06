import QtQuick 2.12
import WeiboPlugin 1.0
import ".."

Rectangle {
    id: commentCard
    width: parent.width
    color: Theme.bgCard
    radius: 0

    property string commentId: ""
    property string text: ""
    property string userName: ""
    property string userAvatar: ""
    property string createdAt: ""
    property string source: ""
    property int likeCount: 0
    property bool liked: false
    property int replyCount: 0
    property bool hasReplyTo: false
    property string replyToText: ""
    property string replyToUserName: ""
    property string picUrl: ""

    signal clicked()
    signal userClicked()
    signal likeClicked()
    signal replyClicked()
    signal imageClicked(string url)

    implicitHeight: contentColumn.height + Theme.spacingLarge * 2

    Column {
        id: contentColumn
        width: parent.width - Theme.spacingLarge * 2
        anchors.centerIn: parent
        spacing: Theme.spacingSmall

        // ── 用户信息行 ──
        Row {
            width: parent.width
            spacing: Theme.spacingMedium
            height: Theme.avatarSizeSmall

            // 头像
            Rectangle {
                width: Theme.avatarSizeSmall
                height: Theme.avatarSizeSmall
                radius: Theme.radiusRound
                color: Theme.bgTertiary
                clip: true

                Image {
                    anchors.fill: parent
                    source: userAvatar !== "" ? "image://weibo/" + encodeURIComponent(userAvatar) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: commentCard.userClicked()
                }
            }

            Column {
                width: parent.width - Theme.avatarSizeSmall - Theme.spacingMedium - 50
                spacing: Theme.spacingTiny

                Text {
                    text: userName
                    font.pixelSize: Theme.fontSmall
                    font.family: Theme.fontFamily
                    font.bold: true
                    color: Theme.textSecondary
                    elide: Text.ElideRight
                    width: parent.width

                    MouseArea {
                        anchors.fill: parent
                        onClicked: commentCard.userClicked()
                    }
                }

                Text {
                    text: createdAt + (source !== "" ? " · " + source : "")
                    font.pixelSize: Theme.fontTiny
                    font.family: Theme.fontFamily
                    color: Theme.textTertiary
                }
            }

            // 点赞按钮
            Rectangle {
                width: 50
                height: Theme.avatarSizeSmall
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingTiny

                    Canvas {
                        width: 12; height: 12
                        anchors.verticalCenter: parent.verticalCenter
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            if (liked) {
                                ctx.fillStyle = Theme.primary
                                ctx.beginPath()
                                ctx.moveTo(6, 10.5)
                                ctx.bezierCurveTo(1, 7.5, 1, 3, 3.5, 2.2)
                                ctx.bezierCurveTo(4.8, 1.8, 6, 2.5, 6, 3.5)
                                ctx.bezierCurveTo(6, 2.5, 7.2, 1.8, 8.5, 2.2)
                                ctx.bezierCurveTo(11, 3, 11, 7.5, 6, 10.5)
                                ctx.fill()
                            } else {
                                ctx.strokeStyle = Theme.textTertiary
                                ctx.lineWidth = 1.2
                                ctx.beginPath()
                                ctx.moveTo(6, 10)
                                ctx.bezierCurveTo(1.5, 7.2, 1.5, 3.5, 3.5, 2.5)
                                ctx.bezierCurveTo(4.7, 2, 6, 2.8, 6, 3.8)
                                ctx.bezierCurveTo(6, 2.8, 7.3, 2, 8.5, 2.5)
                                ctx.bezierCurveTo(10.5, 3.5, 10.5, 7.2, 6, 10)
                                ctx.stroke()
                            }
                        }
                    }
                    Text {
                        text: likeCount > 0 ? Theme.formatNumber(likeCount) : "赞"
                        font.pixelSize: Theme.fontTiny
                        font.family: Theme.fontFamily
                        color: liked ? Theme.primary : Theme.textTertiary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: commentCard.likeClicked()
                }
            }
        }

        // ── 评论正文 ──
        Text {
            width: parent.width
            text: text
            font.pixelSize: Theme.fontBody
            font.family: Theme.fontFamily
            color: Theme.textPrimary
            wrapMode: Text.Wrap
            lineHeight: 1.35
        }

        // ── 评论图片 ──
        Rectangle {
            width: 64
            height: 64
            radius: Theme.radiusSmall
            color: Theme.bgTertiary
            clip: true
            visible: picUrl !== ""

            Image {
                anchors.fill: parent
                source: picUrl !== "" ? "image://weibo/" + encodeURIComponent(picUrl) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: commentCard.imageClicked(picUrl)
            }
        }

        // ── 回复引用 ──
        Rectangle {
            width: parent.width
            visible: hasReplyTo && replyToText !== ""
            color: Theme.bgTertiary
            radius: Theme.radiusTiny
            implicitHeight: replyColumn.height + Theme.spacingSmall * 2

            Column {
                id: replyColumn
                width: parent.width - Theme.spacingSmall * 2
                anchors.centerIn: parent
                spacing: Theme.spacingTiny

                Text {
                    text: "@" + replyToUserName
                    font.pixelSize: Theme.fontTiny
                    font.family: Theme.fontFamily
                    color: Theme.textLink
                    font.bold: true
                }

                Text {
                    width: parent.width
                    text: replyToText
                    font.pixelSize: Theme.fontTiny
                    font.family: Theme.fontFamily
                    color: Theme.textSecondary
                    wrapMode: Text.Wrap
                    lineHeight: 1.3
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }
        }

        // ── 回复入口 ──
        Text {
            text: replyCount > 0 ? "查看 " + replyCount + " 条回复" : "回复"
            font.pixelSize: Theme.fontTiny
            font.family: Theme.fontFamily
            color: Theme.textLink

            MouseArea {
                anchors.fill: parent
                onClicked: commentCard.replyClicked()
            }
        }
    }

    // ── 底部分割线 ──
    Rectangle {
        width: parent.width - Theme.spacingLarge * 2
        height: 1
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        color: Theme.hairline
    }

    MouseArea {
        anchors.fill: parent
        onClicked: commentCard.clicked()
    }
}
