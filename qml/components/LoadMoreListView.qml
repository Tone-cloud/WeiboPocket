import QtQuick 2.12
import WeiboPlugin 1.0

ListView {
    id: loadMoreListView
    orientation: ListView.Vertical
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    property bool isLoading: false
    property bool hasMore: true
    property int currentPage: 1
    signal loadMore()

    onAtYEndChanged: {
        if (atYEnd && !isLoading && hasMore) {
            isLoading = true
            loadMore()
        }
    }

    // 底部加载指示
    footer: Item {
        width: parent.width
        height: isLoading ? 30 : 0
        visible: isLoading

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingSmall

            Components.LoadingIndicator {
                size: 16
                width: 16
                height: 16
            }

            Text {
                text: "加载中..."
                font.pixelSize: Theme.fontSizeTiny
                font.family: Theme.fontFamily
                color: Theme.textTertiary
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    function reset() {
        currentPage = 1
        hasMore = true
        isLoading = false
        model.clear()
    }

    function finishLoad(success, more) {
        isLoading = false
        hasMore = more
        if (success) currentPage++
    }
}
