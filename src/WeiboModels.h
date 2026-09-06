#pragma once

#include <QAbstractListModel>
#include <QObject>
#include <QString>
#include <QVariant>
#include <QJsonArray>
#include <QJsonObject>
#include <QList>

// ==================== 热搜模型 ====================

struct HotSearchItem {
  int rank = 0;
  QString word;
  qint64 hotNum = 0;
  QString hotNumStr;
  QString category;
  QString iconDesc;
  bool isNew = false;
  bool isHot = false;
  bool isBoil = false;
  QString labelName;
  QString url;
};

class HotSearchModel : public QAbstractListModel {
  Q_OBJECT
public:
  enum Roles {
    RankRole = Qt::UserRole + 1,
    WordRole,
    HotNumRole,
    HotNumStrRole,
    CategoryRole,
    IconDescRole,
    IsNewRole,
    IsHotRole,
    IsBoilRole,
    LabelNameRole,
    UrlRole,
  };

  explicit HotSearchModel(QObject *parent = nullptr);

  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
  QHash<int, QByteArray> roleNames() const override;

  void clear();
  void append(const HotSearchItem &item);
  void appendList(const QList<HotSearchItem> &list);
  void fromJsonArray(const QJsonArray &array);

private:
  QList<HotSearchItem> m_items;
};

// ==================== 微博模型 ====================

struct StatusPic {
  QString pid;
  QString url;
  QString largeUrl;
  int width = 0;
  int height = 0;
};

struct StatusUser {
  qint64 id = 0;
  QString idStr;
  QString screenName;
  QString profileUrl;
  QString avatarHd;
  QString description;
  int followersCount = 0;
  int friendsCount = 0;
  int statusesCount = 0;
  bool verified = false;
  QString verifiedReason;
};

struct StatusItem {
  QString id;
  QString idStr;
  QString mid;
  QString text;
  QString textRaw;
  QString source;
  QString createdAt;
  qint64 createdTimestamp = 0;
  int repostsCount = 0;
  int commentsCount = 0;
  int attitudesCount = 0;
  bool isLiked = false;
  bool isFavorited = false;
  QList<StatusPic> pics;
  StatusUser user;
  bool hasRetweeted = false;
  StatusItem *retweeted = nullptr;
  bool hasVideo = false;
  QString videoTitle;
  QString videoCover;
  QString videoStreamUrl;
  QString videoStreamUrlHd;
  double videoDuration = 0;
};

class StatusListModel : public QAbstractListModel {
  Q_OBJECT
public:
  enum Roles {
    IdRole = Qt::UserRole + 1,
    TextRole,
    TextRawRole,
    SourceRole,
    CreatedAtRole,
    RepostsCountRole,
    CommentsCountRole,
    AttitudesCountRole,
    IsLikedRole,
    PicsRole,
    PicCountRole,
    FirstPicRole,
    UserNameRole,
    UserAvatarRole,
    UserIdRole,
    HasRetweetedRole,
    RetweetedTextRole,
    RetweetedUserNameRole,
    RetweetedPicsRole,
    HasVideoRole,
    VideoTitleRole,
    VideoCoverRole,
    VideoDurationRole,
  };

  explicit StatusListModel(QObject *parent = nullptr);
  ~StatusListModel();

  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
  QHash<int, QByteArray> roleNames() const override;

  void clear();
  void append(const StatusItem &item);
  void appendList(const QList<StatusItem> &list);
  void fromJsonArray(const QJsonArray &array);
  StatusItem *find(const QString &id);

private:
  QList<StatusItem *> m_items;
};

// ==================== 评论模型 ====================

struct CommentUser {
  qint64 id = 0;
  QString screenName;
  QString avatarHd;
};

struct CommentItem {
  qint64 id = 0;
  QString idStr;
  QString text;
  QString source;
  QString createdAt;
  int likeCount = 0;
  bool liked = false;
  int replyCount = 0;
  CommentUser user;
  bool hasReplyTo = false;
  QString replyToText;
  QString replyToUserName;
  QString picUrl;
};

class CommentListModel : public QAbstractListModel {
  Q_OBJECT
public:
  enum Roles {
    IdRole = Qt::UserRole + 1,
    TextRole,
    SourceRole,
    CreatedAtRole,
    LikeCountRole,
    LikedRole,
    ReplyCountRole,
    UserNameRole,
    UserAvatarRole,
    HasReplyToRole,
    ReplyToTextRole,
    ReplyToUserNameRole,
    PicUrlRole,
  };

  explicit CommentListModel(QObject *parent = nullptr);

  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
  QHash<int, QByteArray> roleNames() const override;

  void clear();
  void append(const CommentItem &item);
  void appendList(const QList<CommentItem> &list);
  void fromJsonArray(const QJsonArray &array);

private:
  QList<CommentItem> m_items;
};

// ==================== 超话模型 ====================

struct SuperTopicItem {
  QString id;
  QString title;
  QString titleUrl;
  QString coverPic;
  QString desc1;
  QString desc2;
  QString readCount;
  QString postCount;
  QString followCount;
  int rank = 0;
  bool isSigned = false;
  QString signStatus;
  int level = 0;
  QString levelName;
  int continuousSign = 0;
  QString topicId;
};

class SuperTopicModel : public QAbstractListModel {
  Q_OBJECT
public:
  enum Roles {
    IdRole = Qt::UserRole + 1,
    TitleRole,
    CoverPicRole,
    Desc1Role,
    Desc2Role,
    RankRole,
    IsSignedRole,
    SignStatusRole,
    LevelRole,
    LevelNameRole,
    ContinuousSignRole,
    TopicIdRole,
    ReadCountRole,
  };

  explicit SuperTopicModel(QObject *parent = nullptr);

  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
  QHash<int, QByteArray> roleNames() const override;

  void clear();
  void append(const SuperTopicItem &item);
  void appendList(const QList<SuperTopicItem> &list);
  void fromJsonArray(const QJsonArray &array);

private:
  QList<SuperTopicItem> m_items;
};

// ==================== 用户搜索模型 ====================

struct SearchUserItem {
  qint64 id = 0;
  QString screenName;
  QString avatarHd;
  QString description;
  int followersCount = 0;
  bool verified = false;
  QString verifiedReason;
  bool following = false;
};

class SearchUserModel : public QAbstractListModel {
  Q_OBJECT
public:
  enum Roles {
    IdRole = Qt::UserRole + 1,
    ScreenNameRole,
    AvatarHdRole,
    DescriptionRole,
    FollowersCountRole,
    VerifiedRole,
    VerifiedReasonRole,
    FollowingRole,
  };

  explicit SearchUserModel(QObject *parent = nullptr);

  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
  QHash<int, QByteArray> roleNames() const override;

  void clear();
  void append(const SearchUserItem &item);
  void appendList(const QList<SearchUserItem> &list);
  void fromJsonArray(const QJsonArray &array);

private:
  QList<SearchUserItem> m_items;
};
