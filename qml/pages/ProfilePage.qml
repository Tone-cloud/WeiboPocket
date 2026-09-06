import QtQuick 2.12
import WeiboPlugin 1.0
import "../components" as Components

Rectangle {
    id: profilePage
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
                text: "我的"
                font.pixelSize: Theme.fontMedium
                font.family: Theme.fontFamily
                font.bold: true
                color: Theme.textPrimary
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { width: 1; height: 1 }

            Text {
                text: "设置"
                font.pixelSize: Theme.fontSmall
                font.family: Theme.fontFamily
                color: Theme.textSecondary
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    onClicked: root.navigateTo("settings", {})
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

    // ── 内容滚动区 ──
    Flickable {
        id: contentFlick
        anchors.top: headerBar.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        contentHeight: contentColumn.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentColumn
            width: parent.width
            spacing: 0

            // ── 用户信息区 ──
            Rectangle {
                width: parent.width
                height: controller.loggedIn ? 72 : 80
                color: Theme.bgHeader

                // 未登录
                Column {
                    anchors.centerIn: parent
                    spacing: Theme.spacingMedium
                    visible: !controller.loggedIn

                    Rectangle {
                        width: 44
                        height: 44
                        radius: Theme.radiusRound
                        color: Theme.bgTertiary
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "👤"
                            font.pixelSize: 20
                        }
                    }

                    Rectangle {
                        width: 72
                        height: 26
                        radius: Theme.radiusMedium
                        color: Theme.primary
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "登录"
                            font.pixelSize: Theme.fontSmall
                            font.family: Theme.fontFamily
                            color: "#FFFFFF"
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: showLoginDialog()
                        }
                    }
                }

                // 已登录
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingLarge
                    anchors.rightMargin: Theme.spacingLarge
                    spacing: Theme.spacingMedium
                    visible: controller.loggedIn

                    Rectangle {
                        width: 48
                        height: 48
                        radius: Theme.radiusRound
                        color: Theme.bgTertiary
                        clip: true
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            anchors.fill: parent
                            source: controller.userAvatar !== "" ? "image://weibo/" + encodeURIComponent(controller.userAvatar) : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    Column {
                        width: parent.width - 48 - Theme.spacingMedium
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingTiny

                        Text {
                            text: controller.userName
                            font.pixelSize: Theme.fontLarge
                            font.family: Theme.fontFamily
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Text {
                            text: "ID: " + controller.userId
                            font.pixelSize: Theme.fontTiny
                            font.family: Theme.fontFamily
                            color: Theme.textTertiary
                        }

                        Row {
                            spacing: Theme.spacingLarge

                            Text {
                                text: Theme.formatNumber(controller.userStatuses) + " 微博"
                                font.pixelSize: Theme.fontTiny
                                font.family: Theme.fontFamily
                                color: Theme.textSecondary
                            }
                            Text {
                                text: Theme.formatNumber(controller.userFollowing) + " 关注"
                                font.pixelSize: Theme.fontTiny
                                font.family: Theme.fontFamily
                                color: Theme.textSecondary
                            }
                            Text {
                                text: Theme.formatNumber(controller.userFollowers) + " 粉丝"
                                font.pixelSize: Theme.fontTiny
                                font.family: Theme.fontFamily
                                color: Theme.textSecondary
                            }
                        }
                    }
                }
            }

            // 分割区
            Rectangle {
                width: parent.width
                height: 6
                color: Theme.bgPrimary
            }

            // ── 功能菜单 ──
            Rectangle {
                width: parent.width
                color: Theme.bgHeader

                Column {
                    width: parent.width

                    // 我的微博
                    Rectangle {
                        width: parent.width
                        height: 34
                        visible: controller.loggedIn

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingLarge
                            anchors.rightMargin: Theme.spacingLarge
                            spacing: Theme.spacingMedium

                            Text {
                                text: "📝"
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "我的微博"
                                font.pixelSize: Theme.fontNormal
                                font.family: Theme.fontFamily
                                color: Theme.textPrimary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "›"
                                font.pixelSize: 16
                                color: Theme.textTertiary
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (controller) {
                                    controller.loadMyStatuses(1)
                                    root.navigateTo("user", {
                                        userId: controller.userId,
                                        userName: controller.userName
                                    })
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width - Theme.spacingLarge * 2
                            height: 1
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: Theme.hairline
                        }
                    }

                    // 超话签到
                    Rectangle {
                        width: parent.width
                        height: 34
                        visible: controller.loggedIn

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingLarge
                            anchors.rightMargin: Theme.spacingLarge
                            spacing: Theme.spacingMedium

                            Text {
                                text: "⭐"
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "超话签到"
                                font.pixelSize: Theme.fontNormal
                                font.family: Theme.fontFamily
                                color: Theme.textPrimary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "›"
                                font.pixelSize: 16
                                color: Theme.textTertiary
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.navIndex = 1
                                root.currentPage = "supertopic"
                                root.pageStack = []
                            }
                        }

                        Rectangle {
                            width: parent.width - Theme.spacingLarge * 2
                            height: 1
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: Theme.hairline
                        }
                    }

                    // 浏览历史
                    Rectangle {
                        width: parent.width
                        height: 34

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingLarge
                            anchors.rightMargin: Theme.spacingLarge
                            spacing: Theme.spacingMedium

                            Text {
                                text: "🕐"
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "浏览历史"
                                font.pixelSize: Theme.fontNormal
                                font.family: Theme.fontFamily
                                color: Theme.textPrimary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "›"
                                font.pixelSize: 16
                                color: Theme.textTertiary
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.showToast("功能开发中")
                        }

                        Rectangle {
                            width: parent.width - Theme.spacingLarge * 2
                            height: 1
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: Theme.hairline
                        }
                    }

                    // 退出登录
                    Rectangle {
                        width: parent.width
                        height: 34
                        visible: controller.loggedIn

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingLarge
                            anchors.rightMargin: Theme.spacingLarge
                            spacing: Theme.spacingMedium

                            Text {
                                text: "🚪"
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "退出登录"
                                font.pixelSize: Theme.fontNormal
                                font.family: Theme.fontFamily
                                color: Theme.error
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (controller) controller.logout()
                            }
                        }
                    }
                }
            }
        }
    }

    // ── 登录对话框 ──
    Rectangle {
        id: loginDialog
        anchors.fill: parent
        color: "#80000000"
        visible: false
        z: 100

        Rectangle {
            anchors.centerIn: parent
            width: 260
            height: 150
            radius: Theme.radiusLarge
            color: Theme.bgHeader

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingLarge
                spacing: Theme.spacingMedium

                Text {
                    text: "登录微博"
                    font.pixelSize: Theme.fontMedium
                    font.family: Theme.fontFamily
                    font.bold: true
                    color: Theme.textPrimary
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "请输入微博 Cookie（从浏览器复制）"
                    font.pixelSize: Theme.fontTiny
                    font.family: Theme.fontFamily
                    color: Theme.textSecondary
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    width: parent.width
                    height: 50
                    radius: Theme.radiusSmall
                    color: Theme.bgInput
                    border.color: Theme.border

                    TextEdit {
                        id: cookieInput
                        anchors.fill: parent
                        anchors.margins: Theme.spacingSmall
                        font.pixelSize: Theme.fontTiny
                        font.family: Theme.fontFamily
                        color: Theme.textPrimary
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        placeholderText: "SUB=...; SUBP=...; SUHB=..."
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacingLarge

                    Rectangle {
                        width: 72
                        height: 26
                        radius: Theme.radiusMedium
                        color: Theme.bgTertiary

                        Text {
                            anchors.centerIn: parent
                            text: "取消"
                            font.pixelSize: Theme.fontSmall
                            font.family: Theme.fontFamily
                            color: Theme.textSecondary
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: loginDialog.visible = false
                        }
                    }

                    Rectangle {
                        width: 72
                        height: 26
                        radius: Theme.radiusMedium
                        color: Theme.primary

                        Text {
                            anchors.centerIn: parent
                            text: "登录"
                            font.pixelSize: Theme.fontSmall
                            font.family: Theme.fontFamily
                            color: "#FFFFFF"
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (controller && cookieInput.text.trim() !== "") {
                                    controller.importCookie(cookieInput.text.trim())
                                }
                                loginDialog.visible = false
                            }
                        }
                    }
                }
            }
        }
    }

    function showLoginDialog() {
        cookieInput.text = ""
        loginDialog.visible = true
    }
}
