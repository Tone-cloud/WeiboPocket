#pragma once

#include <QObject>
#include <QQuickImageProvider>
#include <QPixmap>
#include <QHash>
#include <QString>

class WeiboImageProvider : public QObject, public QQuickImageProvider {
  Q_OBJECT
public:
  explicit WeiboImageProvider(QObject *parent = nullptr);

  QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override;

  // 预加载图片到缓存
  void preload(const QString &url);

  // 清除缓存
  void clearCache();

private:
  QHash<QString, QPixmap> m_cache;
  QNetworkAccessManager *m_nam;
};
