# WeiboPocket - 词典笔微博客户端插件
# Qt/QML 插件，QML 类型 WeiboPlugin

QT       += core quick qml network multimedia gui
CONFIG   += shared c++17
TEMPLATE = lib
TARGET   = weibo_plugin

# 编译产物：libweibo_plugin.so
DESTDIR = $$PWD/../build

SOURCES += \
    WeiboController.cpp \
    WeiboModels.cpp \
    WeiboNetwork.cpp \
    WeiboImageProvider.cpp \
    WeiboPlugin.cpp \
    modules/playback/WeiboPlaybackModule.cpp \
    modules/viewer/WeiboViewerModule.cpp

HEADERS += \
    WeiboController.h \
    WeiboModels.h \
    WeiboNetwork.h \
    WeiboImageProvider.h \
    WeiboJsonUtils.h \
    WeiboAsyncUtils.hpp \
    WeiboListFetch.hpp \
    modules/playback/WeiboPlaybackModule.h \
    modules/viewer/WeiboViewerModule.h

# Qt include 路径（交叉编译时手动添加）
INCLUDEPATH += $$PWD/../qt-5.15.2-for-aarch64-dictpen-linux/include
INCLUDEPATH += $$PWD/../qt-5.15.2-for-aarch64-dictpen-linux/include/QtQml
INCLUDEPATH += $$PWD/../qt-5.15.2-for-aarch64-dictpen-linux/include/QtQml/5.15.2
INCLUDEPATH += $$PWD/../qt-5.15.2-for-aarch64-dictpen-linux/include/QtQuick
INCLUDEPATH += $$PWD/../qt-5.15.2-for-aarch64-dictpen-linux/include/QtQuick/5.15.2
INCLUDEPATH += $$PWD/../qt-5.15.2-for-aarch64-dictpen-linux/include/QtCore
INCLUDEPATH += $$PWD/../qt-5.15.2-for-aarch64-dictpen-linux/include/QtCore/5.15.2
INCLUDEPATH += $$PWD/../qt-5.15.2-for-aarch64-dictpen-linux/include/QtNetwork
INCLUDEPATH += $$PWD/../qt-5.15.2-for-aarch64-dictpen-linux/include/QtMultimedia
INCLUDEPATH += $$PWD/../qt-5.15.2-for-aarch64-dictpen-linux/include/QtGui
INCLUDEPATH += $$PWD/../qt-5.15.2-for-aarch64-dictpen-linux/include/QtGui/5.15.2

# 链接 Qt 库
LIBS += -lQt5Qml -lQt5Quick -lQt5Network -lQt5Multimedia -lQt5Gui -lQt5Core

# 编译选项
QMAKE_CXXFLAGS += -Wno-deprecated-declarations -Wno-unused-parameter -Wno-unused-variable
QMAKE_LFLAGS += -Wl,--as-needed

# 安装路径（打包时用）
target.path = /userdisk/PenMods/plugins/weibo_plugin
INSTALLS += target
