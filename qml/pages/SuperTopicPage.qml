import QtQuick 2.12
import WeiboPlugin 1.0
import "../components" as Components

Rectangle {
    id: superTopicPage
    color: Theme.bgPrimary

    // ── 标题栏 ──
    Rectangle {
        id: headerBar
        width: parent.width
        height: 34
        color: Theme.bgHeader

        Row {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingLarge
            anchors.rightMargin: Theme.spacingLarge

            Text {
                text: "超话签到"
                font.pixelSize: Theme.fontMedium
                font.family: Theme.fontFamily
                font.bold: true
                color: Theme.textPrimary
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { width: 1; height: 1 }

            // 全部签到按钮
            Rectangle {
                id: batchCheckinBtn
                width: 64
                height: 22
                radius: Theme.radiusRound
                color: Theme.primary
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: controller.loggedIn

                Text {
                    anchors.centerIn: parent
                    text: "全部签到"
                    font.pixelSize: Theme.fontTiny
                    font.family: Theme.fontFamily
                    color: "#FFFFFF"
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (controller) controller.superTopicBatchCheckin()
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

    // ── 未登录提示 ──
    Rectangle {
        id: notLoggedIn
        anchors.top: headerBar.bottom
        width: parent.width
        height: parent.height - headerBar.height
        color: Theme.bgPrimary
        visible: !controller.loggedIn

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacingLarge

            Canvas {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 48; height: 48
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.fillStyle = Theme.primarySoft
                    ctx.beginPath()
                    ctx.arc(24, 24, 22, 0, Math.PI * 2)
                    ctx.fill()
                    ctx.fillStyle = Theme.primary
                    ctx.font = "bold 24px sans-serif"
                    ctx.textAlign = "center"
                    ctx.textBaseline = "middle"
                    ctx.fillText("⭐", 24, 24)
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "登录后查看超话列表"
                font.pixelSize: Theme.fontSmall
                font.family: Theme.fontFamily
                color: Theme.textSecondary
            }

            Rectangle {
                width: 80
                height: 26
                radius: Theme.radiusMedium
                color: Theme.primary
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    anchors.centerIn: parent
                    text: "去登录"
                    font.pixelSize: Theme.fontSmall
                    font.family: Theme.fontFamily
                    color: "#FFFFFF"
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.navIndex = 3
                        root.currentPage = "profile"
                        root.pageStack = []
                    }
                }
            }
        }
    }

    // ── 超话列表 ──
    ListView {
        id: superTopicList
        anchors.top: headerBar.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        visible: controller.loggedIn
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: 200

        model: controller ? controller.superTopicModel() : null

        delegate: Components.SuperTopicCard {
            width: superTopicList.width
            topicId: model.topicId
            title: model.title
            cover: model.cover
            level: model.level
            checkedIn: model.checkedIn
            continuousDays: model.continuousDays

            onCheckinClicked: {
                if (controller) controller.superTopicCheckin(model.topicId)
            }
        }

        // 下拉刷新
        RefreshIndicator {
            id: refreshIndicator
            width: parent.width
            height: 30
            y: -30
            visible: refreshing || active

            property bool refreshing: false

            Text {
                anchors.centerIn: parent
                text: refreshing ? "刷新中..." : "下拉刷新"
                font.pixelSize: Theme.fontTiny
                font.family: Theme.fontFamily
                color: Theme.textTertiary
            }

            onReleased: {
                if (active && !refreshing) {
                    refreshing = true
                    if (controller) controller.loadSuperTopicList(1)
                    Timer {
                        interval: 800
                        onTriggered: refreshIndicator.refreshing = false
                    }
                }
            }
        }
    }

    // ── 加载指示 ──
    Components.LoadingIndicator {
        anchors.centerIn: parent
        visible: controller.isLoading && controller.loggedIn && controller.superTopicModel().rowCount() === 0
    }

    Component.onCompleted: {
        if (controller && controller.loggedIn) controller.loadSuperTopicList(1)
    }

    Connections {
        target: controller
        function onLoginStateChanged() {
            if (controller.loggedIn && controller.superTopicModel().rowCount() === 0) {
                controller.loadSuperTopicList(1)
            }
        }
    }
}
