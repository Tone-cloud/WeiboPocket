#pragma once

#include <QObject>
#include <QJsonObject>
#include <QString>
#include <QMap>
#include <QPointer>
#include <QProcess>
#include <QTimer>
#include <functional>
#include <memory>

#include "WeiboModels.h"

class WeiboNetwork;
class WeiboImageProvider;
class WeiboViewerModule;
class WeiboPlaybackModule;

// 轻量模块对象，用于 QML 属性暴露
class WeiboModule : public QObject {
  Q_OBJECT
public:
  explicit WeiboModule(QObject *parent = nullptr) : QObject(parent) {}
};

class WeiboController : public QObject {
  Q_OBJECT

  friend class WeiboPlaybackModule;
  friend class WeiboViewerModule;

  // 模块属性
  Q_PROPERTY(QObject *hot READ hot CONSTANT)
  Q_PROPERTY(QObject *status READ status CONSTANT)
  Q_PROPERTY(QObject *comment READ comment CONSTANT)
  Q_PROPERTY(QObject *supertopic READ supertopic CONSTANT)
  Q_PROPERTY(QObject *video READ video CONSTANT)
  Q_PROPERTY(QObject *search READ search CONSTANT)
  Q_PROPERTY(QObject *user READ user CONSTANT)
  Q_PROPERTY(QObject *auth READ auth CONSTANT)
  Q_PROPERTY(QObject *viewer READ viewer CONSTANT)
  Q_PROPERTY(QObject *playback READ playback CONSTANT)

  // 播放状态
  Q_PROPERTY(QString playUrl READ playUrl NOTIFY playUrlChanged)
  Q_PROPERTY(QString playTitle READ playTitle NOTIFY playUrlChanged)
  Q_PROPERTY(int playDuration READ playDuration NOTIFY playUrlChanged)
  Q_PROPERTY(QString playbackProgressText READ playbackProgressText NOTIFY playbackProgressChanged)

  // 登录状态
  Q_PROPERTY(bool loggedIn READ loggedIn NOTIFY loginStateChanged)
  Q_PROPERTY(QString userName READ userName NOTIFY loginStateChanged)
  Q_PROPERTY(QString userAvatar READ userAvatar NOTIFY loginStateChanged)
  Q_PROPERTY(QString userId READ userId NOTIFY loginStateChanged)
  Q_PROPERTY(int userFollowers READ userFollowers NOTIFY loginStateChanged)
  Q_PROPERTY(int userFollowing READ userFollowing NOTIFY loginStateChanged)
  Q_PROPERTY(int userStatuses READ userStatuses NOTIFY loginStateChanged)

  // 当前微博详情
  Q_PROPERTY(QString currentStatusId READ currentStatusId NOTIFY currentStatusChanged)
  Q_PROPERTY(QString currentStatusText READ currentStatusText NOTIFY currentStatusChanged)
  Q_PROPERTY(QString currentStatusUser READ currentStatusUser NOTIFY currentStatusChanged)
  Q_PROPERTY(QString currentStatusAvatar READ currentStatusAvatar NOTIFY currentStatusChanged)
  Q_PROPERTY(int currentStatusComments READ currentStatusComments NOTIFY currentStatusChanged)
  Q_PROPERTY(int currentStatusLikes READ currentStatusLikes NOTIFY currentStatusChanged)
  Q_PROPERTY(int currentStatusReposts READ currentStatusReposts NOTIFY currentStatusChanged)
  Q_PROPERTY(bool currentStatusLiked READ currentStatusLiked NOTIFY currentStatusChanged)
  Q_PROPERTY(bool currentStatusHasVideo READ currentStatusHasVideo NOTIFY currentStatusChanged)
  Q_PROPERTY(QString currentStatusVideoUrl READ currentStatusVideoUrl NOTIFY currentStatusChanged)
  Q_PROPERTY(QString currentStatusVideoCover READ currentStatusVideoCover NOTIFY currentStatusChanged)
  Q_PROPERTY(double currentStatusVideoDuration READ currentStatusVideoDuration NOTIFY currentStatusChanged)

  // 全局状态
  Q_PROPERTY(QString globalError READ globalError NOTIFY globalErrorChanged)
  Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

public:
  explicit WeiboController(QObject *parent = nullptr);
  ~WeiboController();

  // 属性 getter
  bool loggedIn() const { return m_loggedIn; }
  QString userName() const { return m_userName; }
  QString userAvatar() const { return m_userAvatar; }
  QString userId() const { return m_userId; }
  int userFollowers() const { return m_userFollowers; }
  int userFollowing() const { return m_userFollowing; }
  int userStatuses() const { return m_userStatuses; }

  QString currentStatusId() const { return m_currentStatus.id; }
  QString currentStatusText() const { return m_currentStatus.text; }
  QString currentStatusUser() const { return m_currentStatus.user.screenName; }
  QString currentStatusAvatar() const { return m_currentStatus.user.avatarHd; }
  int currentStatusComments() const { return m_currentStatus.commentsCount; }
  int currentStatusLikes() const { return m_currentStatus.attitudesCount; }
  int currentStatusReposts() const { return m_currentStatus.repostsCount; }
  bool currentStatusLiked() const { return m_currentStatus.isLiked; }
  bool currentStatusHasVideo() const { return m_currentStatus.hasVideo; }
  QString currentStatusVideoUrl() const { return m_currentStatus.videoStreamUrl; }
  QString currentStatusVideoCover() const { return m_currentStatus.videoCover; }
  double currentStatusVideoDuration() const { return m_currentStatus.videoDuration; }

  QString globalError() const { return m_globalError; }
  bool isLoading() const { return m_isLoading; }

  // 模型访问
  HotSearchModel *hotSearchModel() const { return m_hotSearchModel; }
  StatusListModel *statusListModel() const { return m_statusListModel; }
  StatusListModel *searchStatusModel() const { return m_searchStatusModel; }
  StatusListModel *userStatusModel() const { return m_userStatusModel; }
  CommentListModel *commentListModel() const { return m_commentModel; }
  CommentListModel *commentReplyModel() const { return m_commentReplyModel; }
  SuperTopicModel *superTopicModel() const { return m_superTopicModel; }
  SearchUserModel *searchUserModel() const { return m_searchUserModel; }

  WeiboNetwork *network() const { return m_network; }

  // 模块对象（QML 访问）
  QObject *hot() const { return m_hotObj; }
  QObject *status() const { return m_statusObj; }
  QObject *comment() const { return m_commentObj; }
  QObject *supertopic() const { return m_superTopicObj; }
  QObject *video() const { return m_videoObj; }
  QObject *search() const { return m_searchObj; }
  QObject *user() const { return m_userObj; }
  QObject *auth() const { return m_authObj; }
  QObject *viewer() const;
  QObject *playback() const;

  // 播放状态 getter
  QString playUrl() const { return m_playUrl; }
  QString playTitle() const { return m_playTitle; }
  int playDuration() const { return m_playDuration; }
  QString playbackProgressText() const { return m_playbackProgressText; }

  // 设置播放结果（供 playback 模块调用）
  void setPlayResult(const QString &url, const QString &title, int duration);

  // API 调用辅助
  void apiGet(const QString &path,
              const QMap<QString, QString> &params,
              std::function<void(const QJsonObject &)> onSuccess,
              std::function<void(int, const QString &)> onError = nullptr,
              bool withLoading = false);

  void apiPost(const QString &path,
               const QMap<QString, QString> &params,
               std::function<void(const QJsonObject &)> onSuccess,
               std::function<void(int, const QString &)> onError = nullptr);

  // Q_INVOKABLE 方法
  Q_INVOKABLE void clearError();
  Q_INVOKABLE void cancelAll();
  Q_INVOKABLE void startServer();
  Q_INVOKABLE void stopServer();
  Q_INVOKABLE bool isServerRunning() const;

  // 业务方法
  Q_INVOKABLE void refreshHotSearch();
  Q_INVOKABLE void loadStatusDetail(const QString &id);
  Q_INVOKABLE void loadComments(const QString &statusId, int page = 1);
  Q_INVOKABLE void loadCommentReplies(const QString &statusId, const QString &commentId, int page = 1);
  Q_INVOKABLE void toggleStatusLike(const QString &id, bool like);
  Q_INVOKABLE void toggleCommentLike(const QString &id, bool like);
  Q_INVOKABLE void loadSuperTopicList(int page = 1);
  Q_INVOKABLE void superTopicCheckin(const QString &topicId);
  Q_INVOKABLE void superTopicBatchCheckin();
  Q_INVOKABLE void searchStatus(const QString &keyword, int page = 1);
  Q_INVOKABLE void searchUser(const QString &keyword, int page = 1);
  Q_INVOKABLE void loadUserInfo(const QString &uid);
  Q_INVOKABLE void loadUserStatuses(const QString &uid, int page = 1);
  Q_INVOKABLE void loadMyStatuses(int page = 1);
  Q_INVOKABLE void checkLogin();
  Q_INVOKABLE void importCookie(const QString &cookie);
  Q_INVOKABLE void logout();
  Q_INVOKABLE void toggleFollow(const QString &uid, bool follow);

signals:
  void loginStateChanged();
  void currentStatusChanged();
  void globalErrorChanged();
  void isLoadingChanged();
  void toastMessage(const QString &message);
  void hotSearchLoaded();
  void statusDetailLoaded();
  void commentsLoaded();
  void commentRepliesLoaded();
  void superTopicListLoaded();
  void superTopicCheckinResult(bool success, const QString &message);
  void searchResultLoaded();
  void userInfoLoaded();
  void userStatusesLoaded();
  void videoPlayReady(const QString &url);
  void commentImageReadyForViewer(const QString &localPath);
  void playbackReady(const QString &url);
  void playUrlChanged();
  void playbackProgressChanged();

private:
  void setGlobalError(const QString &error);
  void setIsLoading(bool loading);
  void loadLoginStatus();

  WeiboNetwork *m_network;
  WeiboImageProvider *m_imageProvider;
  WeiboViewerModule *m_viewerModule;
  WeiboPlaybackModule *m_playbackModule;

  // 模型
  HotSearchModel *m_hotSearchModel;
  StatusListModel *m_statusListModel;
  StatusListModel *m_searchStatusModel;
  StatusListModel *m_userStatusModel;
  CommentListModel *m_commentModel;
  CommentListModel *m_commentReplyModel;
  SuperTopicModel *m_superTopicModel;
  SearchUserModel *m_searchUserModel;

  // QML 模块对象
  QObject *m_hotObj;
  QObject *m_statusObj;
  QObject *m_commentObj;
  QObject *m_superTopicObj;
  QObject *m_videoObj;
  QObject *m_searchObj;
  QObject *m_userObj;
  QObject *m_authObj;

  // 登录状态
  bool m_loggedIn;
  QString m_userName;
  QString m_userAvatar;
  QString m_userId;
  int m_userFollowers;
  int m_userFollowing;
  int m_userStatuses;

  // 当前微博
  StatusItem m_currentStatus;

  // 全局状态
  QString m_globalError;
  bool m_isLoading;
  int m_loadingCount;

  // 播放状态
  QString m_playUrl;
  QString m_playTitle;
  int m_playDuration;
  QString m_playbackProgressText;

  // 外部播放器进程
  QPointer<QProcess> m_externalPlayerProcess;

  // 服务器进程
  QPointer<QProcess> m_serverProcess;
  bool m_serverStarted;
};
