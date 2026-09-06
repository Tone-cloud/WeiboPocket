#pragma once

#include <QObject>
#include <QTimer>
#include <functional>

// 异步工具：延迟执行
class WeiboAsyncUtils {
public:
  static void delay(int ms, std::function<void()> callback) {
    QTimer::singleShot(ms, callback);
  }

  // 带超时的异步操作
  template<typename T>
  static void withTimeout(int timeoutMs,
                          std::function<void(std::function<void(T)>)> asyncOp,
                          std::function<void(T)> onResult,
                          std::function<void()> onTimeout = nullptr) {
    bool *completed = new bool(false);
    QTimer *timer = new QTimer();
    timer->setSingleShot(true);

    auto finish = [completed, timer]() {
      *completed = true;
      timer->stop();
      timer->deleteLater();
      delete completed;
    };

    QObject::connect(timer, &QTimer::timeout, [onTimeout, finish]() {
      if (onTimeout) onTimeout();
      finish();
    });

    asyncOp([onResult, finish, completed](T result) {
      if (*completed) return;
      if (onResult) onResult(result);
      finish();
    });

    timer->start(timeoutMs);
  }
};
