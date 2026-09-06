pragma Singleton
import QtQuick 2.12

Item {
    FontLoader {
        id: appFont
        source: "LXGWWenKai-Regular.ttf"
    }

    // ══════════════════════════════════════
    //  品牌色（微博红）
    // ══════════════════════════════════════
    readonly property color primary: "#E6162D"
    readonly property color primaryLight: "#FF4D4F"
    readonly property color primaryDark: "#C41D21"
    readonly property color primarySoft: "#FFF1F0"
    readonly property color primaryGlow: "#1AE6162D"

    // ══════════════════════════════════════
    //  背景色（浅色主题 - 微博风格）
    // ══════════════════════════════════════
    readonly property color bgPrimary: "#F5F5F5"      // 页面主背景
    readonly property color bgSecondary: "#FFFFFF"      // 卡片/导航栏背景
    readonly property color bgTertiary: "#EFEFEF"       // 次级背景/分割区
    readonly property color bgCard: "#FFFFFF"            // 卡片背景
    readonly property color bgCardHover: "#F8F8F8"      // 卡片按下
    readonly property color bgInput: "#F0F0F0"          // 输入框背景
    readonly property color bgOverlay: "#80000000"      // 遮罩层
    readonly property color bgHeader: "#FFFFFF"          // 标题栏背景

    // ══════════════════════════════════════
    //  文字颜色
    // ══════════════════════════════════════
    readonly property color textPrimary: "#1A1A1A"      // 主文字
    readonly property color textSecondary: "#666666"    // 次级文字
    readonly property color textTertiary: "#999999"     // 弱文字/时间
    readonly property color textOnPrimary: "#FFFFFF"     // 主色上的文字
    readonly property color textLink: "#E6162D"          // 链接文字
    readonly property color textMuted: "#B0B0B0"         // 禁用文字

    // ══════════════════════════════════════
    //  边框/分割线
    // ══════════════════════════════════════
    readonly property color border: "#E8E8E8"
    readonly property color borderLight: "#F0F0F0"
    readonly property color divider: "#EEEEEE"
    readonly property color hairline: "#F5F5F5"

    // ══════════════════════════════════════
    //  状态色
    // ══════════════════════════════════════
    readonly property color error: "#FF4D4F"
    readonly property color success: "#52C41A"
    readonly property color warning: "#FAAD14"
    readonly property color info: "#1890FF"

    // ══════════════════════════════════════
    //  热搜排名色
    // ══════════════════════════════════════
    readonly property color rank1: "#FF4D4F"   // 第1名 - 红
    readonly property color rank2: "#FF7A45"   // 第2名 - 橙
    readonly property color rank3: "#FAAD14"   // 第3名 - 金
    readonly property color rankNormal: "#999999" // 其他 - 灰

    // ══════════════════════════════════════
    //  标签色
    // ══════════════════════════════════════
    readonly property color tagHot: "#FF4D4F"
    readonly property color tagNew: "#52C41A"
    readonly property color tagBoil: "#FF7A45"
    readonly property color tagRecommend: "#1890FF"

    // ══════════════════════════════════════
    //  字体尺寸（320x170 优化 - 高信息密度）
    // ══════════════════════════════════════
    readonly property int fontTiny: 7       // 时间/来源/辅助信息
    readonly property int fontSmall: 8      // 次要文字/按钮
    readonly property int fontBody: 9       // 正文
    readonly property int fontNormal: 10    // 标题/列表主文字
    readonly property int fontMedium: 11    // 页面标题
    readonly property int fontLarge: 12     // 大标题/数字
    readonly property int fontTitle: 13     // 页面主标题
    readonly property int fontHuge: 16      // 热搜排名/强调数字
    readonly property int fontRank: 14       // 热搜排名数字

    // ══════════════════════════════════════
    //  间距（紧凑体系 - 最大化信息密度）
    // ══════════════════════════════════════
    readonly property int spacingTiny: 1
    readonly property int spacingSmall: 2
    readonly property int spacingNormal: 3
    readonly property int spacingMedium: 4
    readonly property int spacingLarge: 6
    readonly property int spacingXL: 8
    readonly property int spacingXXL: 12

    // ══════════════════════════════════════
    //  圆角（微博风格 - 小圆角）
    // ══════════════════════════════════════
    readonly property int radiusTiny: 2
    readonly property int radiusSmall: 3
    readonly property int radiusMedium: 4
    readonly property int radiusLarge: 6
    readonly property int radiusXL: 8
    readonly property int radiusRound: 999

    // ══════════════════════════════════════
    //  布局尺寸
    // ══════════════════════════════════════
    readonly property int screenWidth: 320
    readonly property int screenHeight: 170
    readonly property int titleBarHeight: 26
    readonly property int tabBarHeight: 28
    readonly property int statusBarHeight: 0
    readonly property int cardPadding: 5
    readonly property int listItemHeight: 32
    readonly property int avatarSize: 22
    readonly property int avatarSizeSmall: 18
    readonly property int avatarSizeLarge: 32

    // ══════════════════════════════════════
    //  触摸最小点击区域
    // ══════════════════════════════════════
    readonly property int touchMinSize: 24
    readonly property int buttonHeight: 22
    readonly property int buttonHeightLarge: 26

    // ══════════════════════════════════════
    //  动画时长（快速流畅）
    // ══════════════════════════════════════
    readonly property int animFast: 100
    readonly property int animNormal: 150
    readonly property int animSlow: 250
    readonly property int animPage: 200
    readonly property int animSpring: 300

    // ══════════════════════════════════════
    //  字体族
    // ══════════════════════════════════════
    readonly property string fontFamily: appFont.name !== "" ? appFont.name : "Microsoft YaHei"

    // ══════════════════════════════════════
    //  工具函数
    // ══════════════════════════════════════
    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function lighten(c, factor) {
        return Qt.lighter(c, 1.0 + factor);
    }

    function darken(c, factor) {
        return Qt.darker(c, 1.0 + factor);
    }

    function rankColor(index) {
        if (index === 0) return Theme.rank1
        if (index === 1) return Theme.rank2
        if (index === 2) return Theme.rank3
        return Theme.rankNormal
    }

    function formatNumber(num) {
        if (num >= 100000000) return (num / 100000000).toFixed(1) + "亿"
        if (num >= 10000) return (num / 10000).toFixed(1) + "万"
        return String(num)
    }
}
