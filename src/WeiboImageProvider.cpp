#include "WeiboImageProvider.h"

#include <QNetworkRequest>
#include <QNetworkReply>
#include <QEventLoop>
#include <QUrl>

WeiboImageProvider::WeiboImageProvider(QObject *parent)
    : QObject(parent), QQuickImageProvider(QQuickImageProvider::Pixmap) {
  m_nam = new QNetworkAccessManager(this);
}

QPixmap WeiboImageProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) {
  // id 格式: image://weibo/https%3A%2F%2F...
  QString url = QUrl::fromPercentEncoding(id.toUtf8());

  // 检查缓存
  if (m_cache.contains(url)) {
    QPixmap cached = m_cache.value(url);
    if (size) *size = cached.size();
    if (requestedSize.isValid() && requestedSize.width() > 0 && requestedSize.height() > 0) {
      return cached.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }
    return cached;
  }

  // 同步下载图片
  QUrl imgUrl(url);
  QNetworkRequest request(imgUrl);
  request.setRawHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36");
  request.setRawHeader("Referer", "https://weibo.com/");

  QNetworkReply *reply = m_nam->get(request);
  QEventLoop loop;
  connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
  loop.exec();

  QPixmap pixmap;
  if (reply->error() == QNetworkReply::NoError) {
    pixmap.loadFromData(reply->readAll());
    if (!pixmap.isNull()) {
      m_cache.insert(url, pixmap);
    }
  }
  reply->deleteLater();

  if (size) *size = pixmap.size();
  if (requestedSize.isValid() && requestedSize.width() > 0 && requestedSize.height() > 0 && !pixmap.isNull()) {
    return pixmap.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
  }
  return pixmap;
}

void WeiboImageProvider::preload(const QString &url) {
  if (m_cache.contains(url)) return;

  QUrl preloadUrl(url);
  QNetworkRequest request(preloadUrl);
  request.setRawHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36");
  QNetworkReply *reply = m_nam->get(request);
  connect(reply, &QNetworkReply::finished, this, [this, url, reply]() {
    if (reply->error() == QNetworkReply::NoError) {
      QPixmap pixmap;
      pixmap.loadFromData(reply->readAll());
      if (!pixmap.isNull()) {
        m_cache.insert(url, pixmap);
      }
    }
    reply->deleteLater();
  });
}

void WeiboImageProvider::clearCache() {
  m_cache.clear();
}
