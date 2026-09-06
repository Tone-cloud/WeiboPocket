import QtQuick 2.12

// 系统弹层容器（图片查看器等 qrc 页面）
Item {
    id: popupStack
    anchors.fill: parent
    z: 3000
    visible: popItemObject !== null

    property var popItemObject: null

    function updateStackInfo() {
        var found = null
        for (var i = popupStack.children.length - 1; i >= 0; --i) {
            var child = popupStack.children[i]
            if (!child || child === popItemObject) continue
            if (child.visible !== false) {
                found = child
                break
            }
        }
        popItemObject = found
    }

    function closeSameItem(popStackId) {
        for (var i = popupStack.children.length - 1; i >= 0; --i) {
            var child = popupStack.children[i]
            if (child && child.popStackId === popStackId) child.destroy(1)
        }
        Qt.callLater(function() { popupStack.updateStackInfo() })
    }

    function show(componentPath) {
        function initObj(obj) {
            if (!obj) return
            Object.defineProperty(obj, "popStackId", {
                enumerable: false,
                configurable: false,
                writable: false,
                value: componentPath
            })
            popupStack.popItemObject = obj
            if (obj.backButtonClicked) {
                obj.backButtonClicked.connect(function() {
                    popupStack.closeSameItem(obj.popStackId)
                })
            }
            if (obj.show) obj.show()
        }

        closeSameItem(componentPath)
        var comp = Qt.createComponent(componentPath)
        if (comp.status === Component.Ready) {
            var incubator = comp.incubateObject(popupStack)
            if (incubator.status !== Component.Ready) {
                incubator.onStatusChanged = function(s) {
                    if (s === Component.Ready) initObj(incubator.object)
                }
            } else {
                initObj(incubator.object)
            }
        } else {
            console.error("PopupStack component error: " + comp.errorString())
        }
    }
}
