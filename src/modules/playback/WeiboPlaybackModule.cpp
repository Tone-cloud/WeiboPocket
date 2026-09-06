#include "modules/playback/WeiboPlaybackModule.h"
#include "WeiboController.h"
#include "WeiboJsonUtils.h"
#include "WeiboNetwork.h"

#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QPointer>
#include <QProcess>
#include <QSettings>
#include <QStandardPaths>
#include <QTimer>
#include <QUrl>
#include <QtGlobal>
#include <functional>
#include <utility>

WeiboPlaybackModule::WeiboPlaybackModule(WeiboController *controller)
    : QObject(controller), m_controller(controller) {}

// ====== API: 播放地址 ======

void WeiboPlaybackModule::fetchPlayUrl(const QString &statusId) {
  if (statusId.isEmpty()) {
    emit m_controller->toastMessage("视频信息不完整，无法播放");
    return;
  }

  QMap<QString, QString> params;
  params["status_id"] = statusId;
  params["quality"] = "hd";

  QPointer<WeiboController> self(m_controller);
  QPointer<WeiboPlaybackModule> moduleSelf(this);

  m_controller->network()->get(
      "/video/playurl", params,
      [moduleSelf, self, statusId](const QJsonObject &data) {
        if (!moduleSelf || !self) return;

        QJsonObject videoData = data.value("data").toObject();
        QString playUrl = videoData.value("play_url").toString("");
        QString title = videoData.value("title").toString("");
        int duration = videoData.value("duration").toInt(0);

        if (playUrl.isEmpty()) {
          emit self->toastMessage("未获取到播放地址");
          return;
        }

        self->setPlayResult(playUrl, title, duration);
        emit self->playbackReady(playUrl);
      },
      [self](int code, const QString &msg) {
        if (!self) return;
        emit self->toastMessage("获取播放地址失败: " + msg);
      });
}

// ====== 外部播放器 ======

bool WeiboPlaybackModule::isExternalPlayerRunning() const {
  return m_controller->m_externalPlayerProcess &&
         m_controller->m_externalPlayerProcess->state() != QProcess::NotRunning;
}

bool WeiboPlaybackModule::externalPlayerRunning() const {
  return isExternalPlayerRunning();
}

bool WeiboPlaybackModule::startExternalPlayer(const QStringList &args) {
  const QString player = "/userdisk/mpv/mpv";
  if (!QFile::exists(player)) {
    emit m_controller->toastMessage("外部播放器不存在");
    return false;
  }

  if (isExternalPlayerRunning()) {
    emit m_controller->toastMessage("播放器已在运行，请先关闭当前窗口");
    return false;
  }

  auto *process = new QProcess(m_controller);
  process->setProgram(player);
  process->setArguments(args);

  QObject::connect(process, &QProcess::errorOccurred, m_controller,
                   [this, process](QProcess::ProcessError error) {
                     if (process != m_controller->m_externalPlayerProcess) {
                       process->deleteLater();
                       return;
                     }
                     QString detail = process->errorString();
                     if (detail.isEmpty()) {
                       detail = QString::number(static_cast<int>(error));
                     }
                     emit m_controller->toastMessage(
                         QString("启动外部播放器失败：%1").arg(detail));
                     m_controller->m_externalPlayerProcess = nullptr;
                     process->deleteLater();
                   });

  QObject::connect(
      process,
      QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
      m_controller, [this, process](int, QProcess::ExitStatus) {
        if (process == m_controller->m_externalPlayerProcess) {
          m_controller->m_externalPlayerProcess = nullptr;
        }
        process->deleteLater();
      });

  m_controller->m_externalPlayerProcess = process;
  process->start();
  return true;
}

void WeiboPlaybackModule::launchExternalPlayer(const QString &url) {
  if (url.isEmpty()) {
    emit m_controller->toastMessage("播放地址为空");
    return;
  }

  QString filePath = url;
  if (filePath.startsWith("file://")) {
    filePath = filePath.mid(7);
  }

  QStringList args;
  args << ("--force-media-title=" + m_controller->currentStatusText().left(30));
  args << filePath;
  if (filePath.startsWith("http")) {
    args << "--referrer=https://weibo.com"
         << "--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 "
            "Safari/537.36";
  }
  startExternalPlayer(args);
}

void WeiboPlaybackModule::launchExternalPlayerCurrentSelection() {
  QString playUrl = m_controller->playUrl();
  if (playUrl.isEmpty()) {
    emit m_controller->toastMessage("播放地址未就绪");
    return;
  }
  launchExternalPlayer(playUrl);
}

void WeiboPlaybackModule::cancelDownload() {
  // 微博视频无防盗链，直接播放，暂不需要下载取消
  emit m_controller->toastMessage("下载功能开发中");
}
