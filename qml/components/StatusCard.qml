import QtQuick 2.12
import WeiboPlugin 1.0
import ".."

Rectangle {
    id: statusCard
    width: parent.width
    color: Theme.bgCard
    radius: 0

    property string statusId: ""
    property string text: ""
    property string userName: ""
    property string userAvatar: ""
    property string createdAt: ""
    property string source: ""
    property int repostsCount: 0
    property int commentsCount: 0
    property int attitudesCount: 0
    property bool isLiked: false
    property int picCount: 0
    property string firstPic: ""
    property bool hasVideo: false
    property string videoTitle: ""
    property string videoCover: ""
    property int videoDuration: 0
    property bool hasRetweeted: false
    property string retweetedText: ""
    property string retweetedUserName: ""
    property bool showActionBar: true

    signal clicked()
    signal userClicked()
    signal likeClicked()
    signal commentClicked()
    signal repostClicked()
    signal videoClicked()
    signal imageClicked(string url)

    implicitHeight: contentColumn.height + (showActionBar ? actionBar.height : 0) + Theme.spacingLarge * 2

    Column {
        id: contentColumn
        width: parent.width - Theme.spacingLarge * 2
        anchors.centerIn: parent
        spacing: Theme.spacingMedium

        // ── 用户信息行 ──
        Row {
            width: parent.width
            spacing: Theme.spacingMedium
            height: Theme.avatarSize

            // 头像
            Rectangle {
                width: Theme.avatarSize
                height: Theme.avatarSize
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
                    onClicked: statusCard.userClicked()
                }
            }

            Column {
                width: parent.width - Theme.avatarSize - Theme.spacingMedium
                spacing: Theme.spacingTiny

                Row {
                    width: parent.width
                    spacing: Theme.spacingSmall

                    Text {
                        text: userName
                        font.pixelSize: Theme.fontNormal
                        font.family: Theme.fontFamily
                        font.bold: true
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        width: parent.width - 60

                        MouseArea {
                            anchors.fill: parent
                            onClicked: statusCard.userClicked()
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        text: createdAt
                        font.pixelSize: Theme.fontTiny
                        font.family: Theme.fontFamily
                        color: Theme.textTertiary
                    }
                }

                Text {
                    text: source !== "" ? "来自 " + source : ""
                    font.pixelSize: Theme.fontTiny
                    font.family: Theme.fontFamily
                    color: Theme.textTertiary
                    visible: source !== ""
                }
            }
        }

        // ── 正文 ──
        Text {
            width: parent.width
            text: text
            font.pixelSize: Theme.fontBody
            font.family: Theme.fontFamily
            color: Theme.textPrimary
            wrapMode: Text.Wrap
            lineHeight: 1.35
            maximumLineCount: 5
            elide: Text.ElideRight
            visible: text !== ""
        }

        // ── 图片/视频区域 ──
        Item {
            width: parent.width
            height: {
                if (hasVideo) return 64
                if (picCount > 0) return picCount > 1 ? 56 : 64
                return 0
            }
            visible: hasVideo || picCount > 0

            // 视频封面
            Rectangle {
                anchors.fill: parent
                visible: hasVideo
                color: "#000000"
                radius: Theme.radiusSmall
                clip: true

                Image {
                    anchors.fill: parent
                    source: videoCover !== "" ? "image://weibo/" + encodeURIComponent(videoCover) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: 0.75
                }

                // 播放按钮
                Rectangle {
                    anchors.centerIn: parent
                    width: 26
                    height: 26
                    radius: Theme.radiusRound
                    color: "#CC000000"

                    Canvas {
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.fillStyle = "#FFFFFF"
                            ctx.beginPath()
                            ctx.moveTo(3, 1)
                            ctx.lineTo(3, 11)
                            ctx.lineTo(11, 6)
                            ctx.closePath()
                            ctx.fill()
                        }
                    }
                }

                // 时长
                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 3
                    width: 32
                    height: 12
                    radius: Theme.radiusTiny
                    color: "#80000000

                    Text {
                        anchors.centerIn: parent
                        text: videoDuration > 0 ? Math.floor(videoDuration / 60) + ":" + (videoDuration % 60).toString().padStart(2, '0') : ""
                        color: "#FFFFFF"
                        font.pixelSize: Theme.fontTiny
                        font.family: Theme.fontFamily
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 3
                    text: videoTitle
                    color: "#FFFFFF"
                    font.pixelSize: Theme.fontTiny
                    font.family: Theme.fontFamily
                    elide: Text.ElideRight
                    width: parent.width - 40
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: statusCard.videoClicked()
                }
            }

            // 单张图片
            Image {
                anchors.fill: parent
                visible: !hasVideo && picCount > 0
                source: firstPic !== "" ? "image://weibo/" + encodeURIComponent(firstPic) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                radius: Theme.radiusSmall
                clip: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: statusCard.imageClicked(firstPic)
                }
            }

            // 多图角标
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 3
                width: 28
                height: 14
                radius: Theme.radiusTiny
                color: "#80000000"
                visible: picCount > 1

                Text {
                    anchors.centerIn: parent
                    text: picCount + "图"
                    color: "#FFFFFF"
                    font.pixelSize: Theme.fontTiny
                    font.family: Theme.fontFamily
                }
            }
        }

        // ── 转发引用 ──
        Rectangle {
            width: parent.width
            visible: hasRetweeted && retweetedText !== ""
            color: Theme.bgTertiary
            radius: Theme.radiusSmall
            implicitHeight: retweetColumn.height + Theme.spacingMedium * 2

            Column {
                id: retweetColumn
                width: parent.width - Theme.spacingMedium * 2
                anchors.centerIn: parent
                spacing: Theme.spacingTiny

                Text {
                    text: "@" + retweetedUserName
                    font.pixelSize: Theme.fontSmall
                    font.family: Theme.fontFamily
                    color: Theme.textLink
                    font.bold: true
                }

                Text {
                    width: parent.width
                    text: retweetedText
                    font.pixelSize: Theme.fontSmall
                    font.family: Theme.fontFamily
                    color: Theme.textSecondary
                    wrapMode: Text.Wrap
                    lineHeight: 1.3
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }
        }
    }

    // ── 操作栏 ──
    Rectangle {
        id: actionBar
        width: parent.width
        height: 24
        anchors.bottom: parent.bottom
        color: "transparent"
        visible: showActionBar

        Row {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingLarge
            anchors.rightMargin: Theme.spacingLarge

            // 转发
            Item {
                width: parent.width / 3
                height: parent.height

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingTiny

                    Canvas {
                        width: 13; height: 13
                        anchors.verticalCenter: parent.verticalCenter
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.strokeStyle = Theme.textTertiary
                            ctx.lineWidth = 1.3
                            ctx.lineCap = "round"
                            ctx.lineJoin = "round"
                            ctx.beginPath()
                            ctx.moveTo(6, 2)
                            ctx.lineTo(11, 6)
                            ctx.lineTo(6, 10)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(10, 6)
                            ctx.lineTo(2, 6)
                            ctx.lineTo(2, 11)
                            ctx.stroke()
                        }
                    }
                    Text {
                        text: Theme.formatNumber(repostsCount)
                        font.pixelSize: Theme.fontTiny
                        font.family: Theme.fontFamily
                        color: Theme.textTertiary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: statusCard.repostClicked()
                }
            }

            // 评论
            Item {
                width: parent.width / 3
                height: parent.height

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingTiny

                    Canvas {
                        width: 13; height: 13
                        anchors.verticalCenter: parent.verticalCenter
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.strokeStyle = Theme.textTertiary
                            ctx.lineWidth = 1.3
                            ctx.lineCap = "round"
                            ctx.lineJoin = "round"
                            ctx.beginPath()
                            ctx.arc(6.5, 5.5, 4.5, 0, Math.PI * 2)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(4, 9)
                            ctx.lineTo(2, 12)
                            ctx.lineTo(5.5, 9.5)
                            ctx.stroke()
                        }
                    }
                    Text {
                        text: Theme.formatNumber(commentsCount)
                        font.pixelSize: Theme.fontTiny
                        font.family: Theme.fontFamily
                        color: Theme.textTertiary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: statusCard.commentClicked()
                }
            }

            // 点赞
            Item {
                width: parent.width / 3
                height: parent.height

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingTiny

                    Canvas {
                        width: 13; height: 13
                        anchors.verticalCenter: parent.verticalCenter
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            if (isLiked) {
                                ctx.fillStyle = Theme.primary
                                ctx.beginPath()
                                ctx.moveTo(6.5, 11)
                                ctx.bezierCurveTo(1, 7.5, 1, 3, 4, 2)
                                ctx.bezierCurveTo(5.5, 1.5, 6.5, 2.5, 6.5, 3.5)
                                ctx.bezierCurveTo(6.5, 2.5, 7.5, 1.5, 9, 2)
                                ctx.bezierCurveTo(12, 3, 12, 7.5, 6.5, 11)
                                ctx.fill()
                            } else {
                                ctx.strokeStyle = Theme.textTertiary
                                ctx.lineWidth = 1.3
                                ctx.beginPath()
                                ctx.moveTo(6.5, 10.5)
                                ctx.bezierCurveTo(1.5, 7.5, 1.5, 3.5, 4, 2.5)
                                ctx.bezierCurveTo(5.3, 2, 6.5, 2.8, 6.5, 3.8)
                                ctx.bezierCurveTo(6.5, 2.8, 7.7, 2, 9, 2.5)
                                ctx.bezierCurveTo(11.5, 3.5, 11.5, 7.5, 6.5, 10.5)
                                ctx.stroke()
                            }
                        }
                    }
                    Text {
                        text: Theme.formatNumber(attitudesCount)
                        font.pixelSize: Theme.fontTiny
                        font.family: Theme.fontFamily
                        color: isLiked ? Theme.primary : Theme.textTertiary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: statusCard.likeClicked()
                }
            }
        }
    }

    // ── 点击区域 ──
    MouseArea {
        anchors.fill: parent
        onClicked: statusCard.clicked()
    }
}
