import QtQuick 2.12
import WeiboPlugin 1.0
import "../components" as Components

Rectangle {
    id: settingsPage
    color: Theme.bgPrimary

    // ── 标题栏 ──
    Components.TitleBar {
        id: titleBar
        title: "设置"
        showBack: true
        onBackClicked: root.navigateBack()
    }

    // ── 设置列表 ──
    ListView {
        id: settingsList
        anchors.top: titleBar.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        model: ListModel {
            ListElement { category: "账号"; title: "登录状态"; value: ""; action: "loginStatus"; type: "info" }
            ListElement { category: "账号"; title: "导入Cookie"; value: ""; action: "importCookie"; type: "action" }
            ListElement { category: "账号"; title: "退出登录"; value: ""; action: "logout"; type: "danger" }
            ListElement { category: "通用"; title: "服务器地址"; value: "127.0.0.1:8001"; action: "serverAddr"; type: "info" }
            ListElement { category: "通用"; title: "清除缓存"; value: ""; action: "clearCache"; type: "action" }
            ListElement { category: "关于"; title: "版本"; value: "1.0.0"; action: ""; type: "info" }
            ListElement { category: "关于"; title: "作者"; value: "WeiboPocket"; action: ""; type: "info" }
        }

        delegate: Rectangle {
            width: settingsList.width
            height: 34
            color: Theme.bgHeader
            visible: category !== ""

            Row {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingLarge
                anchors.rightMargin: Theme.spacingLarge
                spacing: Theme.spacingMedium

                Text {
                    text: title
                    font.pixelSize: Theme.fontNormal
                    font.family: Theme.fontFamily
                    color: type === "danger" ? Theme.error : Theme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: 1; height: 1 }

                Text {
                    text: value !== "" ? value : (type === "action" ? "›" : "")
                    font.pixelSize: Theme.fontTiny
                    font.family: Theme.fontFamily
                    color: Theme.textTertiary
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: value !== "" || type === "action"
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
                onClicked: handleAction(action)
            }
        }

        // 分类标题
        section.property: "category"
        section.criteria: ViewSection.FullString
        section.delegate: Rectangle {
            width: settingsList.width
            height: 22
            color: Theme.bgPrimary

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacingLarge
                anchors.verticalCenter: parent.verticalCenter
                text: section
                font.pixelSize: Theme.fontTiny
                font.family: Theme.fontFamily
                font.bold: true
                color: Theme.textTertiary
            }
        }
    }

    function handleAction(action) {
        switch (action) {
            case "loginStatus":
                if (controller) {
                    root.showToast(controller.loggedIn ? "已登录: " + controller.userName : "未登录")
                }
                break
            case "importCookie":
                root.showToast("请在个人中心登录")
                break
            case "logout":
                if (controller) controller.logout()
                break
            case "clearCache":
                root.showToast("缓存已清除")
                break
        }
    }
}
