.pragma library

// 富文本处理工具

// 去除 HTML 标签
function stripHtml(text) {
    if (!text) return ""
    return text
        .replace(/<br\s*\/?>/gi, "\n")
        .replace(/<[^>]+>/g, "")
        .replace(/&nbsp;/g, " ")
        .replace(/&amp;/g, "&")
        .replace(/&lt;/g, "<")
        .replace(/&gt;/g, ">")
        .replace(/&quot;/g, '"')
        .trim()
}

// 提取 @用户
function extractMentions(text) {
    if (!text) return []
    var matches = text.match(/@([^\s@]+)/g)
    if (!matches) return []
    return matches.map(function(m) { return m.substring(1) })
}

// 提取 #话题#
function extractTopics(text) {
    if (!text) return []
    var matches = text.match(/#([^#]+)#/g)
    if (!matches) return []
    return matches.map(function(m) { return m.substring(1, m.length - 1) })
}

// 提取 URL
function extractUrls(text) {
    if (!text) return []
    var matches = text.match(/https?:\/\/[^\s]+/g)
    return matches || []
}

// 截断文本
function truncate(text, maxLen) {
    if (!text) return ""
    if (text.length <= maxLen) return text
    return text.substring(0, maxLen) + "..."
}

// 格式化数字
function formatNumber(num) {
    if (num >= 100000000) return (num / 100000000).toFixed(1) + "亿"
    if (num >= 10000) return (num / 10000).toFixed(1) + "万"
    return String(num)
}

// 格式化时间
function formatTime(ts) {
    if (!ts) return ""
    var now = Math.floor(Date.now() / 1000)
    var diff = now - ts
    if (diff < 60) return "刚刚"
    if (diff < 3600) return Math.floor(diff / 60) + "分钟前"
    if (diff < 86400) return Math.floor(diff / 3600) + "小时前"
    if (diff < 604800) return Math.floor(diff / 86400) + "天前"
    var d = new Date(ts * 1000)
    return d.getFullYear() + "-" +
        String(d.getMonth() + 1).padStart(2, '0') + "-" +
        String(d.getDate()).padStart(2, '0')
}
