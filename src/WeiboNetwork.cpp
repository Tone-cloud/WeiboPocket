#include "WeiboNetwork.h"

#include <QUrl>
#include <QUrlQuery>
#include <QJsonDocument>
#include <QJsonObject>
#include <QEventLoop>
#include <QTimer>
#include <QFile>
#include <QFileInfo>
#include <QDir>

WeiboNetwork::WeiboNetwork(QObject *parent)
    : QObject(parent), m_baseUrl("http://127.0.0.1:8001") {
  m_nam = new QNetworkAccessManager(this);
}

WeiboNetwork::~WeiboNetwork() {
  cancelAll();
}

void WeiboNetwork::setBaseUrl(const QString &url) {
  m_baseUrl = url;
}

QString WeiboNetwork::buildUrl(const QString &path, const QMap<QString, QString> &params) {
  QString url = m_baseUrl + path;
  if (!params.isEmpty()) {
    QUrlQuery query;
    for (auto it = params.begin(); it != params.end(); ++it) {
      query.addQueryItem(it.key(), it.value());
    }
    url += "?" + query.toString(QUrl::FullyEncoded);
  }
  return url;
}

QNetworkReply *WeiboNetwork::doRequest(const QString &url, const QByteArray &body) {
  QNetworkRequest request(QUrl(url));
  request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
  request.setRawHeader("Accept", "application/json");

  QNetworkReply *reply;
  if (body.isEmpty()) {
    reply = m_nam->get(request);
  } else {
    reply = m_nam->post(request, body);
  }

  m_activeReplies.append(reply);
  connect(reply, &QNetworkReply::finished, this, [this, reply]() {
    m_activeReplies.removeAll(reply);
    reply->deleteLater();
  });

  return reply;
}

void WeiboNetwork::get(const QString &path,
                       const QMap<QString, QString> &params,
                       std::function<void(const QJsonObject &)> onSuccess,
                       std::function<void(int, const QString &)> onError) {
  QString url = buildUrl(path, params);
  QNetworkReply *reply = doRequest(url);

  connect(reply, &QNetworkReply::finished, this, [reply, onSuccess, onError, this]() {
    if (reply->error() != QNetworkReply::NoError) {
      QString errMsg = reply->errorString();
      int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
      if (onError) onError(statusCode, errMsg);
      emit networkError(statusCode, errMsg);
      return;
    }

    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) {
      if (onError) onError(-1, "响应不是有效的 JSON");
      return;
    }

    QJsonObject obj = doc.object();
    int code = obj.value("code").toInt(-1);
    if (code != 0) {
      QString msg = obj.value("message").toString("未知错误");
      if (onError) onError(code, msg);
      return;
    }

    if (onSuccess) onSuccess(obj);
  });
}

void WeiboNetwork::post(const QString &path,
                        const QMap<QString, QString> &params,
                        std::function<void(const QJsonObject &)> onSuccess,
                        std::function<void(int, const QString &)> onError) {
  QString url = m_baseUrl + path;
  QUrlQuery query;
  for (auto it = params.begin(); it != params.end(); ++it) {
    query.addQueryItem(it.key(), it.value());
  }
  QByteArray body = query.toString(QUrl::FullyEncoded).toUtf8();

  QNetworkReply *reply = doRequest(url, body);

  connect(reply, &QNetworkReply::finished, this, [reply, onSuccess, onError, this]() {
    if (reply->error() != QNetworkReply::NoError) {
      QString errMsg = reply->errorString();
      int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
      if (onError) onError(statusCode, errMsg);
      emit networkError(statusCode, errMsg);
      return;
    }

    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) {
      if (onError) onError(-1, "响应不是有效的 JSON");
      return;
    }

    QJsonObject obj = doc.object();
    int code = obj.value("code").toInt(-1);
    if (code != 0) {
      QString msg = obj.value("message").toString("未知错误");
      if (onError) onError(code, msg);
      return;
    }

    if (onSuccess) onSuccess(obj);
  });
}

void WeiboNetwork::getRaw(const QString &url,
                           std::function<void(const QByteArray &)> onSuccess,
                           std::function<void(int, const QString &)> onError) {
  QNetworkRequest request(QUrl(url));
  QNetworkReply *reply = m_nam->get(request);
  m_activeReplies.append(reply);

  connect(reply, &QNetworkReply::finished, this, [reply, onSuccess, onError, this]() {
    m_activeReplies.removeAll(reply);
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
      if (onError) onError(reply->error(), reply->errorString());
      return;
    }
    if (onSuccess) onSuccess(reply->readAll());
  });
}

void WeiboNetwork::applyCommonHeaders(QNetworkRequest &request) {
  request.setRawHeader("User-Agent",
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");
  request.setRawHeader("Accept", "*/*");
  request.setRawHeader("Accept-Language", "zh-CN,zh;q=0.9");
}

void WeiboNetwork::downloadImage(const QUrl &url,
                                  RawCallback onSuccess,
                                  ErrorCallback onError) {
  if (!url.isValid()) {
    if (onError) onError(-3, "无效的图片地址");
    return;
  }

  QNetworkRequest request(url);
  applyCommonHeaders(request);

  QNetworkReply *reply = m_nam->get(request);
  if (!reply) {
    if (onError) onError(-13, "创建请求失败");
    return;
  }

  m_activeReplies.append(reply);

  constexpr qint64 MAX_IMAGE_SIZE = 10 * 1024 * 1024;

  connect(reply, &QNetworkReply::downloadProgress,
          [reply](qint64 received, qint64 total) {
            Q_UNUSED(total)
            if (received > MAX_IMAGE_SIZE) reply->abort();
          });

  QPointer<QNetworkReply> safeReply(reply);
  QTimer *timer = new QTimer(this);
  timer->setSingleShot(true);
  connect(timer, &QTimer::timeout, this, [safeReply, timer]() {
    if (safeReply && safeReply->isRunning()) safeReply->abort();
    timer->disconnect();
    timer->deleteLater();
  });
  timer->start(10000);

  connect(reply, &QNetworkReply::finished, this,
          [this, reply, onSuccess, onError, timer]() {
            timer->stop();
            timer->disconnect();
            timer->deleteLater();
            m_activeReplies.removeAll(reply);

            if (reply->error() == QNetworkReply::NoError) {
              QByteArray data = reply->readAll();
              if (data.isEmpty()) {
                if (onError) onError(-4, "图片数据为空");
              } else {
                if (onSuccess) onSuccess(data);
              }
            } else {
              if (onError) onError(reply->error(), reply->errorString());
            }
            reply->deleteLater();
          });
}

void WeiboNetwork::downloadVideo(const QString &url,
                                  const QString &targetPath,
                                  std::function<void(const QString &path)> onSuccess,
                                  ErrorCallback onError,
                                  ProgressCallback onProgress,
                                  const QString &tag) {
  QUrl downloadUrl(url);
  if (!downloadUrl.isValid()) {
    if (onError) onError(-3, "无效的视频地址");
    return;
  }

  QFileInfo targetInfo(targetPath);
  QDir targetDir = targetInfo.absoluteDir();
  if (!targetDir.exists() && !targetDir.mkpath(".")) {
    if (onError) onError(-5, "无法创建目标目录");
    return;
  }

  QNetworkRequest request(downloadUrl);
  applyCommonHeaders(request);
  if (url.contains("weibo.com") || url.contains("sinaimg.cn")) {
    request.setRawHeader("Referer", "https://weibo.com/");
  }

  QNetworkReply *reply = m_nam->get(request);
  if (!reply) {
    if (onError) onError(-13, "创建请求失败");
    return;
  }

  m_activeReplies.append(reply);

  QPointer<QNetworkReply> safeReply(reply);
  QString safePath = targetPath;
  QString safeTag = tag;

  QFile *file = new QFile(targetPath, this);
  if (!file->open(QIODevice::WriteOnly | QIODevice::Truncate)) {
    if (onError) onError(-6, "无法打开目标文件: " + file->errorString());
    file->deleteLater();
    m_activeReplies.removeAll(reply);
    reply->abort();
    reply->deleteLater();
    return;
  }

  connect(reply, &QNetworkReply::readyRead, this, [reply, file]() {
    if (reply->bytesAvailable() > 0) file->write(reply->readAll());
  });

  connect(reply, &QNetworkReply::downloadProgress, this,
          [onProgress](qint64 received, qint64 total) {
            if (onProgress) onProgress(received, total);
          });

  connect(reply, &QNetworkReply::finished, this,
          [this, reply, file, onSuccess, onError, safePath, safeTag]() {
            m_activeReplies.removeAll(reply);

            if (reply->error() == QNetworkReply::NoError) {
              if (reply->bytesAvailable() > 0) file->write(reply->readAll());
              file->flush();
              file->close();
              file->deleteLater();

              QFileInfo fi(safePath);
              if (fi.exists() && fi.size() > 0) {
                if (onSuccess) onSuccess(safePath);
              } else {
                if (onError) onError(-7, "下载文件为空");
              }
            } else {
              file->close();
              file->remove();
              file->deleteLater();
              if (onError) onError(reply->error(), reply->errorString());
            }
            reply->deleteLater();
          });
}

void WeiboNetwork::cancelAll() {
  for (QNetworkReply *reply : m_activeReplies) {
    reply->abort();
  }
  m_activeReplies.clear();
}
