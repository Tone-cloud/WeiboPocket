#include "WeiboController.h"
#include "WeiboNetwork.h"
#include "WeiboImageProvider.h"
#include "modules/viewer/WeiboViewerModule.h"
#include "modules/playback/WeiboPlaybackModule.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <QCoreApplication>

WeiboController::WeiboController(QObject *parent)
    : QObject(parent),
      m_loggedIn(false),
      m_userFollowers(0),
      m_userFollowing(0),
      m_userStatuses(0),
      m_isLoading(false),
      m_loadingCount(0),
      m_playDuration(0),
      m_serverStarted(false) {

  m_network = new WeiboNetwork(this);
  m_imageProvider = new WeiboImageProvider(this);
  m_viewerModule = new WeiboViewerModule(this);
  m_playbackModule = new WeiboPlaybackModule(this);

  // 初始化模型
  m_hotSearchModel = new HotSearchModel(this);
  m_statusListModel = new StatusListModel(this);
  m_searchStatusModel = new StatusListModel(this);
  m_userStatusModel = new StatusListModel(this);
  m_commentModel = new CommentListModel(this);
  m_commentReplyModel = new CommentListModel(this);
  m_superTopicModel = new SuperTopicModel(this);
  m_searchUserModel = new SearchUserModel(this);

  // 初始化模块对象
  m_hotObj = new WeiboModule(this);
  m_statusObj = new WeiboModule(this);
  m_commentObj = new WeiboModule(this);
  m_superTopicObj = new WeiboModule(this);
  m_videoObj = new WeiboModule(this);
  m_searchObj = new WeiboModule(this);
  m_userObj = new WeiboModule(this);
  m_authObj = new WeiboModule(this);

  // 启动服务器
  startServer();

  // 检查登录状态
  QTimer::singleShot(1000, this, &WeiboController::checkLogin);
}

WeiboController::~WeiboController() {
  stopServer();
}

// ==================== API 辅助 ====================

void WeiboController::apiGet(const QString &path,
                              const QMap<QString, QString> &params,
                              std::function<void(const QJsonObject &)> onSuccess,
                              std::function<void(int, const QString &)> onError,
                              bool withLoading) {
  if (withLoading) setIsLoading(true);

  m_network->get(path, params,
    [this, onSuccess, withLoading](const QJsonObject &obj) {
      if (withLoading) setIsLoading(false);
      if (onSuccess) onSuccess(obj);
    },
    [this, onError, withLoading](int code, const QString &msg) {
      if (withLoading) setIsLoading(false);
      setGlobalError(msg);
      if (onError) onError(code, msg);
    });
}

void WeiboController::apiPost(const QString &path,
                               const QMap<QString, QString> &params,
                               std::function<void(const QJsonObject &)> onSuccess,
                               std::function<void(int, const QString &)> onError) {
  m_network->post(path, params,
    [this, onSuccess](const QJsonObject &obj) {
      if (onSuccess) onSuccess(obj);
    },
    [this, onError](int code, const QString &msg) {
      setGlobalError(msg);
      if (onError) onError(code, msg);
    });
}

void WeiboController::setGlobalError(const QString &error) {
  if (m_globalError != error) {
    m_globalError = error;
    emit globalErrorChanged();
  }
  if (!error.isEmpty()) {
    emit toastMessage(error);
  }
}

void WeiboController::setIsLoading(bool loading) {
  if (loading) {
    m_loadingCount++;
  } else {
    m_loadingCount = qMax(0, m_loadingCount - 1);
  }
  bool newState = m_loadingCount > 0;
  if (m_isLoading != newState) {
    m_isLoading = newState;
    emit isLoadingChanged();
  }
}

void WeiboController::clearError() {
  setGlobalError("");
}

void WeiboController::cancelAll() {
  m_network->cancelAll();
  m_loadingCount = 0;
  m_isLoading = false;
  emit isLoadingChanged();
}

// ==================== 服务器管理 ====================

void WeiboController::startServer() {
  if (m_serverStarted) return;

  // 查找服务器二进制
  QString appDir = QCoreApplication::applicationDirPath();
  QStringList possiblePaths = {
    appDir + "/server",
    appDir + "/../server",
    "/userdisk/PenMods/plugins/weibo_plugin/server",
  };

  QString serverPath;
  for (const QString &p : possiblePaths) {
    if (QFileInfo::exists(p)) {
      serverPath = p;
      break;
    }
  }

  if (serverPath.isEmpty()) {
    qWarning() << "Weibo server binary not found, will use external server";
    return;
  }

  m_serverProcess = new QProcess(this);
  m_serverProcess->setProgram(serverPath);
  m_serverProcess->setProcessEnvironment(QProcessEnvironment::systemEnvironment());
  m_serverProcess->start();

  if (m_serverProcess->waitForStarted(3000)) {
    m_serverStarted = true;
    qInfo() << "Weibo server started:" << serverPath;
  } else {
    qWarning() << "Failed to start weibo server:" << m_serverProcess->errorString();
  }
}

void WeiboController::stopServer() {
  if (m_serverProcess && m_serverStarted) {
    m_serverProcess->terminate();
    if (!m_serverProcess->waitForFinished(3000)) {
      m_serverProcess->kill();
    }
    m_serverStarted = false;
  }
}

bool WeiboController::isServerRunning() const {
  return m_serverStarted;
}

// ==================== 热搜 ====================

void WeiboController::refreshHotSearch() {
  apiGet("/hot/search", {{"limit", "50"}},
    [this](const QJsonObject &obj) {
      QJsonObject data = obj.value("data").toObject();
      QJsonArray list = data.value("list").toArray();
      m_hotSearchModel->fromJsonArray(list);
      emit hotSearchLoaded();
    }, nullptr, true);
}

// ==================== 微博详情 ====================

void WeiboController::loadStatusDetail(const QString &id) {
  apiGet("/statuses/show", {{"id", id}},
    [this](const QJsonObject &obj) {
      QJsonObject data = obj.value("data").toObject();
      // 解析为 StatusItem
      QJsonArray arr;
      arr.append(data);
      StatusListModel temp;
      temp.fromJsonArray(arr);
      if (temp.rowCount() > 0) {
        // 复制数据
        QModelIndex idx = temp.index(0);
        m_currentStatus.id = idx.data(StatusListModel::IdRole).toString();
        m_currentStatus.text = idx.data(StatusListModel::TextRole).toString();
        m_currentStatus.user.screenName = idx.data(StatusListModel::UserNameRole).toString();
        m_currentStatus.user.avatarHd = idx.data(StatusListModel::UserAvatarRole).toString();
        m_currentStatus.commentsCount = idx.data(StatusListModel::CommentsCountRole).toInt();
        m_currentStatus.attitudesCount = idx.data(StatusListModel::AttitudesCountRole).toInt();
        m_currentStatus.repostsCount = idx.data(StatusListModel::RepostsCountRole).toInt();
        m_currentStatus.isLiked = idx.data(StatusListModel::IsLikedRole).toBool();
        m_currentStatus.hasVideo = idx.data(StatusListModel::HasVideoRole).toBool();
        m_currentStatus.videoCover = idx.data(StatusListModel::VideoCoverRole).toString();
        m_currentStatus.videoDuration = idx.data(StatusListModel::VideoDurationRole).toDouble();
      }
      emit currentStatusChanged();
      emit statusDetailLoaded();
    }, nullptr, true);
}

// ==================== 评论 ====================

void WeiboController::loadComments(const QString &statusId, int page) {
  apiGet("/statuses/comments", {{"id", statusId}, {"page", QString::number(page)}, {"count", "20"}},
    [this](const QJsonObject &obj) {
      QJsonObject data = obj.value("data").toObject();
      QJsonArray list = data.value("list").toArray();
      if (data.value("page").toInt(1) == 1) {
        m_commentModel->fromJsonArray(list);
      } else {
        // 追加
        CommentListModel temp;
        temp.fromJsonArray(list);
        for (int i = 0; i < temp.rowCount(); i++) {
          QModelIndex idx = temp.index(i);
          CommentItem item;
          item.id = idx.data(CommentListModel::IdRole).toLongLong();
          item.text = idx.data(CommentListModel::TextRole).toString();
          item.user.screenName = idx.data(CommentListModel::UserNameRole).toString();
          item.user.avatarHd = idx.data(CommentListModel::UserAvatarRole).toString();
          item.likeCount = idx.data(CommentListModel::LikeCountRole).toInt();
          item.liked = idx.data(CommentListModel::LikedRole).toBool();
          item.replyCount = idx.data(CommentListModel::ReplyCountRole).toInt();
          item.createdAt = idx.data(CommentListModel::CreatedAtRole).toString();
          m_commentModel->append(item);
        }
      }
      emit commentsLoaded();
    });
}

void WeiboController::loadCommentReplies(const QString &statusId, const QString &commentId, int page) {
  apiGet("/statuses/comments/replies",
    {{"status_id", statusId}, {"comment_id", commentId}, {"page", QString::number(page)}, {"count", "20"}},
    [this](const QJsonObject &obj) {
      QJsonObject data = obj.value("data").toObject();
      QJsonArray list = data.value("list").toArray();
      m_commentReplyModel->fromJsonArray(list);
      emit commentRepliesLoaded();
    });
}

void WeiboController::toggleStatusLike(const QString &id, bool like) {
  apiGet("/statuses/like/toggle", {{"id", id}, {"like", like ? "1" : "0"}},
    [this, like](const QJsonObject &obj) {
      m_currentStatus.isLiked = like;
      if (like) m_currentStatus.attitudesCount++;
      else m_currentStatus.attitudesCount = qMax(0, m_currentStatus.attitudesCount - 1);
      emit currentStatusChanged();
      emit toastMessage(like ? "已点赞" : "已取消点赞");
    });
}

void WeiboController::toggleCommentLike(const QString &id, bool like) {
  apiGet("/comment/like/toggle", {{"id", id}, {"like", like ? "1" : "0"}},
    [this, like](const QJsonObject &obj) {
      emit toastMessage(like ? "已点赞" : "已取消点赞");
    });
}

// ==================== 超话 ====================

void WeiboController::loadSuperTopicList(int page) {
  apiGet("/supertopic/list", {{"page", QString::number(page)}},
    [this](const QJsonObject &obj) {
      QJsonObject data = obj.value("data").toObject();
      QJsonArray list = data.value("list").toArray();
      m_superTopicModel->fromJsonArray(list);
      emit superTopicListLoaded();
    }, nullptr, true);
}

void WeiboController::superTopicCheckin(const QString &topicId) {
  apiGet("/supertopic/checkin", {{"topic_id", topicId}},
    [this](const QJsonObject &obj) {
      QJsonObject data = obj.value("data").toObject();
      bool success = data.value("success").toBool(false);
      QString message = data.value("message").toString("");
      emit superTopicCheckinResult(success, message);
      emit toastMessage(success ? "签到成功" : message);
    });
}

void WeiboController::superTopicBatchCheckin() {
  emit toastMessage("开始批量签到...");
  apiGet("/supertopic/checkin/batch", {},
    [this](const QJsonObject &obj) {
      QJsonObject data = obj.value("data").toObject();
      int total = data.value("total").toInt(0);
      emit toastMessage(QString("批量签到完成，共 %1 个超话").arg(total));
      // 刷新列表
      loadSuperTopicList(1);
    });
}

// ==================== 搜索 ====================

void WeiboController::searchStatus(const QString &keyword, int page) {
  apiGet("/search/status", {{"q", keyword}, {"page", QString::number(page)}},
    [this](const QJsonObject &obj) {
      QJsonObject data = obj.value("data").toObject();
      QJsonArray list = data.value("list").toArray();
      m_searchStatusModel->fromJsonArray(list);
      emit searchResultLoaded();
    }, nullptr, true);
}

void WeiboController::searchUser(const QString &keyword, int page) {
  apiGet("/search/user", {{"q", keyword}, {"page", QString::number(page)}},
    [this](const QJsonObject &obj) {
      QJsonObject data = obj.value("data").toObject();
      QJsonArray list = data.value("list").toArray();
      m_searchUserModel->fromJsonArray(list);
      emit searchResultLoaded();
    }, nullptr, true);
}

// ==================== 用户 ====================

void WeiboController::loadUserInfo(const QString &uid) {
  apiGet("/user/info", {{"uid", uid}},
    [this](const QJsonObject &obj) {
      QJsonObject data = obj.value("data").toObject();
      emit userInfoLoaded();
    });
}

void WeiboController::loadUserStatuses(const QString &uid, int page) {
  apiGet("/user/statuses", {{"uid", uid}, {"page", QString::number(page)}},
    [this](const QJsonObject &obj) {
      QJsonObject data = obj.value("data").toObject();
      QJsonArray list = data.value("list").toArray();
      m_userStatusModel->fromJsonArray(list);
      emit userStatusesLoaded();
    }, nullptr, true);
}

void WeiboController::loadMyStatuses(int page) {
  apiGet("/profile/statuses", {{"page", QString::number(page)}},
    [this](const QJsonObject &obj) {
      QJsonObject data = obj.value("data").toObject();
      QJsonArray list = data.value("list").toArray();
      m_userStatusModel->fromJsonArray(list);
      emit userStatusesLoaded();
    }, nullptr, true);
}

void WeiboController::toggleFollow(const QString &uid, bool follow) {
  apiGet("/user/follow/toggle", {{"uid", uid}, {"follow", follow ? "1" : "0"}},
    [this, follow](const QJsonObject &obj) {
      emit toastMessage(follow ? "已关注" : "已取消关注");
    });
}

// ==================== 登录 ====================

void WeiboController::checkLogin() {
  apiGet("/login/info", {},
    [this](const QJsonObject &obj) {
      QJsonObject data = obj.value("data").toObject();
      bool loggedIn = data.value("logged_in").toBool(false);
      m_loggedIn = loggedIn;
      if (loggedIn) {
        m_userName = data.value("nickname").toString("");
        m_userAvatar = data.value("avatar").toString("");
        m_userId = data.value("uid").toString("");
        m_userFollowers = data.value("followers_count").toInt(0);
        m_userFollowing = data.value("friends_count").toInt(0);
        m_userStatuses = data.value("statuses_count").toInt(0);
      }
      emit loginStateChanged();
    });
}

void WeiboController::importCookie(const QString &cookie) {
  QMap<QString, QString> params;
  params["cookie"] = cookie;
  m_network->post("/login/import", params,
    [this](const QJsonObject &obj) {
      emit toastMessage("登录成功");
      checkLogin();
    },
    [this](int code, const QString &msg) {
      setGlobalError("登录失败: " + msg);
    });
}

void WeiboController::logout() {
  apiGet("/logout", {},
    [this](const QJsonObject &obj) {
      m_loggedIn = false;
      m_userName = "";
      m_userAvatar = "";
      m_userId = "";
      emit loginStateChanged();
      emit toastMessage("已退出登录");
    });
}

void WeiboController::loadLoginStatus() {
  checkLogin();
}

// ==================== 模块访问 ====================

QObject *WeiboController::viewer() const {
  return m_viewerModule;
}

QObject *WeiboController::playback() const {
  return m_playbackModule;
}

void WeiboController::setPlayResult(const QString &url, const QString &title, int duration) {
  m_playUrl = url;
  m_playTitle = title;
  m_playDuration = duration;
  emit playUrlChanged();
}
