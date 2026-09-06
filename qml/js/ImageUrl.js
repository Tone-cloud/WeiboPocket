.pragma library

// 图片 URL 处理工具

// 微博图片 URL 转换为高清
function toHighQuality(url) {
    if (!url) return ""
    // 替换缩略图为高清图
    return url
        .replace("/thumb150/", "/large/")
        .replace("/thumb180/", "/large/")
        .replace("/thumb300/", "/large/")
        .replace("/square/", "/large/")
        .replace("/mw690/", "/large/")
        .replace("/orj360/", "/large/")
}

// 微博图片 URL 转换为缩略图
function toThumbnail(url) {
    if (!url) return ""
    return url
        .replace("/large/", "/thumb300/")
        .replace("/mw690/", "/thumb300/")
}

// 构建 image://weibo 协议 URL
function toImageProviderUrl(url) {
    if (!url) return ""
    return "image://weibo/" + encodeURIComponent(url)
}

// 检查是否为微博图片域名
function isWeiboImage(url) {
    if (!url) return false
    return url.indexOf("sinaimg.cn") >= 0 ||
           url.indexOf("weibo.com") >= 0 ||
           url.indexOf("weibocdn.com") >= 0
}

// 获取图片尺寸（从 URL 中解析）
function getImageSize(url) {
    if (!url) return { width: 0, height: 0 }
    // 微博图片 URL 格式: https://wx1.sinaimg.cn/large/xxx.jpg
    // 尺寸需要从 API 获取，这里返回默认值
    return { width: 0, height: 0 }
}
