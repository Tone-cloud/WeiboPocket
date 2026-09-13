#include <QCoreApplication>
#include <QDebug>
#include <QFile>
#include <QProcess>
#include <QQmlEngine>
#include <QTcpSocket>
#include <QThread>
#include <QPointer>
#include <signal.h>

#include "WeiboController.h"
#include "WeiboModels.h"
#include "WeiboNetwork.h"
#include "WeiboImageProvider.h"

// ==================== 配置 ====================

static const char *kPluginPath = "/userdisk/PenMods/plugins/weibo_plugin/";
static const char *kQmlPath = "/userdisk/PenMods/plugins/weibo_plugin/qml";
static const char *kServerExec = "server";
static const int kServerPort = 8001;

// ==================== 全局状态 ====================

static QPointer<QProcess> s_serverProcess;
static QPointer<QQmlEngine> s_engine;
static WeiboImageProvider *s_imageProvider = nullptr;

// ==================== Go Server 同步启动 ====================

static bool probeServer() {
  QTcpSocket socket;
  socket.connectToHost(QStringLiteral("127.0.0.1"), kServerPort);
  return socket.waitForConnected(300);
}

static bool startServerSync() {
  qDebug() << "WeiboPlugin: Starting API server (sync, port" << kServerPort << ")...";

  // 已在运行则复用
  if (probeServer()) {
    qDebug() << "WeiboPlugin: API server already running, reuse it";
    return true;
  }

  // 清理残留进程
  const QString execPath = QString::fromUtf8(kPluginPath) + QString::fromUtf8(kServerExec);
  {
    QProcess pgrepProcess;
    pgrepProcess.start(QStringLiteral("pgrep"),
                       QStringList() << QStringLiteral("-f") << execPath);
    pgrepProcess.waitForFinished(2000);
    if (pgrepProcess.exitCode() == 0) {
      const QString output =
          QString::fromLocal8Bit(pgrepProcess.readAllStandardOutput()).trimmed();
      const QStringList pids = output.split('\n', Qt::SkipEmptyParts);
      for (const QString &pid : pids) {
        bool ok = false;
        const int pidNum = pid.toInt(&ok);
        if (ok && pidNum > 0) {
          qDebug() << "WeiboPlugin: Killing existing process PID:" << pidNum;
          kill(pidNum, SIGTERM);
        }
      }
      QThread::msleep(500);
      for (const QString &pid : pids) {
        bool ok = false;
        const int pidNum = pid.toInt(&ok);
        if (ok && pidNum > 0 && kill(pidNum, 0) == 0) {
          qWarning() << "WeiboPlugin: Force killing PID:" << pidNum;
          kill(pidNum, SIGKILL);
        }
      }
    }
  }

  // 等待端口释放
  for (int i = 0; i < 40; ++i) {
    if (!probeServer())
      break;
    QThread::msleep(250);
  }

  // 检查可执行文件
  if (!QFile::exists(execPath)) {
    qWarning() << "WeiboPlugin: API server executable not found:" << execPath;
    return false;
  }

  // 设置可执行权限
  QFile serverFile(execPath);
  if (!(serverFile.permissions() & QFile::ExeUser)) {
    serverFile.setPermissions(serverFile.permissions() | QFile::ExeUser |
                              QFile::ExeGroup | QFile::ExeOther);
  }

  // 清理旧进程对象
  if (s_serverProcess) {
    s_serverProcess->disconnect();
    s_serverProcess->deleteLater();
    s_serverProcess = nullptr;
  }

  // 启动 server
  s_serverProcess = new QProcess();
  s_serverProcess->setWorkingDirectory(QString::fromUtf8(kPluginPath));

  QObject::connect(
      s_serverProcess, &QProcess::readyReadStandardOutput, []() {
        if (s_serverProcess) {
          qDebug() << "Weibo Server:"
                   << s_serverProcess->readAllStandardOutput().constData();
        }
      });
  QObject::connect(
      s_serverProcess, &QProcess::readyReadStandardError, []() {
        if (s_serverProcess) {
          qWarning() << "Weibo Server Error:"
                     << s_serverProcess->readAllStandardError().constData();
        }
      });
  QObject::connect(
      s_serverProcess,
      QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
      [](int exitCode, QProcess::ExitStatus exitStatus) {
        qWarning() << "WeiboPlugin: API server exited with code" << exitCode
                   << ", status:"
                   << (exitStatus == QProcess::NormalExit ? "normal"
                                                          : "crashed");
      });

  s_serverProcess->start(execPath, QStringList());
  if (!s_serverProcess->waitForStarted(5000)) {
    qWarning() << "WeiboPlugin: Failed to start API server:"
               << s_serverProcess->errorString();
    delete s_serverProcess;
    s_serverProcess = nullptr;
    return false;
  }

  // 等待端口就绪
  bool ready = false;
  for (int i = 0; i < 50; ++i) { // 50 * 100ms = 5s
    if (probeServer()) {
      ready = true;
      break;
    }
    if (s_serverProcess->state() != QProcess::Running) {
      qWarning() << "WeiboPlugin: API server exited during bring-up";
      delete s_serverProcess;
      s_serverProcess = nullptr;
      return false;
    }
    QThread::msleep(100);
  }

  if (!ready) {
    qWarning() << "WeiboPlugin: API server started but port" << kServerPort
               << "not ready yet; keeping process, requests may retry";
  } else {
    qDebug() << "WeiboPlugin: API server started successfully, PID:"
             << s_serverProcess->processId();
  }
  return s_serverProcess->state() == QProcess::Running;
}

static void stopServer() {
  qDebug() << "WeiboPlugin: Stopping API server...";

  if (!s_serverProcess) {
    qDebug() << "WeiboPlugin: No owned API server process, skip stop";
    return;
  }

  QProcess *proc = s_serverProcess;
  s_serverProcess = nullptr;
  proc->disconnect();
  proc->terminate();
  if (!proc->waitForFinished(3000)) {
    proc->kill();
    proc->waitForFinished(1000);
  }
  delete proc;

  qDebug() << "WeiboPlugin: API server stopped";
}

// ==================== PenMods 插件入口 ====================

extern "C" {

void init_plugin() {
  qDebug() << "WeiboPlugin: Initializing...";

  // 注册 QML 类型
  qmlRegisterType<WeiboController>("WeiboPlugin", 1, 0, "WeiboController");
  qmlRegisterType<HotSearchModel>("WeiboPlugin", 1, 0, "HotSearchModel");
  qmlRegisterType<StatusListModel>("WeiboPlugin", 1, 0, "StatusListModel");
  qmlRegisterType<CommentListModel>("WeiboPlugin", 1, 0, "CommentListModel");
  qmlRegisterType<SuperTopicModel>("WeiboPlugin", 1, 0, "SuperTopicModel");
  qmlRegisterType<SearchUserModel>("WeiboPlugin", 1, 0, "SearchUserModel");
  qmlRegisterType<WeiboNetwork>("WeiboPlugin", 1, 0, "WeiboNetwork");

  // 同步启动 Go server
  // 注意：这里绝不能碰 WeiboNetwork 单例，
  // 因为 init_plugin 可能在无事件循环的加载线程调用，
  // 会把 QNAM 单例钉在错误线程。
  if (!startServerSync()) {
    qWarning() << "WeiboPlugin: Warning - API server failed to start";
  }

  qDebug() << "WeiboPlugin: Registered successfully!";
}

void attach_engine(QQmlEngine *engine) {
  qDebug() << "WeiboPlugin: Attaching engine...";

  s_engine = engine;

  if (s_engine) {
    // 添加 QML import 路径
    s_engine->addImportPath(QString::fromUtf8(kQmlPath));
    s_engine->addImportPath(QString::fromUtf8(kPluginPath));

    // 注册图片提供者
    s_imageProvider = new WeiboImageProvider();
    s_engine->addImageProvider(QStringLiteral("weibo"), s_imageProvider);

    qDebug() << "WeiboPlugin: Engine attached, ImageProvider registered";
  }
}

void destroy_plugin() {
  qDebug() << "WeiboPlugin: Destroying...";

  // 停止 API 服务器
  stopServer();

  // 清理图片提供者
  s_imageProvider = nullptr;

  s_engine = nullptr;

  qDebug() << "WeiboPlugin: Destroyed successfully";
}

} // extern "C"
