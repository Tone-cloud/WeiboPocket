import QtQuick 2.12
import WeiboPlugin 1.0
import ".."

Rectangle {
    id: superTopicCard
    width: parent.width
    height: 52
    color: Theme.bgCard
    radius: 0

    property string topicId: ""
    property string title: ""
    property string cover: ""
    property string level: ""
    property bool checkedIn: false
    property int continuousDays: 0
    property int rank: 0

    signal clicked()
    signal checkinClicked()

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingLarge
        anchors.rightMargin: Theme.spacingLarge
        spacing: Theme.spacingMedium

        // 封面
        Rectangle {
            width: 38
            height: 38
            radius: Theme.radiusMedium
            color: Theme.primarySoft
            clip: true
            anchors.verticalCenter: parent.verticalCenter

            Image {
                anchors.fill: parent
                source: cover !== "" ? "image://weibo/" + encodeURIComponent(cover) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: cover !== ""
            }

            Text {
                anchors.centerIn: parent
                text: title.substring(0, 1)
                font.pixelSize: Theme.fontLarge
                font.family: Theme.fontFamily
                font.bold: true
                color: Theme.primary
                visible: cover === ""
            }
        }

        // 信息
        Column {
            width: parent.width - 38 - Theme.spacingMedium - 60 - Theme.spacingMedium
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingTiny

            Row {
                spacing: Theme.spacingSmall

                Text {
                    text: title
                    font.pixelSize: Theme.fontNormal
                    font.family: Theme.fontFamily
                    font.bold: true
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                    width: parent.width - 30
                }

                // 等级标签
                Rectangle {
                    width: 24
                    height: 13
                    radius: Theme.radiusTiny
                    color: Theme.primarySoft
                    visible: level !== ""

                    Text {
                        anchors.centerIn: parent
                        text: "Lv." + level
                        color: Theme.primary
                        font.pixelSize: Theme.fontTiny
                        font.family: Theme.fontFamily
                        font.bold: true
                    }
                }
            }

            Row {
                spacing: Theme.spacingMedium

                Text {
                    text: checkedIn ? "✓ 已签到" : "未签到"
                    font.pixelSize: Theme.fontTiny
                    font.family: Theme.fontFamily
                    color: checkedIn ? Theme.success : Theme.textTertiary
                }

                Text {
                    text: continuousDays > 0 ? "连续 " + continuousDays + " 天" : ""
                    font.pixelSize: Theme.fontTiny
                    font.family: Theme.fontFamily
                    color: Theme.textTertiary
                    visible: continuousDays > 0
                }
            }
        }

        // 签到按钮
        Rectangle {
            id: checkinBtn
            width: 56
            height: 24
            radius: Theme.radiusMedium
            color: checkedIn ? Theme.bgTertiary : Theme.primary
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: checkedIn ? "已签到" : "签到"
                font.pixelSize: Theme.fontSmall
                font.family: Theme.fontFamily
                color: checkedIn ? Theme.textTertiary : "#FFFFFF"
                font.bold: !checkedIn
            }

            MouseArea {
                anchors.fill: parent
                onClicked: superTopicCard.checkinClicked()
            }
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
        onClicked: superTopicCard.clicked()
    }
}
