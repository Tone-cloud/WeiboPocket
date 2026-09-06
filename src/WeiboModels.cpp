#include "WeiboModels.h"

#include <QJsonValue>
#include <QJsonArray>
#include <QJsonObject>

// ==================== 工具函数 ====================

static QString jsonString(const QJsonObject &obj, const QString &key) {
  return obj.value(key).toString("");
}

static int jsonInt(const QJsonObject &obj, const QString &key) {
  return obj.value(key).toInt(0);
}

static qint64 jsonInt64(const QJsonObject &obj, const QString &key) {
  return obj.value(key).toVariant().toLongLong();
}

static bool jsonBool(const QJsonObject &obj, const QString &key) {
  return obj.value(key).toBool(false);
}

// ==================== HotSearchModel ====================

HotSearchModel::HotSearchModel(QObject *parent) : QAbstractListModel(parent) {}

int HotSearchModel::rowCount(const QModelIndex &parent) const {
  if (parent.isValid()) return 0;
  return m_items.size();
}

QVariant HotSearchModel::data(const QModelIndex &index, int role) const {
  if (!index.isValid() || index.row() >= m_items.size()) return QVariant();
  const HotSearchItem &item = m_items.at(index.row());
  switch (role) {
    case RankRole: return item.rank;
    case WordRole: return item.word;
    case HotNumRole: return item.hotNum;
    case HotNumStrRole: return item.hotNumStr;
    case CategoryRole: return item.category;
    case IconDescRole: return item.iconDesc;
    case IsNewRole: return item.isNew;
    case IsHotRole: return item.isHot;
    case IsBoilRole: return item.isBoil;
    case LabelNameRole: return item.labelName;
    case UrlRole: return item.url;
  }
  return QVariant();
}

QHash<int, QByteArray> HotSearchModel::roleNames() const {
  QHash<int, QByteArray> roles;
  roles[RankRole] = "rank";
  roles[WordRole] = "word";
  roles[HotNumRole] = "hotNum";
  roles[HotNumStrRole] = "hotNumStr";
  roles[CategoryRole] = "category";
  roles[IconDescRole] = "iconDesc";
  roles[IsNewRole] = "isNew";
  roles[IsHotRole] = "isHot";
  roles[IsBoilRole] = "isBoil";
  roles[LabelNameRole] = "labelName";
  roles[UrlRole] = "url";
  return roles;
}

void HotSearchModel::clear() {
  beginResetModel();
  m_items.clear();
  endResetModel();
}

void HotSearchModel::append(const HotSearchItem &item) {
  beginInsertRows(QModelIndex(), m_items.size(), m_items.size());
  m_items.append(item);
  endInsertRows();
}

void HotSearchModel::appendList(const QList<HotSearchItem> &list) {
  if (list.isEmpty()) return;
  beginInsertRows(QModelIndex(), m_items.size(), m_items.size() + list.size() - 1);
  m_items.append(list);
  endInsertRows();
}

void HotSearchModel::fromJsonArray(const QJsonArray &array) {
  clear();
  QList<HotSearchItem> list;
  for (const QJsonValue &val : array) {
    if (!val.isObject()) continue;
    QJsonObject obj = val.toObject();
    HotSearchItem item;
    item.rank = jsonInt(obj, "rank");
    item.word = jsonString(obj, "word");
    item.hotNum = jsonInt64(obj, "hot_num");
    item.hotNumStr = jsonString(obj, "hot_num_str");
    item.category = jsonString(obj, "category");
    item.iconDesc = jsonString(obj, "icon_desc");
    item.isNew = jsonBool(obj, "is_new");
    item.isHot = jsonBool(obj, "is_hot");
    item.isBoil = jsonBool(obj, "is_boil");
    item.labelName = jsonString(obj, "label_name");
    item.url = jsonString(obj, "url");
    list.append(item);
  }
  appendList(list);
}

// ==================== StatusListModel ====================

static StatusUser parseStatusUser(const QJsonObject &obj) {
  StatusUser user;
  user.id = jsonInt64(obj, "id");
  user.idStr = jsonString(obj, "idstr");
  user.screenName = jsonString(obj, "screen_name");
  user.profileUrl = jsonString(obj, "profile_url");
  user.avatarHd = jsonString(obj, "avatar_hd");
  if (user.avatarHd.isEmpty()) user.avatarHd = jsonString(obj, "avatar_large");
  user.description = jsonString(obj, "description");
  user.followersCount = jsonInt(obj, "followers_count");
  user.friendsCount = jsonInt(obj, "friends_count");
  user.statusesCount = jsonInt(obj, "statuses_count");
  user.verified = jsonBool(obj, "verified");
  user.verifiedReason = jsonString(obj, "verified_reason");
  return user;
}

static StatusPic parseStatusPic(const QJsonObject &obj) {
  StatusPic pic;
  pic.pid = jsonString(obj, "pid");
  pic.url = jsonString(obj, "url");
  pic.largeUrl = jsonString(obj, "large_url");
  QJsonObject geo = obj.value("geo").toObject();
  pic.width = jsonInt(geo, "width");
  pic.height = jsonInt(geo, "height");
  return pic;
}

StatusListModel::StatusListModel(QObject *parent) : QAbstractListModel(parent) {}

StatusListModel::~StatusListModel() {
  clear();
}

int StatusListModel::rowCount(const QModelIndex &parent) const {
  if (parent.isValid()) return 0;
  return m_items.size();
}

QVariant StatusListModel::data(const QModelIndex &index, int role) const {
  if (!index.isValid() || index.row() >= m_items.size()) return QVariant();
  const StatusItem *item = m_items.at(index.row());
  switch (role) {
    case IdRole: return item->id;
    case TextRole: return item->text;
    case TextRawRole: return item->textRaw;
    case SourceRole: return item->source;
    case CreatedAtRole: return item->createdAt;
    case RepostsCountRole: return item->repostsCount;
    case CommentsCountRole: return item->commentsCount;
    case AttitudesCountRole: return item->attitudesCount;
    case IsLikedRole: return item->isLiked;
    case PicsRole: {
      QStringList urls;
      for (const StatusPic &p : item->pics) urls << (p.largeUrl.isEmpty() ? p.url : p.largeUrl);
      return urls;
    }
    case PicCountRole: return item->pics.size();
    case FirstPicRole: {
      if (item->pics.isEmpty()) return QString();
      const StatusPic &p = item->pics.first();
      return p.largeUrl.isEmpty() ? p.url : p.largeUrl;
    }
    case UserNameRole: return item->user.screenName;
    case UserAvatarRole: return item->user.avatarHd;
    case UserIdRole: return item->user.id;
    case HasRetweetedRole: return item->hasRetweeted;
    case RetweetedTextRole: return item->retweeted ? item->retweeted->text : QString();
    case RetweetedUserNameRole: return item->retweeted ? item->retweeted->user.screenName : QString();
    case RetweetedPicsRole: {
      if (!item->retweeted) return QStringList();
      QStringList urls;
      for (const StatusPic &p : item->retweeted->pics) urls << p.largeUrl.isEmpty() ? p.url : p.largeUrl;
      return urls;
    }
    case HasVideoRole: return item->hasVideo;
    case VideoTitleRole: return item->videoTitle;
    case VideoCoverRole: return item->videoCover;
    case VideoDurationRole: return item->videoDuration;
  }
  return QVariant();
}

QHash<int, QByteArray> StatusListModel::roleNames() const {
  QHash<int, QByteArray> roles;
  roles[IdRole] = "id";
  roles[TextRole] = "text";
  roles[TextRawRole] = "textRaw";
  roles[SourceRole] = "source";
  roles[CreatedAtRole] = "createdAt";
  roles[RepostsCountRole] = "repostsCount";
  roles[CommentsCountRole] = "commentsCount";
  roles[AttitudesCountRole] = "attitudesCount";
  roles[IsLikedRole] = "isLiked";
  roles[PicsRole] = "pics";
  roles[PicCountRole] = "picCount";
  roles[FirstPicRole] = "firstPic";
  roles[UserNameRole] = "userName";
  roles[UserAvatarRole] = "userAvatar";
  roles[UserIdRole] = "userId";
  roles[HasRetweetedRole] = "hasRetweeted";
  roles[RetweetedTextRole] = "retweetedText";
  roles[RetweetedUserNameRole] = "retweetedUserName";
  roles[RetweetedPicsRole] = "retweetedPics";
  roles[HasVideoRole] = "hasVideo";
  roles[VideoTitleRole] = "videoTitle";
  roles[VideoCoverRole] = "videoCover";
  roles[VideoDurationRole] = "videoDuration";
  return roles;
}

void StatusListModel::clear() {
  beginResetModel();
  qDeleteAll(m_items);
  m_items.clear();
  endResetModel();
}

void StatusListModel::append(const StatusItem &item) {
  StatusItem *copy = new StatusItem(item);
  if (item.retweeted) {
    copy->retweeted = new StatusItem(*item.retweeted);
  }
  beginInsertRows(QModelIndex(), m_items.size(), m_items.size());
  m_items.append(copy);
  endInsertRows();
}

void StatusListModel::appendList(const QList<StatusItem> &list) {
  if (list.isEmpty()) return;
  beginInsertRows(QModelIndex(), m_items.size(), m_items.size() + list.size() - 1);
  for (const StatusItem &item : list) {
    StatusItem *copy = new StatusItem(item);
    if (item.retweeted) copy->retweeted = new StatusItem(*item.retweeted);
    m_items.append(copy);
  }
  endInsertRows();
}

static StatusItem *parseStatusItem(const QJsonObject &obj) {
  StatusItem *item = new StatusItem();
  item->id = jsonString(obj, "id");
  if (item->id.isEmpty()) item->id = jsonString(obj, "idstr");
  item->idStr = jsonString(obj, "idstr");
  item->mid = jsonString(obj, "mid");
  item->text = jsonString(obj, "text");
  item->textRaw = jsonString(obj, "text_raw");
  if (item->textRaw.isEmpty()) item->textRaw = item->text;
  item->source = jsonString(obj, "source");
  item->createdAt = jsonString(obj, "created_at");
  item->createdTimestamp = jsonInt64(obj, "created_timestamp");
  item->repostsCount = jsonInt(obj, "reposts_count");
  item->commentsCount = jsonInt(obj, "comments_count");
  item->attitudesCount = jsonInt(obj, "attitudes_count");
  item->isLiked = jsonBool(obj, "is_liked");
  item->isFavorited = jsonBool(obj, "is_favorited");

  // 图片
  QJsonArray picsArray = obj.value("pics").toArray();
  for (const QJsonValue &pv : picsArray) {
    if (pv.isObject()) item->pics.append(parseStatusPic(pv.toObject()));
  }

  // 用户
  if (obj.value("user").isObject()) {
    item->user = parseStatusUser(obj.value("user").toObject());
  }

  // 转发
  if (obj.value("retweeted_status").isObject()) {
    QJsonObject rtObj = obj.value("retweeted_status").toObject();
    item->hasRetweeted = true;
    item->retweeted = parseStatusItem(rtObj);
  }

  // 视频
  if (obj.value("page_info").isObject()) {
    QJsonObject pageInfo = obj.value("page_info").toObject();
    QString type = jsonString(pageInfo, "type");
    if (type == "video" || pageInfo.value("media_info").isObject()) {
      item->hasVideo = true;
      item->videoTitle = jsonString(pageInfo, "title");
      item->videoCover = jsonString(pageInfo, "page_pic");
      if (pageInfo.value("media_info").isObject()) {
        QJsonObject media = pageInfo.value("media_info").toObject();
        item->videoStreamUrl = jsonString(media, "stream_url");
        item->videoStreamUrlHd = jsonString(media, "stream_url_hd");
        item->videoDuration = media.value("duration").toDouble(0);
      }
    }
  }

  return item;
}

void StatusListModel::fromJsonArray(const QJsonArray &array) {
  clear();
  QList<StatusItem *> newItems;
  for (const QJsonValue &val : array) {
    if (!val.isObject()) continue;
    newItems.append(parseStatusItem(val.toObject()));
  }
  if (!newItems.isEmpty()) {
    beginInsertRows(QModelIndex(), 0, newItems.size() - 1);
    m_items = newItems;
    endInsertRows();
  }
}

StatusItem *StatusListModel::find(const QString &id) {
  for (StatusItem *item : m_items) {
    if (item->id == id) return item;
  }
  return nullptr;
}

// ==================== CommentListModel ====================

CommentListModel::CommentListModel(QObject *parent) : QAbstractListModel(parent) {}

int CommentListModel::rowCount(const QModelIndex &parent) const {
  if (parent.isValid()) return 0;
  return m_items.size();
}

QVariant CommentListModel::data(const QModelIndex &index, int role) const {
  if (!index.isValid() || index.row() >= m_items.size()) return QVariant();
  const CommentItem &item = m_items.at(index.row());
  switch (role) {
    case IdRole: return item.id;
    case TextRole: return item.text;
    case SourceRole: return item.source;
    case CreatedAtRole: return item.createdAt;
    case LikeCountRole: return item.likeCount;
    case LikedRole: return item.liked;
    case ReplyCountRole: return item.replyCount;
    case UserNameRole: return item.user.screenName;
    case UserAvatarRole: return item.user.avatarHd;
    case HasReplyToRole: return item.hasReplyTo;
    case ReplyToTextRole: return item.replyToText;
    case ReplyToUserNameRole: return item.replyToUserName;
    case PicUrlRole: return item.picUrl;
  }
  return QVariant();
}

QHash<int, QByteArray> CommentListModel::roleNames() const {
  QHash<int, QByteArray> roles;
  roles[IdRole] = "id";
  roles[TextRole] = "text";
  roles[SourceRole] = "source";
  roles[CreatedAtRole] = "createdAt";
  roles[LikeCountRole] = "likeCount";
  roles[LikedRole] = "liked";
  roles[ReplyCountRole] = "replyCount";
  roles[UserNameRole] = "userName";
  roles[UserAvatarRole] = "userAvatar";
  roles[HasReplyToRole] = "hasReplyTo";
  roles[ReplyToTextRole] = "replyToText";
  roles[ReplyToUserNameRole] = "replyToUserName";
  roles[PicUrlRole] = "picUrl";
  return roles;
}

void CommentListModel::clear() {
  beginResetModel();
  m_items.clear();
  endResetModel();
}

void CommentListModel::append(const CommentItem &item) {
  beginInsertRows(QModelIndex(), m_items.size(), m_items.size());
  m_items.append(item);
  endInsertRows();
}

void CommentListModel::appendList(const QList<CommentItem> &list) {
  if (list.isEmpty()) return;
  beginInsertRows(QModelIndex(), m_items.size(), m_items.size() + list.size() - 1);
  m_items.append(list);
  endInsertRows();
}

void CommentListModel::fromJsonArray(const QJsonArray &array) {
  clear();
  QList<CommentItem> list;
  for (const QJsonValue &val : array) {
    if (!val.isObject()) continue;
    QJsonObject obj = val.toObject();
    CommentItem item;
    item.id = jsonInt64(obj, "id");
    item.idStr = jsonString(obj, "idstr");
    item.text = jsonString(obj, "text");
    item.source = jsonString(obj, "source");
    item.createdAt = jsonString(obj, "created_at");
    item.likeCount = jsonInt(obj, "like_count");
    item.liked = jsonBool(obj, "liked");
    item.replyCount = jsonInt(obj, "reply_count");
    if (obj.value("user").isObject()) {
      QJsonObject u = obj.value("user").toObject();
      item.user.id = jsonInt64(u, "id");
      item.user.screenName = jsonString(u, "screen_name");
      item.user.avatarHd = jsonString(u, "avatar_hd");
    }
    if (obj.value("reply_to").isObject()) {
      QJsonObject rt = obj.value("reply_to").toObject();
      item.hasReplyTo = true;
      item.replyToText = jsonString(rt, "text");
      if (rt.value("user").isObject()) {
        item.replyToUserName = jsonString(rt.value("user").toObject(), "screen_name");
      }
    }
    // 评论图片
    if (obj.value("pic_urls").isArray()) {
      QJsonArray pics = obj.value("pic_urls").toArray();
      if (!pics.isEmpty() && pics.at(0).isObject()) {
        item.picUrl = jsonString(pics.at(0).toObject(), "thumbnail_pic");
        if (item.picUrl.isEmpty()) {
          item.picUrl = jsonString(pics.at(0).toObject(), "url");
        }
      }
    }
    if (item.picUrl.isEmpty() && obj.value("pic_infos").isObject()) {
      QJsonObject picInfos = obj.value("pic_infos").toObject();
      if (!picInfos.isEmpty()) {
        QString firstKey = picInfos.keys().first();
        QJsonObject firstPic = picInfos.value(firstKey).toObject();
        if (firstPic.value("largest").isObject()) {
          item.picUrl = jsonString(firstPic.value("largest").toObject(), "url");
        } else if (firstPic.value("mw_2000").isObject()) {
          item.picUrl = jsonString(firstPic.value("mw_2000").toObject(), "url");
        }
      }
    }
    list.append(item);
  }
  appendList(list);
}

// ==================== SuperTopicModel ====================

SuperTopicModel::SuperTopicModel(QObject *parent) : QAbstractListModel(parent) {}

int SuperTopicModel::rowCount(const QModelIndex &parent) const {
  if (parent.isValid()) return 0;
  return m_items.size();
}

QVariant SuperTopicModel::data(const QModelIndex &index, int role) const {
  if (!index.isValid() || index.row() >= m_items.size()) return QVariant();
  const SuperTopicItem &item = m_items.at(index.row());
  switch (role) {
    case IdRole: return item.id;
    case TitleRole: return item.title;
    case CoverPicRole: return item.coverPic;
    case Desc1Role: return item.desc1;
    case Desc2Role: return item.desc2;
    case RankRole: return item.rank;
    case IsSignedRole: return item.isSigned;
    case SignStatusRole: return item.signStatus;
    case LevelRole: return item.level;
    case LevelNameRole: return item.levelName;
    case ContinuousSignRole: return item.continuousSign;
    case TopicIdRole: return item.topicId;
    case ReadCountRole: return item.readCount;
  }
  return QVariant();
}

QHash<int, QByteArray> SuperTopicModel::roleNames() const {
  QHash<int, QByteArray> roles;
  roles[IdRole] = "id";
  roles[TitleRole] = "title";
  roles[CoverPicRole] = "coverPic";
  roles[Desc1Role] = "desc1";
  roles[Desc2Role] = "desc2";
  roles[RankRole] = "rank";
  roles[IsSignedRole] = "isSigned";
  roles[SignStatusRole] = "signStatus";
  roles[LevelRole] = "level";
  roles[LevelNameRole] = "levelName";
  roles[ContinuousSignRole] = "continuousSign";
  roles[TopicIdRole] = "topicId";
  roles[ReadCountRole] = "readCount";
  return roles;
}

void SuperTopicModel::clear() {
  beginResetModel();
  m_items.clear();
  endResetModel();
}

void SuperTopicModel::append(const SuperTopicItem &item) {
  beginInsertRows(QModelIndex(), m_items.size(), m_items.size());
  m_items.append(item);
  endInsertRows();
}

void SuperTopicModel::appendList(const QList<SuperTopicItem> &list) {
  if (list.isEmpty()) return;
  beginInsertRows(QModelIndex(), m_items.size(), m_items.size() + list.size() - 1);
  m_items.append(list);
  endInsertRows();
}

void SuperTopicModel::fromJsonArray(const QJsonArray &array) {
  clear();
  QList<SuperTopicItem> list;
  for (const QJsonValue &val : array) {
    if (!val.isObject()) continue;
    QJsonObject obj = val.toObject();
    SuperTopicItem item;
    item.id = jsonString(obj, "id");
    item.title = jsonString(obj, "title");
    item.titleUrl = jsonString(obj, "title_url");
    item.coverPic = jsonString(obj, "cover_pic");
    item.desc1 = jsonString(obj, "desc1");
    item.desc2 = jsonString(obj, "desc2");
    item.readCount = jsonString(obj, "read_count");
    item.postCount = jsonString(obj, "post_count");
    item.followCount = jsonString(obj, "follow_count");
    item.rank = jsonInt(obj, "rank");
    item.isSigned = jsonBool(obj, "is_signed");
    item.signStatus = jsonString(obj, "sign_status");
    item.level = jsonInt(obj, "level");
    item.levelName = jsonString(obj, "level_name");
    item.continuousSign = jsonInt(obj, "continuous_sign");
    item.topicId = jsonString(obj, "topic_id");
    list.append(item);
  }
  appendList(list);
}

// ==================== SearchUserModel ====================

SearchUserModel::SearchUserModel(QObject *parent) : QAbstractListModel(parent) {}

int SearchUserModel::rowCount(const QModelIndex &parent) const {
  if (parent.isValid()) return 0;
  return m_items.size();
}

QVariant SearchUserModel::data(const QModelIndex &index, int role) const {
  if (!index.isValid() || index.row() >= m_items.size()) return QVariant();
  const SearchUserItem &item = m_items.at(index.row());
  switch (role) {
    case IdRole: return item.id;
    case ScreenNameRole: return item.screenName;
    case AvatarHdRole: return item.avatarHd;
    case DescriptionRole: return item.description;
    case FollowersCountRole: return item.followersCount;
    case VerifiedRole: return item.verified;
    case VerifiedReasonRole: return item.verifiedReason;
    case FollowingRole: return item.following;
  }
  return QVariant();
}

QHash<int, QByteArray> SearchUserModel::roleNames() const {
  QHash<int, QByteArray> roles;
  roles[IdRole] = "id";
  roles[ScreenNameRole] = "screenName";
  roles[AvatarHdRole] = "avatarHd";
  roles[DescriptionRole] = "description";
  roles[FollowersCountRole] = "followersCount";
  roles[VerifiedRole] = "verified";
  roles[VerifiedReasonRole] = "verifiedReason";
  roles[FollowingRole] = "following";
  return roles;
}

void SearchUserModel::clear() {
  beginResetModel();
  m_items.clear();
  endResetModel();
}

void SearchUserModel::append(const SearchUserItem &item) {
  beginInsertRows(QModelIndex(), m_items.size(), m_items.size());
  m_items.append(item);
  endInsertRows();
}

void SearchUserModel::appendList(const QList<SearchUserItem> &list) {
  if (list.isEmpty()) return;
  beginInsertRows(QModelIndex(), m_items.size(), m_items.size() + list.size() - 1);
  m_items.append(list);
  endInsertRows();
}

void SearchUserModel::fromJsonArray(const QJsonArray &array) {
  clear();
  QList<SearchUserItem> list;
  for (const QJsonValue &val : array) {
    if (!val.isObject()) continue;
    QJsonObject obj = val.toObject();
    SearchUserItem item;
    item.id = jsonInt64(obj, "id");
    item.screenName = jsonString(obj, "screen_name");
    item.avatarHd = jsonString(obj, "avatar_hd");
    item.description = jsonString(obj, "description");
    item.followersCount = jsonInt(obj, "followers_count");
    item.verified = jsonBool(obj, "verified");
    item.verifiedReason = jsonString(obj, "verified_reason");
    item.following = jsonBool(obj, "following");
    list.append(item);
  }
  appendList(list);
}
