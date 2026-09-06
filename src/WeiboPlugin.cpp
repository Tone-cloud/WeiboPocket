#include <QQmlExtensionPlugin>
#include <QQmlEngine>
#include <QQuickImageProvider>

#include "WeiboController.h"
#include "WeiboModels.h"
#include "WeiboNetwork.h"
#include "WeiboImageProvider.h"

class WeiboPlugin : public QQmlExtensionPlugin {
  Q_OBJECT
  Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
  void registerTypes(const char *uri) override {
    Q_ASSERT(uri == QLatin1String("WeiboPlugin"));

    // 注册主控制器
    qmlRegisterType<WeiboController>(uri, 1, 0, "WeiboController");

    // 注册模型
    qmlRegisterType<HotSearchModel>(uri, 1, 0, "HotSearchModel");
    qmlRegisterType<StatusListModel>(uri, 1, 0, "StatusListModel");
    qmlRegisterType<CommentListModel>(uri, 1, 0, "CommentListModel");
    qmlRegisterType<SuperTopicModel>(uri, 1, 0, "SuperTopicModel");
    qmlRegisterType<SearchUserModel>(uri, 1, 0, "SearchUserModel");

    // 注册网络类
    qmlRegisterType<WeiboNetwork>(uri, 1, 0, "WeiboNetwork");
  }

  void initializeEngine(QQmlEngine *engine, const char *uri) override {
    Q_UNUSED(uri);
    // 注册图片提供者
    engine->addImageProvider(QLatin1String("weibo"), new WeiboImageProvider());
  }
};

#include "WeiboPlugin.moc"
