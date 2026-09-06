#pragma once

#include <QObject>
#include <QtGlobal>
#include <QString>
#include <QStringList>
#include <functional>

class WeiboController;

class WeiboPlaybackModule : public QObject {
  Q_OBJECT
public:
  explicit WeiboPlaybackModule(WeiboController *controller);
  Q_INVOKABLE void fetchPlayUrl(const QString &statusId);
  Q_INVOKABLE bool externalPlayerRunning() const;
  Q_INVOKABLE void launchExternalPlayer(const QString &url);
  Q_INVOKABLE void launchExternalPlayerCurrentSelection();
  Q_INVOKABLE void cancelDownload();

private:
  bool isExternalPlayerRunning() const;
  bool startExternalPlayer(const QStringList &args);
  WeiboController *m_controller;
};
