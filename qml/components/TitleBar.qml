import QtQuick 2.12
import WeiboPlugin 1.0
import ".."

Rectangle {
    id: titleBar
    width: parent ? parent.width : 320
    height: Theme.titleBarHeight
    color: Theme.bgHeader
    z: 10

    property string title: ""
    property string titleSuffix: ""
    property bool showBack: true
    property bool showSearch: false
    property bool showRightText: false
    property string rightText: ""
    property int titleSideReserve: 50

    signal backClicked()
    signal searchClicked()
    signal rightClicked()

    // ── 返回按钮 ──
    Rectangle {
        id: backBtn
        visible: showBack
        width: 48
        height: parent.height
        color: "transparent"
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            id: backBtnCore
            anchors.centerIn: parent
            width: 34; height: 20
            radius: Theme.radiusMedium
            color: backArea.pressed
            ? Theme.withAlpha(Theme.primary, 0.1) : "transparent"

            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Row {
                anchors.centerIn: parent
                spacing: 1

                Canvas {
                    width: 12; height: 12
                    anchors.verticalCenter: parent.verticalCenter
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.strokeStyle = Theme.primary
                        ctx.lineWidth = 2
                        ctx.lineCap = "round"
                        ctx.lineJoin = "round"
                        ctx.beginPath()
                        ctx.moveTo(9, 2)
                        ctx.lineTo(3, 6)
                        ctx.lineTo(9, 10)
                        ctx.stroke()
                    }
                }
                Text {
                    text: "返回"
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        MouseArea {
            id: backArea
            anchors.fill: parent
            anchors.margins: -4
            onClicked: titleBar.backClicked()
        }
    }

    // ── 标题 ──
    Row {
        id: titleGroup
        property int maxWidth: Math.max(0, parent.width - titleBar.titleSideReserve * 2)
        anchors.centerIn: parent
        width: Math.min(maxWidth, titleText.implicitWidth + (suffixText.visible ? spacing + suffixText.implicitWidth : 0))
        height: parent.height
        spacing: suffixText.visible ? 3 : 0

        Text {
            id: titleText
            width: Math.max(0, titleGroup.width - (suffixText.visible ? titleGroup.spacing + suffixText.implicitWidth : 0))
            text: titleBar.title
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontMedium
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            horizontalAlignment: suffixText.visible ? Text.AlignRight : Text.AlignHCenter
        }

        Text {
            id: suffixText
            visible: titleBar.titleSuffix.length > 0
            text: titleBar.titleSuffix
            color: Theme.textTertiary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontTiny
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ── 搜索按钮 ──
    Rectangle {
        id: searchBtn
        visible: showSearch
        width: 32
        height: parent.height
        color: "transparent"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            anchors.centerIn: parent
            width: 24; height: 20
            radius: Theme.radiusMedium
            color: searchArea.pressed
            ? Theme.withAlpha(Theme.primary, 0.1) : "transparent"

            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Canvas {
                anchors.centerIn: parent
                width: 14
                height: 14
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = Theme.textSecondary
                    ctx.lineWidth = 1.5
                    ctx.lineCap = "round"
                    ctx.beginPath()
                    ctx.arc(6, 6, 4.5, 0, Math.PI * 2)
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.moveTo(9.5, 9.5)
                    ctx.lineTo(13, 13)
                    ctx.stroke()
                }
            }
        }

        MouseArea {
            id: searchArea
            anchors.fill: parent
            onClicked: titleBar.searchClicked()
        }
    }

    // ── 右侧文字按钮 ──
    Rectangle {
        id: rightTextBtn
        visible: showRightText
        width: 40
        height: parent.height
        color: "transparent"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        Text {
            anchors.centerIn: parent
            text: titleBar.rightText
            color: rightTextArea.pressed ? Theme.primaryDark : Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }

        MouseArea {
            id: rightTextArea
            anchors.fill: parent
            onClicked: titleBar.rightClicked()
        }
    }

    // ── 底部分割线 ──
    Rectangle {
        width: parent.width; height: 1
        anchors.bottom: parent.bottom
        color: Theme.border
    }
}
