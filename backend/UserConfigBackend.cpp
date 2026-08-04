#include "UserConfigBackend.h"

#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QJsonValue>
#include <QSet>
#include <QVariant>
#include <Qt>

#include <algorithm>
#include <cmath>

namespace {
QVariantList defaultDynamicIslandLeftSwipeItems()
{
    return {QStringLiteral("cava"), QStringLiteral("battery")};
}

QVariantList defaultLiveActivityPriority()
{
    return {QStringLiteral("recording"), QStringLiteral("media")};
}

QVariantList defaultControlCenterModules()
{
    return {QStringLiteral("wifi"), QStringLiteral("bluetooth"), QStringLiteral("mic"), QStringLiteral("nightlight")};
}

QByteArray stripJsonComments(const QByteArray &input)
{
    QString text = QString::fromUtf8(input);

    // Remove /* ... */ block comments
    static const QRegularExpression blockRe(QStringLiteral("/\\*.*?\\*/"), QRegularExpression::DotMatchesEverythingOption);
    text.replace(blockRe, QString());

    // Remove // line comments
    const QStringList lines = text.split(u'\n');
    QStringList stripped;
    bool inString = false;
    for (const QString &line : lines) {
        QString result;
        for (int i = 0; i < line.size(); ++i) {
            const QChar ch = line.at(i);
            if (ch == u'"' && (i == 0 || line.at(i - 1) != u'\\'))
                inString = !inString;
            if (!inString && ch == u'/' && i + 1 < line.size() && line.at(i + 1) == u'/')
                break;
            result.append(ch);
        }
        stripped.append(result);
    }
    return stripped.join(u'\n').toUtf8();
}

QString jsonString(const QJsonObject &object, QLatin1String key, const QString &fallback)
{
    const QJsonValue value = object.value(key);
    return value.isString() && !value.toString().isEmpty() ? value.toString() : fallback;
}

int jsonInt(const QJsonObject &object, QLatin1String key, int fallback)
{
    const QJsonValue value = object.value(key);
    if (!value.isDouble())
        return fallback;

    const double number = value.toDouble();
    return std::isfinite(number) ? qRound(number) : fallback;
}

int jsonBoundedInt(const QJsonObject &object, QLatin1String key, int fallback, int minimum, int maximum)
{
    return std::clamp(jsonInt(object, key, fallback), minimum, maximum);
}

double jsonDouble(const QJsonObject &object, QLatin1String key, double fallback)
{
    const QJsonValue value = object.value(key);
    if (!value.isDouble())
        return fallback;

    const double number = value.toDouble();
    return std::isfinite(number) ? number : fallback;
}

QVariantList jsonArray(const QJsonObject &object, QLatin1String key, const QVariantList &fallback)
{
    const QJsonValue value = object.value(key);
    return value.isArray() ? value.toArray().toVariantList() : fallback;
}

bool jsonBool(const QJsonObject &object, QLatin1String key, bool fallback)
{
    const QJsonValue value = object.value(key);
    return value.isBool() ? value.toBool() : fallback;
}

QVariantList jsonStringList(const QJsonObject &object, QLatin1String key, const QVariantList &fallback)
{
    const QJsonValue value = object.value(key);
    if (value.isArray()) {
        QVariantList result;
        const QJsonArray array = value.toArray();
        for (const QJsonValue &item : array) {
            if (item.isString())
                result.append(item.toString());
        }
        return result;
    }

    if (value.isString()) {
        const QString text = value.toString();
        if (text.trimmed().isEmpty())
            return fallback;

        QVariantList result;
        const QStringList parts = text.split(u',', Qt::SkipEmptyParts);
        for (const QString &part : parts) {
            const QString trimmed = part.trimmed();
            if (!trimmed.isEmpty())
                result.append(trimmed);
        }
        return result.isEmpty() ? fallback : result;
    }

    return fallback;
}

QString jsonEnum(const QJsonObject &object, QLatin1String key, const QString &fallback, const QSet<QString> &allowed)
{
    const QString value = jsonString(object, key, fallback);
    return allowed.contains(value) ? value : fallback;
}

template<typename Owner, typename T, typename Signal>
void updateField(Owner *owner, T &field, T nextValue, Signal signal)
{
    if (field == nextValue)
        return;

    field = std::move(nextValue);
    emit(owner->*signal)();
}
}

UserConfigBackend::UserConfigBackend(QObject *parent)
    : QObject(parent)
    , m_userConfigPath(configHome() + QStringLiteral("/tide-island/userconfig.json"))
    , m_dynamicIslandLeftSwipeItems(defaultDynamicIslandLeftSwipeItems())
{
    m_reloadTimer.setSingleShot(true);
    m_reloadTimer.setInterval(50);

    connect(&m_reloadTimer, &QTimer::timeout, this, &UserConfigBackend::loadConfig);
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, &UserConfigBackend::scheduleReload);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &UserConfigBackend::scheduleReload);

    loadConfig();
}

QString UserConfigBackend::userConfigPath() const
{
    return m_userConfigPath;
}

QString UserConfigBackend::configError() const
{
    return m_configError;
}

QString UserConfigBackend::defaultWallpaperPath() const
{
    return m_defaultWallpaperPath;
}

QString UserConfigBackend::defaultTlpSudoPassword() const
{
    return m_defaultTlpSudoPassword;
}

QString UserConfigBackend::wallpaperPath() const
{
    return m_wallpaperPath;
}

QString UserConfigBackend::wallpaperLibraryPath() const
{
    return m_wallpaperLibraryPath;
}

bool UserConfigBackend::wallpaperPywalEnabled() const
{
    return m_wallpaperPywalEnabled;
}

bool UserConfigBackend::wallpaperCustomCommandEnabled() const
{
    return m_wallpaperCustomCommandEnabled;
}

QString UserConfigBackend::wallpaperCustomCommand() const
{
    return m_wallpaperCustomCommand;
}

QString UserConfigBackend::wallpaperTransitionType() const
{
    return m_wallpaperTransitionType;
}

int UserConfigBackend::wallpaperTransitionStep() const
{
    return m_wallpaperTransitionStep;
}

double UserConfigBackend::wallpaperTransitionDuration() const
{
    return m_wallpaperTransitionDuration;
}

int UserConfigBackend::wallpaperTransitionFps() const
{
    return m_wallpaperTransitionFps;
}

int UserConfigBackend::wallpaperTransitionAngle() const
{
    return m_wallpaperTransitionAngle;
}

QString UserConfigBackend::wallpaperTransitionPosition() const
{
    return m_wallpaperTransitionPosition;
}

QString UserConfigBackend::wallpaperTransitionBezier() const
{
    return m_wallpaperTransitionBezier;
}

QString UserConfigBackend::wallpaperTransitionWave() const
{
    return m_wallpaperTransitionWave;
}

bool UserConfigBackend::wallpaperTransitionInvertY() const
{
    return m_wallpaperTransitionInvertY;
}

QString UserConfigBackend::iconFontFamily() const
{
    return m_iconFontFamily;
}

QString UserConfigBackend::textFontFamily() const
{
    return m_textFontFamily;
}

QString UserConfigBackend::heroFontFamily() const
{
    return m_heroFontFamily;
}

QString UserConfigBackend::timeFontFamily() const
{
    return m_timeFontFamily;
}

QString UserConfigBackend::clockFormat() const
{
    return m_clockFormat;
}

QString UserConfigBackend::tlpSudoPassword() const
{
    return m_tlpSudoPassword;
}

QString UserConfigBackend::tlpPermissionMode() const
{
    return m_tlpPermissionMode;
}

int UserConfigBackend::workspaceOverviewWindowDragButton() const
{
    return m_workspaceOverviewWindowDragButton;
}

int UserConfigBackend::dynamicIslandPrimaryButton() const
{
    return m_dynamicIslandPrimaryButton;
}

QString UserConfigBackend::dynamicIslandPrimaryAction() const
{
    return m_dynamicIslandPrimaryAction;
}

int UserConfigBackend::dynamicIslandSecondaryButton() const
{
    return m_dynamicIslandSecondaryButton;
}

QString UserConfigBackend::dynamicIslandSecondaryAction() const
{
    return m_dynamicIslandSecondaryAction;
}

const QVariantList &UserConfigBackend::dynamicIslandLeftSwipeItems() const
{
    return m_dynamicIslandLeftSwipeItems;
}

bool UserConfigBackend::disableAutoExpandOnTrackChange() const
{
    return m_disableAutoExpandOnTrackChange;
}

int UserConfigBackend::hoverExpandAction() const
{
    return m_hoverExpandAction;
}

bool UserConfigBackend::islandAutoHideEnabled() const
{
    return m_islandAutoHideEnabled;
}

int UserConfigBackend::islandAutoHideDelayMs() const
{
    return m_islandAutoHideDelayMs;
}

int UserConfigBackend::islandWidth() const
{
    return m_islandWidth;
}

int UserConfigBackend::islandBackgroundOpacity() const
{
    return m_islandBackgroundOpacity;
}

int UserConfigBackend::islandHeight() const
{
    return m_islandHeight;
}

bool UserConfigBackend::islandHeightOverrideEnabled() const
{
    return m_islandHeightOverrideEnabled;
}

int UserConfigBackend::islandExclusiveZone() const
{
    return m_islandExclusiveZone;
}

int UserConfigBackend::islandTopMargin() const
{
    return m_islandTopMargin;
}

int UserConfigBackend::islandScale() const
{
    return m_islandScale;
}

int UserConfigBackend::islandCornerRadius() const
{
    return m_islandCornerRadius;
}

int UserConfigBackend::islandBottomGap() const
{
    return m_islandBottomGap;
}

bool UserConfigBackend::islandReserveSpace() const
{
    return m_islandReserveSpace;
}

int UserConfigBackend::statusBarIslandGap() const
{
    return m_statusBarIslandGap;
}

int UserConfigBackend::statusBarItemSpacing() const
{
    return m_statusBarItemSpacing;
}

int UserConfigBackend::statusBarBaselineOffset() const
{
    return m_statusBarBaselineOffset;
}

int UserConfigBackend::islandPositionX() const
{
    return m_islandPositionX;
}

bool UserConfigBackend::islandMacNotchStyle() const
{
    return m_islandMacNotchStyle;
}

bool UserConfigBackend::statusBarEnabled() const
{
    return m_statusBarEnabled;
}

int UserConfigBackend::statusBarHeight() const
{
    return m_statusBarHeight;
}

int UserConfigBackend::statusBarTopMargin() const
{
    return m_statusBarTopMargin;
}

int UserConfigBackend::statusBarFontSize() const
{
    return m_statusBarFontSize;
}

int UserConfigBackend::statusBarClockFontSize() const
{
    return m_statusBarClockFontSize;
}

int UserConfigBackend::statusBarIconSize() const
{
    return m_statusBarIconSize;
}

int UserConfigBackend::statusBarFontWeight() const
{
    return m_statusBarFontWeight;
}

int UserConfigBackend::statusBarTextOpacity() const
{
    return m_statusBarTextOpacity;
}

int UserConfigBackend::statusBarDimAmount() const
{
    return m_statusBarDimAmount;
}

int UserConfigBackend::statusBarIconSpacing() const
{
    return m_statusBarIconSpacing;
}

int UserConfigBackend::statusBarWorkspaceDotSize() const
{
    return m_statusBarWorkspaceDotSize;
}

int UserConfigBackend::statusBarWorkspaceActiveWidth() const
{
    return m_statusBarWorkspaceActiveWidth;
}

int UserConfigBackend::statusBarWorkspaceSpacing() const
{
    return m_statusBarWorkspaceSpacing;
}

int UserConfigBackend::statusBarWorkspaceMinimumCount() const
{
    return m_statusBarWorkspaceMinimumCount;
}

int UserConfigBackend::statusBarBatteryScale() const
{
    return m_statusBarBatteryScale;
}

int UserConfigBackend::statusBarActiveWindowMaxWidth() const
{
    return m_statusBarActiveWindowMaxWidth;
}

int UserConfigBackend::statusBarActiveWindowOpacity() const
{
    return m_statusBarActiveWindowOpacity;
}

int UserConfigBackend::statusBarBackgroundOpacity() const
{
    return m_statusBarBackgroundOpacity;
}

int UserConfigBackend::statusBarBackgroundRadius() const
{
    return m_statusBarBackgroundRadius;
}

int UserConfigBackend::statusBarBackgroundMargin() const
{
    return m_statusBarBackgroundMargin;
}

bool UserConfigBackend::statusBarUseIslandBaseline() const
{
    return m_statusBarUseIslandBaseline;
}

bool UserConfigBackend::statusBarTextShadow() const
{
    return m_statusBarTextShadow;
}

bool UserConfigBackend::statusBarBackgroundEnabled() const
{
    return m_statusBarBackgroundEnabled;
}

bool UserConfigBackend::statusBarShowWifi() const
{
    return m_statusBarShowWifi;
}

bool UserConfigBackend::statusBarShowBluetooth() const
{
    return m_statusBarShowBluetooth;
}

bool UserConfigBackend::statusBarShowBattery() const
{
    return m_statusBarShowBattery;
}

bool UserConfigBackend::statusBarShowMute() const
{
    return m_statusBarShowMute;
}

bool UserConfigBackend::statusBarShowDate() const
{
    return m_statusBarShowDate;
}

bool UserConfigBackend::statusBarShowSeconds() const
{
    return m_statusBarShowSeconds;
}

QString UserConfigBackend::statusBarTextColor() const
{
    return m_statusBarTextColor;
}

QString UserConfigBackend::statusBarBackgroundColor() const
{
    return m_statusBarBackgroundColor;
}

int UserConfigBackend::statusBarSideMargin() const
{
    return m_statusBarSideMargin;
}

int UserConfigBackend::statusBarOpacity() const
{
    return m_statusBarOpacity;
}

bool UserConfigBackend::statusBarShowWorkspaces() const
{
    return m_statusBarShowWorkspaces;
}

bool UserConfigBackend::statusBarShowActiveWindow() const
{
    return m_statusBarShowActiveWindow;
}

bool UserConfigBackend::statusBarShowStatusIcons() const
{
    return m_statusBarShowStatusIcons;
}

bool UserConfigBackend::statusBarShowClock() const
{
    return m_statusBarShowClock;
}

bool UserConfigBackend::statusBarShowDateOnHover() const
{
    return m_statusBarShowDateOnHover;
}

bool UserConfigBackend::statusBarFadeWithIsland() const
{
    return m_statusBarFadeWithIsland;
}

bool UserConfigBackend::statusBarShowRecordingPill() const
{
    return m_statusBarShowRecordingPill;
}

QString UserConfigBackend::captureVideoDirectory() const
{
    return m_captureVideoDirectory;
}

QString UserConfigBackend::captureScreenshotDirectory() const
{
    return m_captureScreenshotDirectory;
}

QString UserConfigBackend::captureAnnotationTool() const
{
    return m_captureAnnotationTool;
}

bool UserConfigBackend::captureRecordAudio() const
{
    return m_captureRecordAudio;
}

bool UserConfigBackend::captureCopyToClipboard() const
{
    return m_captureCopyToClipboard;
}

bool UserConfigBackend::captureNotify() const
{
    return m_captureNotify;
}

bool UserConfigBackend::captureShowScreenshotPreview() const
{
    return m_captureShowScreenshotPreview;
}

int UserConfigBackend::captureScreenshotPreviewSeconds() const
{
    return m_captureScreenshotPreviewSeconds;
}

QString UserConfigBackend::motionPreset() const
{
    return m_motionPreset;
}

int UserConfigBackend::motionShapeSpring() const
{
    return m_motionShapeSpring;
}

int UserConfigBackend::motionShapeDamping() const
{
    return m_motionShapeDamping;
}

int UserConfigBackend::motionRadiusSpring() const
{
    return m_motionRadiusSpring;
}

int UserConfigBackend::motionRadiusDamping() const
{
    return m_motionRadiusDamping;
}

int UserConfigBackend::motionContentRevealDuration() const
{
    return m_motionContentRevealDuration;
}

int UserConfigBackend::motionPressScale() const
{
    return m_motionPressScale;
}

int UserConfigBackend::motionPulseScale() const
{
    return m_motionPulseScale;
}

int UserConfigBackend::motionLongPressMs() const
{
    return m_motionLongPressMs;
}

bool UserConfigBackend::motionIdleBreathEnabled() const
{
    return m_motionIdleBreathEnabled;
}

QString UserConfigBackend::idleStyle() const
{
    return m_idleStyle;
}

bool UserConfigBackend::idleShowUsageRings() const
{
    return m_idleShowUsageRings;
}

int UserConfigBackend::idleDotSize() const
{
    return m_idleDotSize;
}

int UserConfigBackend::idleDotOpacity() const
{
    return m_idleDotOpacity;
}

const QVariantList &UserConfigBackend::liveActivityPriority() const
{
    return m_liveActivityPriority;
}

int UserConfigBackend::transientNotificationMs() const
{
    return m_transientNotificationMs;
}

int UserConfigBackend::transientShotMs() const
{
    return m_transientShotMs;
}

int UserConfigBackend::transientBannerMs() const
{
    return m_transientBannerMs;
}

int UserConfigBackend::transientHudMs() const
{
    return m_transientHudMs;
}

int UserConfigBackend::transientClockMs() const
{
    return m_transientClockMs;
}

bool UserConfigBackend::notificationAutoExpand() const
{
    return m_notificationAutoExpand;
}

const QVariantList &UserConfigBackend::controlCenterModules() const
{
    return m_controlCenterModules;
}

bool UserConfigBackend::controlCenterShowVolume() const
{
    return m_controlCenterShowVolume;
}

bool UserConfigBackend::controlCenterShowBrightness() const
{
    return m_controlCenterShowBrightness;
}

const QVariantList &UserConfigBackend::mediaExcludedPlayers() const
{
    return m_mediaExcludedPlayers;
}

const QVariantList &UserConfigBackend::mediaPreferredPlayers() const
{
    return m_mediaPreferredPlayers;
}

int UserConfigBackend::clipboardHistoryLimit() const
{
    return m_clipboardHistoryLimit;
}

const QVariantList &UserConfigBackend::clipboardExcludedApps() const
{
    return m_clipboardExcludedApps;
}

bool UserConfigBackend::clipboardShowImagePreviews() const
{
    return m_clipboardShowImagePreviews;
}

const QVariantList &UserConfigBackend::notificationsBlockedApps() const
{
    return m_notificationsBlockedApps;
}

const QVariantList &UserConfigBackend::notificationsAllowedApps() const
{
    return m_notificationsAllowedApps;
}

bool UserConfigBackend::doNotDisturbEnabled() const
{
    return m_doNotDisturbEnabled;
}

bool UserConfigBackend::dndScheduleEnabled() const
{
    return m_dndScheduleEnabled;
}

QString UserConfigBackend::dndStartTime() const
{
    return m_dndStartTime;
}

QString UserConfigBackend::dndEndTime() const
{
    return m_dndEndTime;
}

int UserConfigBackend::notificationsHistoryLimit() const
{
    return m_notificationsHistoryLimit;
}

QString UserConfigBackend::captureScreenshotFormat() const
{
    return m_captureScreenshotFormat;
}

QString UserConfigBackend::captureVideoFormat() const
{
    return m_captureVideoFormat;
}

QString UserConfigBackend::captureScreenshotNamePattern() const
{
    return m_captureScreenshotNamePattern;
}

QString UserConfigBackend::captureVideoNamePattern() const
{
    return m_captureVideoNamePattern;
}

bool UserConfigBackend::shellAutostartEnabled() const
{
    return m_shellAutostartEnabled;
}

QString UserConfigBackend::islandMonitorMode() const
{
    return m_islandMonitorMode;
}

QString UserConfigBackend::islandMonitorName() const
{
    return m_islandMonitorName;
}

QString UserConfigBackend::statusBarMonitorMode() const
{
    return m_statusBarMonitorMode;
}

QString UserConfigBackend::statusBarMonitorName() const
{
    return m_statusBarMonitorName;
}

int UserConfigBackend::bodyFontSize() const
{
    return m_bodyFontSize;
}

int UserConfigBackend::titleFontSize() const
{
    return m_titleFontSize;
}

int UserConfigBackend::iconFontSize() const
{
    return m_iconFontSize;
}

void UserConfigBackend::setDefaultWallpaperPath(const QString &path)
{
    if (m_defaultWallpaperPath == path)
        return;

    m_defaultWallpaperPath = path;
    emit defaultWallpaperPathChanged();
    loadConfig();
}

void UserConfigBackend::setDefaultTlpSudoPassword(const QString &password)
{
    if (m_defaultTlpSudoPassword == password)
        return;

    m_defaultTlpSudoPassword = password;
    emit defaultTlpSudoPasswordChanged();
    loadConfig();
}

int UserConfigBackend::mouseButton(const QVariant &button) const
{
    bool ok = false;
    const int numericButton = button.toInt(&ok);
    if (!ok)
        return Qt::NoButton;

    switch (numericButton) {
    case 1:
        return Qt::LeftButton;
    case 2:
        return Qt::MiddleButton;
    case 3:
        return Qt::RightButton;
    default:
        return numericButton;
    }
}

int UserConfigBackend::mouseButtonsMask(const QVariant &buttons) const
{
    if (!buttons.isValid() || buttons.isNull())
        return Qt::NoButton;

    if (buttons.canConvert<QVariantList>()) {
        int mask = Qt::NoButton;
        const QVariantList buttonList = buttons.toList();
        for (const QVariant &button : buttonList)
            mask |= mouseButton(button);
        return mask;
    }

    return mouseButton(buttons);
}

void UserConfigBackend::reload()
{
    loadConfig();
}

void UserConfigBackend::scheduleReload()
{
    if (!m_reloadTimer.isActive())
        m_reloadTimer.start();
}

void UserConfigBackend::loadConfig()
{
    updateWatchedPaths();

    QJsonObject configObject;
    QString nextConfigError;

    QFile configFile(m_userConfigPath);
    if (configFile.exists()) {
        if (!configFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            nextConfigError = QStringLiteral("Could not read %1: %2").arg(m_userConfigPath, configFile.errorString());
        } else {
            const QByteArray configBytes = configFile.readAll();
            if (!configBytes.trimmed().isEmpty()) {
                const QByteArray strippedBytes = stripJsonComments(configBytes);
                QJsonParseError parseError;
                const QJsonDocument document = QJsonDocument::fromJson(strippedBytes, &parseError);
                if (parseError.error != QJsonParseError::NoError) {
                    nextConfigError = QStringLiteral("Invalid JSON in %1 at offset %2: %3")
                        .arg(m_userConfigPath)
                        .arg(parseError.offset)
                        .arg(parseError.errorString());
                } else if (!document.isObject()) {
                    nextConfigError = QStringLiteral("Invalid JSON in %1: root value must be an object").arg(m_userConfigPath);
                } else {
                    configObject = document.object();
                }
            }
        }
    }

    updateField(this, m_configError, nextConfigError, &UserConfigBackend::configErrorChanged);

    updateField(this, m_wallpaperPath, jsonString(configObject, QLatin1String("wallpaperPath"), m_defaultWallpaperPath), &UserConfigBackend::wallpaperPathChanged);
    updateField(this, m_wallpaperLibraryPath, jsonString(configObject, QLatin1String("wallpaperLibraryPath"), QString()), &UserConfigBackend::wallpaperLibraryPathChanged);
    updateField(this, m_wallpaperPywalEnabled, jsonBool(configObject, QLatin1String("wallpaperPywalEnabled"), false), &UserConfigBackend::wallpaperPywalEnabledChanged);
    updateField(this, m_wallpaperCustomCommandEnabled, jsonBool(configObject, QLatin1String("wallpaperCustomCommandEnabled"), false), &UserConfigBackend::wallpaperCustomCommandEnabledChanged);
    updateField(this, m_wallpaperCustomCommand, jsonString(configObject, QLatin1String("wallpaperCustomCommand"), QString()), &UserConfigBackend::wallpaperCustomCommandChanged);
    updateField(this, m_wallpaperTransitionType, jsonString(configObject, QLatin1String("wallpaperTransitionType"), QStringLiteral("center")), &UserConfigBackend::wallpaperTransitionTypeChanged);
    updateField(this, m_wallpaperTransitionStep, jsonInt(configObject, QLatin1String("wallpaperTransitionStep"), 5), &UserConfigBackend::wallpaperTransitionStepChanged);
    updateField(this, m_wallpaperTransitionDuration, jsonDouble(configObject, QLatin1String("wallpaperTransitionDuration"), 3.0), &UserConfigBackend::wallpaperTransitionDurationChanged);
    updateField(this, m_wallpaperTransitionFps, jsonInt(configObject, QLatin1String("wallpaperTransitionFps"), 60), &UserConfigBackend::wallpaperTransitionFpsChanged);
    updateField(this, m_wallpaperTransitionAngle, jsonInt(configObject, QLatin1String("wallpaperTransitionAngle"), 45), &UserConfigBackend::wallpaperTransitionAngleChanged);
    updateField(this, m_wallpaperTransitionPosition, jsonString(configObject, QLatin1String("wallpaperTransitionPosition"), QStringLiteral("center")), &UserConfigBackend::wallpaperTransitionPositionChanged);
    updateField(this, m_wallpaperTransitionBezier, jsonString(configObject, QLatin1String("wallpaperTransitionBezier"), QStringLiteral(".54,0,.34,.99")), &UserConfigBackend::wallpaperTransitionBezierChanged);
    updateField(this, m_wallpaperTransitionWave, jsonString(configObject, QLatin1String("wallpaperTransitionWave"), QStringLiteral("20,20")), &UserConfigBackend::wallpaperTransitionWaveChanged);
    updateField(this, m_wallpaperTransitionInvertY, jsonBool(configObject, QLatin1String("wallpaperTransitionInvertY"), false), &UserConfigBackend::wallpaperTransitionInvertYChanged);
    updateField(this, m_iconFontFamily, jsonString(configObject, QLatin1String("iconFontFamily"), QStringLiteral("JetBrainsMono Nerd Font")), &UserConfigBackend::iconFontFamilyChanged);
    updateField(this, m_textFontFamily, jsonString(configObject, QLatin1String("textFontFamily"), QStringLiteral("Inter Display")), &UserConfigBackend::textFontFamilyChanged);
    updateField(this, m_heroFontFamily, jsonString(configObject, QLatin1String("heroFontFamily"), QStringLiteral("Inter Display")), &UserConfigBackend::heroFontFamilyChanged);
    updateField(this, m_timeFontFamily, jsonString(configObject, QLatin1String("timeFontFamily"), QStringLiteral("Inter Display")), &UserConfigBackend::timeFontFamilyChanged);
    const QString configuredClockFormat = jsonString(configObject, QLatin1String("clockFormat"), QStringLiteral("12"));
    updateField(this, m_clockFormat, configuredClockFormat == QLatin1String("24") ? QStringLiteral("24") : QStringLiteral("12"), &UserConfigBackend::clockFormatChanged);
    updateField(this, m_tlpSudoPassword, jsonString(configObject, QLatin1String("tlpSudoPassword"), m_defaultTlpSudoPassword), &UserConfigBackend::tlpSudoPasswordChanged);
    updateField(this, m_tlpPermissionMode, jsonString(configObject, QLatin1String("tlpPermissionMode"), QStringLiteral("skip")), &UserConfigBackend::tlpPermissionModeChanged);
    updateField(this, m_workspaceOverviewWindowDragButton, jsonInt(configObject, QLatin1String("workspaceOverviewWindowDragButton"), 1), &UserConfigBackend::workspaceOverviewWindowDragButtonChanged);
    updateField(this, m_dynamicIslandPrimaryButton, jsonInt(configObject, QLatin1String("dynamicIslandPrimaryButton"), 1), &UserConfigBackend::dynamicIslandPrimaryButtonChanged);
    updateField(this, m_dynamicIslandPrimaryAction, jsonString(configObject, QLatin1String("dynamicIslandPrimaryAction"), QStringLiteral("toggleExpandedPlayer")), &UserConfigBackend::dynamicIslandPrimaryActionChanged);
    updateField(this, m_dynamicIslandSecondaryButton, jsonInt(configObject, QLatin1String("dynamicIslandSecondaryButton"), 3), &UserConfigBackend::dynamicIslandSecondaryButtonChanged);
    updateField(this, m_dynamicIslandSecondaryAction, jsonString(configObject, QLatin1String("dynamicIslandSecondaryAction"), QStringLiteral("toggleControlCenter")), &UserConfigBackend::dynamicIslandSecondaryActionChanged);
    updateField(this, m_dynamicIslandLeftSwipeItems, jsonArray(configObject, QLatin1String("dynamicIslandLeftSwipeItems"), defaultDynamicIslandLeftSwipeItems()), &UserConfigBackend::dynamicIslandLeftSwipeItemsChanged);
    updateField(this, m_disableAutoExpandOnTrackChange, jsonBool(configObject, QLatin1String("disableAutoExpandOnTrackChange"), false), &UserConfigBackend::disableAutoExpandOnTrackChangeChanged);
    updateField(this, m_hoverExpandAction, jsonInt(configObject, QLatin1String("hoverExpandAction"), 1), &UserConfigBackend::hoverExpandActionChanged);
    updateField(this, m_islandAutoHideEnabled, jsonBool(configObject, QLatin1String("islandAutoHideEnabled"), true), &UserConfigBackend::islandAutoHideEnabledChanged);
    updateField(this, m_islandAutoHideDelayMs, jsonBoundedInt(configObject, QLatin1String("islandAutoHideDelayMs"), 1000, 100, 10000), &UserConfigBackend::islandAutoHideDelayMsChanged);
    updateField(this, m_islandWidth, jsonInt(configObject, QLatin1String("islandWidth"), 125), &UserConfigBackend::islandWidthChanged);
    updateField(this, m_islandBackgroundOpacity, jsonBoundedInt(configObject, QLatin1String("islandBackgroundOpacity"), 100, 0, 100), &UserConfigBackend::islandBackgroundOpacityChanged);
    updateField(this, m_islandHeight, jsonInt(configObject, QLatin1String("islandHeight"), 37), &UserConfigBackend::islandHeightChanged);
    updateField(this, m_islandHeightOverrideEnabled, jsonBool(configObject, QLatin1String("islandHeightOverrideEnabled"), false), &UserConfigBackend::islandHeightOverrideEnabledChanged);
    updateField(this, m_islandExclusiveZone, jsonBoundedInt(configObject, QLatin1String("islandExclusiveZone"), 45, 0, 1000), &UserConfigBackend::islandExclusiveZoneChanged);
    updateField(this, m_islandTopMargin, jsonBoundedInt(configObject, QLatin1String("islandTopMargin"), 11, 0, 1000), &UserConfigBackend::islandTopMarginChanged);
    updateField(this, m_islandScale, jsonBoundedInt(configObject, QLatin1String("islandScale"), 100, 60, 160), &UserConfigBackend::islandScaleChanged);
    updateField(this, m_islandCornerRadius, jsonBoundedInt(configObject, QLatin1String("islandCornerRadius"), 32, 4, 60), &UserConfigBackend::islandCornerRadiusChanged);
    updateField(this, m_islandBottomGap, jsonBoundedInt(configObject, QLatin1String("islandBottomGap"), 8, 0, 200), &UserConfigBackend::islandBottomGapChanged);
    updateField(this, m_islandReserveSpace, jsonBool(configObject, QLatin1String("islandReserveSpace"), true), &UserConfigBackend::islandReserveSpaceChanged);
    updateField(this, m_islandPositionX, jsonInt(configObject, QLatin1String("islandPositionX"), 50), &UserConfigBackend::islandPositionXChanged);
    updateField(this, m_islandMacNotchStyle, jsonBool(configObject, QLatin1String("islandMacNotchStyle"), true), &UserConfigBackend::islandMacNotchStyleChanged);
    updateField(this, m_bodyFontSize, jsonInt(configObject, QLatin1String("bodyFontSize"), 16), &UserConfigBackend::bodyFontSizeChanged);
    updateField(this, m_titleFontSize, jsonInt(configObject, QLatin1String("titleFontSize"), 20), &UserConfigBackend::titleFontSizeChanged);
    updateField(this, m_iconFontSize, jsonInt(configObject, QLatin1String("iconFontSize"), 18), &UserConfigBackend::iconFontSizeChanged);

    updateField(this, m_statusBarEnabled, jsonBool(configObject, QLatin1String("statusBarEnabled"), true), &UserConfigBackend::statusBarEnabledChanged);
    updateField(this, m_statusBarSideMargin, jsonBoundedInt(configObject, QLatin1String("statusBarSideMargin"), 22, 0, 400), &UserConfigBackend::statusBarSideMarginChanged);
    updateField(this, m_statusBarIslandGap, jsonBoundedInt(configObject, QLatin1String("statusBarIslandGap"), 14, 0, 200), &UserConfigBackend::statusBarIslandGapChanged);
    updateField(this, m_statusBarItemSpacing, jsonBoundedInt(configObject, QLatin1String("statusBarItemSpacing"), 14, 0, 80), &UserConfigBackend::statusBarItemSpacingChanged);
    updateField(this, m_statusBarBaselineOffset, jsonBoundedInt(configObject, QLatin1String("statusBarBaselineOffset"), 0, -40, 120), &UserConfigBackend::statusBarBaselineOffsetChanged);
    updateField(this, m_statusBarOpacity, jsonBoundedInt(configObject, QLatin1String("statusBarOpacity"), 100, 0, 100), &UserConfigBackend::statusBarOpacityChanged);
    updateField(this, m_statusBarShowWorkspaces, jsonBool(configObject, QLatin1String("statusBarShowWorkspaces"), true), &UserConfigBackend::statusBarShowWorkspacesChanged);
    updateField(this, m_statusBarShowActiveWindow, jsonBool(configObject, QLatin1String("statusBarShowActiveWindow"), true), &UserConfigBackend::statusBarShowActiveWindowChanged);
    updateField(this, m_statusBarShowStatusIcons, jsonBool(configObject, QLatin1String("statusBarShowStatusIcons"), true), &UserConfigBackend::statusBarShowStatusIconsChanged);
    updateField(this, m_statusBarShowClock, jsonBool(configObject, QLatin1String("statusBarShowClock"), true), &UserConfigBackend::statusBarShowClockChanged);
    updateField(this, m_statusBarShowDateOnHover, jsonBool(configObject, QLatin1String("statusBarShowDateOnHover"), true), &UserConfigBackend::statusBarShowDateOnHoverChanged);
    updateField(this, m_statusBarFadeWithIsland, jsonBool(configObject, QLatin1String("statusBarFadeWithIsland"), true), &UserConfigBackend::statusBarFadeWithIslandChanged);
    updateField(this, m_statusBarShowRecordingPill, jsonBool(configObject, QLatin1String("statusBarShowRecordingPill"), true), &UserConfigBackend::statusBarShowRecordingPillChanged);
    updateField(this, m_statusBarHeight, jsonBoundedInt(configObject, QLatin1String("statusBarHeight"), 34, 0, 240), &UserConfigBackend::statusBarHeightChanged);
    updateField(this, m_statusBarTopMargin, jsonBoundedInt(configObject, QLatin1String("statusBarTopMargin"), 0, 0, 240), &UserConfigBackend::statusBarTopMarginChanged);
    updateField(this, m_statusBarFontSize, jsonBoundedInt(configObject, QLatin1String("statusBarFontSize"), 13, 7, 40), &UserConfigBackend::statusBarFontSizeChanged);
    updateField(this, m_statusBarClockFontSize, jsonBoundedInt(configObject, QLatin1String("statusBarClockFontSize"), 13, 7, 40), &UserConfigBackend::statusBarClockFontSizeChanged);
    updateField(this, m_statusBarIconSize, jsonBoundedInt(configObject, QLatin1String("statusBarIconSize"), 13, 7, 40), &UserConfigBackend::statusBarIconSizeChanged);
    updateField(this, m_statusBarFontWeight, jsonBoundedInt(configObject, QLatin1String("statusBarFontWeight"), 600, 300, 900), &UserConfigBackend::statusBarFontWeightChanged);
    updateField(this, m_statusBarTextOpacity, jsonBoundedInt(configObject, QLatin1String("statusBarTextOpacity"), 100, 10, 100), &UserConfigBackend::statusBarTextOpacityChanged);
    updateField(this, m_statusBarDimAmount, jsonBoundedInt(configObject, QLatin1String("statusBarDimAmount"), 40, 0, 100), &UserConfigBackend::statusBarDimAmountChanged);
    updateField(this, m_statusBarIconSpacing, jsonBoundedInt(configObject, QLatin1String("statusBarIconSpacing"), 9, 0, 40), &UserConfigBackend::statusBarIconSpacingChanged);
    updateField(this, m_statusBarWorkspaceDotSize, jsonBoundedInt(configObject, QLatin1String("statusBarWorkspaceDotSize"), 7, 2, 28), &UserConfigBackend::statusBarWorkspaceDotSizeChanged);
    updateField(this, m_statusBarWorkspaceActiveWidth, jsonBoundedInt(configObject, QLatin1String("statusBarWorkspaceActiveWidth"), 18, 4, 80), &UserConfigBackend::statusBarWorkspaceActiveWidthChanged);
    updateField(this, m_statusBarWorkspaceSpacing, jsonBoundedInt(configObject, QLatin1String("statusBarWorkspaceSpacing"), 6, 0, 40), &UserConfigBackend::statusBarWorkspaceSpacingChanged);
    updateField(this, m_statusBarWorkspaceMinimumCount, jsonBoundedInt(configObject, QLatin1String("statusBarWorkspaceMinimumCount"), 4, 1, 10), &UserConfigBackend::statusBarWorkspaceMinimumCountChanged);
    updateField(this, m_statusBarBatteryScale, jsonBoundedInt(configObject, QLatin1String("statusBarBatteryScale"), 100, 50, 220), &UserConfigBackend::statusBarBatteryScaleChanged);
    updateField(this, m_statusBarActiveWindowMaxWidth, jsonBoundedInt(configObject, QLatin1String("statusBarActiveWindowMaxWidth"), 0, 0, 1600), &UserConfigBackend::statusBarActiveWindowMaxWidthChanged);
    updateField(this, m_statusBarActiveWindowOpacity, jsonBoundedInt(configObject, QLatin1String("statusBarActiveWindowOpacity"), 100, 20, 100), &UserConfigBackend::statusBarActiveWindowOpacityChanged);
    updateField(this, m_statusBarBackgroundOpacity, jsonBoundedInt(configObject, QLatin1String("statusBarBackgroundOpacity"), 45, 0, 100), &UserConfigBackend::statusBarBackgroundOpacityChanged);
    updateField(this, m_statusBarBackgroundRadius, jsonBoundedInt(configObject, QLatin1String("statusBarBackgroundRadius"), 0, 0, 60), &UserConfigBackend::statusBarBackgroundRadiusChanged);
    updateField(this, m_statusBarBackgroundMargin, jsonBoundedInt(configObject, QLatin1String("statusBarBackgroundMargin"), 0, 0, 200), &UserConfigBackend::statusBarBackgroundMarginChanged);
    updateField(this, m_statusBarUseIslandBaseline, jsonBool(configObject, QLatin1String("statusBarUseIslandBaseline"), true), &UserConfigBackend::statusBarUseIslandBaselineChanged);
    updateField(this, m_statusBarTextShadow, jsonBool(configObject, QLatin1String("statusBarTextShadow"), true), &UserConfigBackend::statusBarTextShadowChanged);
    updateField(this, m_statusBarBackgroundEnabled, jsonBool(configObject, QLatin1String("statusBarBackgroundEnabled"), false), &UserConfigBackend::statusBarBackgroundEnabledChanged);
    updateField(this, m_statusBarShowWifi, jsonBool(configObject, QLatin1String("statusBarShowWifi"), true), &UserConfigBackend::statusBarShowWifiChanged);
    updateField(this, m_statusBarShowBluetooth, jsonBool(configObject, QLatin1String("statusBarShowBluetooth"), true), &UserConfigBackend::statusBarShowBluetoothChanged);
    updateField(this, m_statusBarShowBattery, jsonBool(configObject, QLatin1String("statusBarShowBattery"), true), &UserConfigBackend::statusBarShowBatteryChanged);
    updateField(this, m_statusBarShowMute, jsonBool(configObject, QLatin1String("statusBarShowMute"), true), &UserConfigBackend::statusBarShowMuteChanged);
    updateField(this, m_statusBarShowDate, jsonBool(configObject, QLatin1String("statusBarShowDate"), false), &UserConfigBackend::statusBarShowDateChanged);
    updateField(this, m_statusBarShowSeconds, jsonBool(configObject, QLatin1String("statusBarShowSeconds"), false), &UserConfigBackend::statusBarShowSecondsChanged);
    updateField(this, m_statusBarTextColor, jsonString(configObject, QLatin1String("statusBarTextColor"), QStringLiteral("#ffffff")), &UserConfigBackend::statusBarTextColorChanged);
    updateField(this, m_statusBarBackgroundColor, jsonString(configObject, QLatin1String("statusBarBackgroundColor"), QStringLiteral("#000000")), &UserConfigBackend::statusBarBackgroundColorChanged);
    updateField(this, m_captureVideoDirectory, jsonString(configObject, QLatin1String("captureVideoDirectory"), QString()), &UserConfigBackend::captureVideoDirectoryChanged);
    updateField(this, m_captureScreenshotDirectory, jsonString(configObject, QLatin1String("captureScreenshotDirectory"), QString()), &UserConfigBackend::captureScreenshotDirectoryChanged);
    updateField(this, m_captureAnnotationTool, jsonString(configObject, QLatin1String("captureAnnotationTool"), QString()), &UserConfigBackend::captureAnnotationToolChanged);
    updateField(this, m_captureRecordAudio, jsonBool(configObject, QLatin1String("captureRecordAudio"), true), &UserConfigBackend::captureRecordAudioChanged);
    updateField(this, m_captureCopyToClipboard, jsonBool(configObject, QLatin1String("captureCopyToClipboard"), true), &UserConfigBackend::captureCopyToClipboardChanged);
    updateField(this, m_captureNotify, jsonBool(configObject, QLatin1String("captureNotify"), true), &UserConfigBackend::captureNotifyChanged);
    updateField(this, m_captureShowScreenshotPreview, jsonBool(configObject, QLatin1String("captureShowScreenshotPreview"), true), &UserConfigBackend::captureShowScreenshotPreviewChanged);
    updateField(this, m_captureScreenshotPreviewSeconds, jsonBoundedInt(configObject, QLatin1String("captureScreenshotPreviewSeconds"), 6, 2, 60), &UserConfigBackend::captureScreenshotPreviewSecondsChanged);

    updateField(this, m_motionPreset, jsonEnum(configObject, QLatin1String("motionPreset"), QStringLiteral("default"), {QStringLiteral("default"), QStringLiteral("snappy"), QStringLiteral("bouncy"), QStringLiteral("custom")}), &UserConfigBackend::motionPresetChanged);
    updateField(this, m_motionShapeSpring, jsonBoundedInt(configObject, QLatin1String("motionShapeSpring"), 36, 10, 120), &UserConfigBackend::motionShapeSpringChanged);
    updateField(this, m_motionShapeDamping, jsonBoundedInt(configObject, QLatin1String("motionShapeDamping"), 42, 10, 100), &UserConfigBackend::motionShapeDampingChanged);
    updateField(this, m_motionRadiusSpring, jsonBoundedInt(configObject, QLatin1String("motionRadiusSpring"), 42, 10, 120), &UserConfigBackend::motionRadiusSpringChanged);
    updateField(this, m_motionRadiusDamping, jsonBoundedInt(configObject, QLatin1String("motionRadiusDamping"), 75, 10, 100), &UserConfigBackend::motionRadiusDampingChanged);
    updateField(this, m_motionContentRevealDuration, jsonBoundedInt(configObject, QLatin1String("motionContentRevealDuration"), 200, 60, 600), &UserConfigBackend::motionContentRevealDurationChanged);
    updateField(this, m_motionPressScale, jsonBoundedInt(configObject, QLatin1String("motionPressScale"), 97, 85, 100), &UserConfigBackend::motionPressScaleChanged);
    updateField(this, m_motionPulseScale, jsonBoundedInt(configObject, QLatin1String("motionPulseScale"), 105, 100, 125), &UserConfigBackend::motionPulseScaleChanged);
    updateField(this, m_motionLongPressMs, jsonBoundedInt(configObject, QLatin1String("motionLongPressMs"), 420, 150, 1200), &UserConfigBackend::motionLongPressMsChanged);
    updateField(this, m_motionIdleBreathEnabled, jsonBool(configObject, QLatin1String("motionIdleBreathEnabled"), true), &UserConfigBackend::motionIdleBreathEnabledChanged);

    updateField(this, m_idleStyle, jsonEnum(configObject, QLatin1String("idleStyle"), QStringLiteral("dot"), {QStringLiteral("dot"), QStringLiteral("orb"), QStringLiteral("clock"), QStringLiteral("blank")}), &UserConfigBackend::idleStyleChanged);
    updateField(this, m_idleShowUsageRings, jsonBool(configObject, QLatin1String("idleShowUsageRings"), false), &UserConfigBackend::idleShowUsageRingsChanged);
    updateField(this, m_idleDotSize, jsonBoundedInt(configObject, QLatin1String("idleDotSize"), 6, 2, 16), &UserConfigBackend::idleDotSizeChanged);
    updateField(this, m_idleDotOpacity, jsonBoundedInt(configObject, QLatin1String("idleDotOpacity"), 25, 5, 100), &UserConfigBackend::idleDotOpacityChanged);

    updateField(this, m_liveActivityPriority, jsonStringList(configObject, QLatin1String("liveActivityPriority"), defaultLiveActivityPriority()), &UserConfigBackend::liveActivityPriorityChanged);
    updateField(this, m_transientNotificationMs, jsonBoundedInt(configObject, QLatin1String("transientNotificationMs"), 6000, 0, 30000), &UserConfigBackend::transientNotificationMsChanged);
    updateField(this, m_transientShotMs, jsonBoundedInt(configObject, QLatin1String("transientShotMs"), 6000, 0, 30000), &UserConfigBackend::transientShotMsChanged);
    updateField(this, m_transientBannerMs, jsonBoundedInt(configObject, QLatin1String("transientBannerMs"), 5000, 0, 30000), &UserConfigBackend::transientBannerMsChanged);
    updateField(this, m_transientHudMs, jsonBoundedInt(configObject, QLatin1String("transientHudMs"), 2200, 0, 30000), &UserConfigBackend::transientHudMsChanged);
    updateField(this, m_transientClockMs, jsonBoundedInt(configObject, QLatin1String("transientClockMs"), 2600, 0, 30000), &UserConfigBackend::transientClockMsChanged);
    updateField(this, m_notificationAutoExpand, jsonBool(configObject, QLatin1String("notificationAutoExpand"), true), &UserConfigBackend::notificationAutoExpandChanged);

    updateField(this, m_controlCenterModules, jsonStringList(configObject, QLatin1String("controlCenterModules"), defaultControlCenterModules()), &UserConfigBackend::controlCenterModulesChanged);
    updateField(this, m_controlCenterShowVolume, jsonBool(configObject, QLatin1String("controlCenterShowVolume"), true), &UserConfigBackend::controlCenterShowVolumeChanged);
    updateField(this, m_controlCenterShowBrightness, jsonBool(configObject, QLatin1String("controlCenterShowBrightness"), true), &UserConfigBackend::controlCenterShowBrightnessChanged);

    updateField(this, m_mediaExcludedPlayers, jsonStringList(configObject, QLatin1String("mediaExcludedPlayers"), QVariantList()), &UserConfigBackend::mediaExcludedPlayersChanged);
    updateField(this, m_mediaPreferredPlayers, jsonStringList(configObject, QLatin1String("mediaPreferredPlayers"), QVariantList()), &UserConfigBackend::mediaPreferredPlayersChanged);

    updateField(this, m_clipboardHistoryLimit, jsonBoundedInt(configObject, QLatin1String("clipboardHistoryLimit"), 50, 5, 500), &UserConfigBackend::clipboardHistoryLimitChanged);
    updateField(this, m_clipboardExcludedApps, jsonStringList(configObject, QLatin1String("clipboardExcludedApps"), QVariantList()), &UserConfigBackend::clipboardExcludedAppsChanged);
    updateField(this, m_clipboardShowImagePreviews, jsonBool(configObject, QLatin1String("clipboardShowImagePreviews"), true), &UserConfigBackend::clipboardShowImagePreviewsChanged);

    updateField(this, m_notificationsBlockedApps, jsonStringList(configObject, QLatin1String("notificationsBlockedApps"), QVariantList()), &UserConfigBackend::notificationsBlockedAppsChanged);
    updateField(this, m_notificationsAllowedApps, jsonStringList(configObject, QLatin1String("notificationsAllowedApps"), QVariantList()), &UserConfigBackend::notificationsAllowedAppsChanged);
    updateField(this, m_doNotDisturbEnabled, jsonBool(configObject, QLatin1String("doNotDisturbEnabled"), false), &UserConfigBackend::doNotDisturbEnabledChanged);
    updateField(this, m_dndScheduleEnabled, jsonBool(configObject, QLatin1String("dndScheduleEnabled"), false), &UserConfigBackend::dndScheduleEnabledChanged);
    updateField(this, m_dndStartTime, jsonString(configObject, QLatin1String("dndStartTime"), QStringLiteral("22:00")), &UserConfigBackend::dndStartTimeChanged);
    updateField(this, m_dndEndTime, jsonString(configObject, QLatin1String("dndEndTime"), QStringLiteral("08:00")), &UserConfigBackend::dndEndTimeChanged);
    updateField(this, m_notificationsHistoryLimit, jsonBoundedInt(configObject, QLatin1String("notificationsHistoryLimit"), 30, 5, 200), &UserConfigBackend::notificationsHistoryLimitChanged);

    updateField(this, m_captureScreenshotFormat, jsonEnum(configObject, QLatin1String("captureScreenshotFormat"), QStringLiteral("png"), {QStringLiteral("png"), QStringLiteral("jpg")}), &UserConfigBackend::captureScreenshotFormatChanged);
    updateField(this, m_captureVideoFormat, jsonEnum(configObject, QLatin1String("captureVideoFormat"), QStringLiteral("mp4"), {QStringLiteral("mp4"), QStringLiteral("mkv"), QStringLiteral("webm")}), &UserConfigBackend::captureVideoFormatChanged);
    updateField(this, m_captureScreenshotNamePattern, jsonString(configObject, QLatin1String("captureScreenshotNamePattern"), QStringLiteral("Screenshot_%Y-%m-%d_%H-%M-%S")), &UserConfigBackend::captureScreenshotNamePatternChanged);
    updateField(this, m_captureVideoNamePattern, jsonString(configObject, QLatin1String("captureVideoNamePattern"), QStringLiteral("Recording_%Y-%m-%d_%H-%M-%S")), &UserConfigBackend::captureVideoNamePatternChanged);

    updateField(this, m_shellAutostartEnabled, jsonBool(configObject, QLatin1String("shellAutostartEnabled"), false), &UserConfigBackend::shellAutostartEnabledChanged);
    updateField(this, m_islandMonitorMode, jsonEnum(configObject, QLatin1String("islandMonitorMode"), QStringLiteral("all"), {QStringLiteral("all"), QStringLiteral("primary"), QStringLiteral("named")}), &UserConfigBackend::islandMonitorModeChanged);
    updateField(this, m_islandMonitorName, jsonString(configObject, QLatin1String("islandMonitorName"), QString()), &UserConfigBackend::islandMonitorNameChanged);
    updateField(this, m_statusBarMonitorMode, jsonEnum(configObject, QLatin1String("statusBarMonitorMode"), QStringLiteral("all"), {QStringLiteral("all"), QStringLiteral("primary"), QStringLiteral("named")}), &UserConfigBackend::statusBarMonitorModeChanged);
    updateField(this, m_statusBarMonitorName, jsonString(configObject, QLatin1String("statusBarMonitorName"), QString()), &UserConfigBackend::statusBarMonitorNameChanged);

    updateWatchedPaths();
}

void UserConfigBackend::updateWatchedPaths()
{
    const QString configDirectory = QFileInfo(m_userConfigPath).absolutePath();
    const QString configParentDirectory = QFileInfo(configDirectory).absolutePath();
    const QSet<QString> wantedFiles = QFileInfo::exists(m_userConfigPath)
        ? QSet<QString>{m_userConfigPath}
        : QSet<QString>{};
    QSet<QString> wantedDirectories;
    if (QFileInfo::exists(configParentDirectory))
        wantedDirectories.insert(configParentDirectory);
    if (QFileInfo::exists(configDirectory))
        wantedDirectories.insert(configDirectory);

    const QStringList currentFiles = m_watcher.files();
    for (const QString &path : currentFiles) {
        if (!wantedFiles.contains(path))
            m_watcher.removePath(path);
    }

    const QStringList currentDirectories = m_watcher.directories();
    for (const QString &path : currentDirectories) {
        if (!wantedDirectories.contains(path))
            m_watcher.removePath(path);
    }

    for (const QString &path : wantedFiles) {
        if (!m_watcher.files().contains(path))
            m_watcher.addPath(path);
    }

    for (const QString &path : wantedDirectories) {
        if (!m_watcher.directories().contains(path))
            m_watcher.addPath(path);
    }
}

QString UserConfigBackend::configHome() const
{
    const QByteArray xdgConfigHome = qgetenv("XDG_CONFIG_HOME");
    if (!xdgConfigHome.isEmpty())
        return QString::fromLocal8Bit(xdgConfigHome);

    const QByteArray home = qgetenv("HOME");
    return home.isEmpty()
        ? QStringLiteral(".")
        : QString::fromLocal8Bit(home) + QStringLiteral("/.config");
}
