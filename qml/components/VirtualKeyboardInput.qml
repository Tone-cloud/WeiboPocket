import QtQuick 2.12

// 虚拟键盘输入弹层：封装 YInputPage 的 incubate + YPagePopHelper 样板。
// 依赖宿主注入的 qmlCreateComponent() 与 qmlGlobal.inputPageShowing；
// accepted 的 content 是原始文本，是否 trim/空串处理由页面决定。
Item {
    id: helper
    z: 99

    property string initialText: ""

    signal accepted(string content)
    signal dismissed()

    property bool isShowing: false

    function open(prefill) {
        if (prefill !== undefined && prefill !== null) initialText = String(prefill)
        if (typeof qmlCreateComponent === "undefined") {
            console.warn("VirtualKeyboardInput: qmlCreateComponent not available")
            return
        }
        var component = qmlCreateComponent("YInputPage")
        if (Component.Ready === component.status) {
            var incubator = component.incubateObject(helper)
            if (incubator.status !== Component.Ready) {
                incubator.onStatusChanged = function(status) {
                    if (status === Component.Ready)
                        helper.inputPageCreated(incubator.object)
                }
            } else {
                helper.inputPageCreated(incubator.object)
            }
        }
    }

    function inputPageCreated(keyboardPage) {
        keyboardPage.backButtonClicked.connect(function() {
            helper.isShowing = false
            keyboardPage.todoDestroy()
            keyboardPage = null
            helper.dismissed()
        })

        keyboardPage.inputFinished.connect(function(content) {
            helper.isShowing = false
            keyboardPage.todoDestroy()
            helper.accepted(content)
        })

        keyboardPage.enterText(helper.initialText)
        keyboardPage.show()
        helper.isShowing = true
    }
}
