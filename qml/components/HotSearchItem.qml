import QtQuick 2.12
import WeiboPlugin 1.0
import ".."

Rectangle {
    id: hotSearchItem
    width: parent.width
    height: 30
    color: index % 2 === 0 ? Theme.bgSecondary : Theme.bgPrimary

    property int rank: 0
    property string title: ""
    property string heat: ""
    property string tag: "" // hot/new/boil/empty
    property bool isTop: false

    signal clicked()

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingLarge
        anchors.rightMargin: Theme.spacingLarge
        spacing: Theme.spacingMedium

        // 排名数字
        Text {
            width: 20
            text: rank + 1
            font.pixelSize: rank < 3 ? Theme.fontRank : Theme.fontLarge
            font.family: Theme.fontFamily
            font.bold: rank < 3
            color: Theme.rankColor(rank)
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
        }

        // 标题
        Text {
            width: parent.width - 20 - Theme.spacingMedium - 50 - (tagVisible.visible ? 24 : 0) - Theme.spacingSmall
            text: title
            font.pixelSize: Theme.fontNormal
            font.family: Theme.fontFamily
            color: isTop ? Theme.primary : Theme.textPrimary
            font.bold: isTop || rank < 3
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
        }

        // 标签
        Rectangle {
            id: tagVisible
            width: 22
            height: 13
            radius: Theme.radiusTiny
            anchors.verticalCenter: parent.verticalCenter
            visible: tag !== "" && tag !== "empty"
            color: {
                if (tag === "hot") return Theme.tagHot
                if (tag === "new") return Theme.tagNew
                if (tag === "boil") return Theme.tagBoil
                return Theme.tagRecommend
            }

            Text {
                anchors.centerIn: parent
                text: {
                    if (tag === "hot") return "热"
                    if (tag === "new") return "新"
                    if (tag === "boil") return "沸"
                    return "荐"
                }
                color: "#FFFFFF"
                font.pixelSize: Theme.fontTiny
                font.family: Theme.fontFamily
                font.bold: true
            }
        }

        // 热度
        Text {
            width: 50
            text: heat
            font.pixelSize: Theme.fontTiny
            font.family: Theme.fontFamily
            color: Theme.textTertiary
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            visible: heat !== ""
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
        onClicked: hotSearchItem.clicked()
    }
}
