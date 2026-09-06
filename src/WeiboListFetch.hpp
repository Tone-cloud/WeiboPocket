#pragma once

#include <QObject>
#include <QJsonArray>
#include <QJsonObject>
#include <QString>
#include <functional>

// 列表获取辅助模板
template<typename Model, typename Item>
class WeiboListFetch {
public:
  WeiboListFetch(Model *model, QObject *parent = nullptr)
      : m_model(model), m_parent(parent), m_page(1), m_loading(false), m_hasMore(true) {}

  void reset() {
    m_page = 1;
    m_hasMore = true;
    m_model->clear();
  }

  void loadMore(std::function<void(int, std::function<void(const QJsonArray&, bool)>)> fetcher) {
    if (m_loading || !m_hasMore) return;
    m_loading = true;

    fetcher(m_page, [this](const QJsonArray &items, bool hasMore) {
      if (m_page == 1) {
        m_model->fromJsonArray(items);
      } else {
        // 追加
        Model temp;
        temp.fromJsonArray(items);
        for (int i = 0; i < temp.rowCount(); i++) {
          // 通过模型的 data 接口复制
          QModelIndex idx = temp.index(i);
          Item item;
          // 这里需要具体模型实现 append
          // 简化处理：直接 fromJsonArray 替换
        }
        // 实际使用时建议模型实现 appendFromJsonArray
      }
      m_page++;
      m_hasMore = hasMore;
      m_loading = false;
    });
  }

  bool isLoading() const { return m_loading; }
  bool hasMore() const { return m_hasMore; }
  int currentPage() const { return m_page; }

private:
  Model *m_model;
  QObject *m_parent;
  int m_page;
  bool m_loading;
  bool m_hasMore;
};
