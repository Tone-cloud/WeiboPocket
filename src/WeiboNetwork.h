#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QString>
#include <QMap>
#include <QUrl>
#include <functional>

using RawCallback = std::function<void(const QByteArray &)>;
using ErrorCallback = std::function<void(int code, const QString &msg)>;
using ProgressCallback = std::function<void(qint64 received, qint64 total)>;

class WeiboNetwork : public QObject {
  Q_OBJECT

public:
  explicit WeiboNetwork(QObject *parent = nullptr);
  ~WeiboNetwork();

  void setBaseUrl(const QString &url);
  QString baseUrl() const { return m_baseUrl; }

  // GET 请求
  void get(const QString &path,
           const QMap<QString, QString> &params,
           std::function<void(const QJsonObject &)> onSuccess,
           std::function<void(int, const QString &)> onError = nullptr);

  // POST 请求
  void post(const QString &path,
            const QMap<QString, QString> &params,
            std::function<void(const QJsonObject &)> onSuccess,
            std::function<void(int, const QString &)> onError = nullptr);

  // 原始 GET（返回 bytes）
  void getRaw(const QString &url,
              std::function<void(const QByteArray &)> onSuccess,
              std::function<void(int, const QString &)> onError = nullptr);

  // 下载图片（返回 bytes，限制 10MB）
  void downloadImage(const QUrl &url,
                     RawCallback onSuccess,
                     ErrorCallback onError = nullptr);

  // 下载视频到文件
  void downloadVideo(const QString &url,
                     const QString &targetPath,
                     std::function<void(const QString &path)> onSuccess,
                     ErrorCallback onError = nullptr,
                     ProgressCallback onProgress = nullptr,
                     const QString &tag = QString());

  // 取消所有请求
  void cancelAll();

signals:
  void networkError(int code, const QString &message);

private:
  QString buildUrl(const QString &path, const QMap<QString, QString> &params);
  QNetworkReply *doRequest(const QString &url, const QByteArray &body = QByteArray());
  void applyCommonHeaders(QNetworkRequest &request);

  QString m_baseUrl;
  QNetworkAccessManager *m_nam;
  QList<QNetworkReply *> m_activeReplies;
};
