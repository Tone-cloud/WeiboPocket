import QtQuick 2.12
import WeiboPlugin 1.0
import "../components" as Components

Rectangle {
    id: homePage
    color: Theme.bgPrimary

    // ── 顶部搜索栏 ──
    Rectangle {
        id: searchBar
        width: parent.width
        height: 32
        color: Theme.bgHeader

        Row {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingLarge
            anchors.rightMargin: Theme.spacingLarge
            spacing: Theme.spacingMedium

            // Logo
            Text {
                text: "微博"
                font.pixelSize: Theme.fontTitle
                font.family: Theme.fontFamily
                font.bold: true
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            // 搜索框
            Rectangle {
                width: parent.width - 50 - Theme.spacingMedium
                height: 22
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
                        text: "搜索微博、用户"
                        font.pixelSize: Theme.fontSmall
                        font.family: Theme.fontFamily
                        color: Theme.textTertiary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.navIndex = 2
                        root.currentPage = "search"
                        root.pageStack = []
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

    // ── 热搜标题栏 ──
    Rectangle {
        id: hotTitleBar
        anchors.top: searchBar.bottom
        width: parent.width
        height: 24
        color: Theme.bgSecondary

        Row {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingLarge
            anchors.rightMargin: Theme.spacingLarge
            spacing: Theme.spacingSmall

            Canvas {
                width: 14; height: 14
                anchors.verticalCenter: parent.verticalCenter
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.fillStyle = Theme.primary
                    // 火焰形状
                    ctx.beginPath()
                    ctx.moveTo(7, 1)
                    ctx.bezierCurveTo(3, 4, 2, 7, 4, 10)
                    ctx.bezierCurveTo(3, 9, 2, 11, 3, 13)
                    ctx.bezierCurveTo(5, 12, 7, 13, 7, 13)
                    ctx.bezierCurveTo(7, 13, 9, 12, 11, 13)
                    ctx.bezierCurveTo(12, 11, 11, 9, 10, 10)
                    ctx.bezierCurveTo(12, 7, 11, 4, 7, 1)
                    ctx.fill()
                }
            }

            Text {
                text: "微博热搜"
                font.pixelSize: Theme.fontNormal
                font.family: Theme.fontFamily
                font.bold: true
                color: Theme.textPrimary
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { width: 1; height: 1 }

            // 刷新按钮
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "⟳ 刷新"
                font.pixelSize: Theme.fontTiny
                font.family: Theme.fontFamily
                color: Theme.textTertiary

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    onClicked: {
                        if (controller) controller.refreshHotSearch()
                    }
                }
            }
        }
    }

    // ── 热搜列表 ──
    ListView {
        id: hotSearchList
        anchors.top: hotTitleBar.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: 200

        model: controller ? controller.hotSearchModel() : null

        delegate: Components.HotSearchItem {
            width: hotSearchList.width
            rank: index
            title: model.title
            heat: model.heat
            tag: model.tag
            isTop: model.isTop

            onClicked: {
                root.searchKeyword = model.title
                root.navIndex = 2
                root.currentPage = "search"
                root.pageStack = []
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
                    if (controller) controller.refreshHotSearch()
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
        visible: controller.isLoading && controller.hotSearchModel().rowCount() === 0
    }

    // ── 错误覆盖层 ──
    Components.ErrorOverlay {
        anchors.fill: parent
        visible: !controller.isLoading && controller.hotSearchModel().rowCount() === 0 && controller.globalError !== ""
        errorText: controller.globalError
        retryText: "重试"
        onRetry: {
            if (controller) controller.refreshHotSearch()
        }
    }

    Component.onCompleted: {
        if (controller) controller.refreshHotSearch()
    }
}
