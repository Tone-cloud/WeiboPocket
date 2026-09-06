#pragma once

#include <QJsonObject>
#include <QJsonArray>
#include <QString>

namespace WeiboJsonUtils {

inline QString getString(const QJsonObject &obj, const QString &key) {
  return obj.value(key).toString("");
}

inline int getInt(const QJsonObject &obj, const QString &key) {
  return obj.value(key).toInt(0);
}

inline qint64 getInt64(const QJsonObject &obj, const QString &key) {
  return obj.value(key).toVariant().toLongLong();
}

inline bool getBool(const QJsonObject &obj, const QString &key) {
  return obj.value(key).toBool(false);
}

inline QJsonObject getObject(const QJsonObject &obj, const QString &key) {
  return obj.value(key).toObject();
}

inline QJsonArray getArray(const QJsonObject &obj, const QString &key) {
  return obj.value(key).toArray();
}

} // namespace WeiboJsonUtils
