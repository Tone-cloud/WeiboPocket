#pragma once

#include <QObject>
#include <QtGlobal>
#include <QString>

class WeiboController;

class WeiboViewerModule : public QObject {
  Q_OBJECT
public:
  explicit WeiboViewerModule(WeiboController *controller);
  Q_INVOKABLE void prepareImageForViewer(const QString &url);

private:
  WeiboController *m_controller;
};
