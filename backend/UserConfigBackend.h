#pragma once

#include <QFileSystemWatcher>
#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QtQml/qqml.h>

class UserConfigBackend final : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(UserConfig)
    QML_SINGLETON

    Q_PROPERTY(QString userConfigPath READ userConfigPath CONSTANT FINAL)
    Q_PROPERTY(QString configError READ configError NOTIFY configErrorChanged FINAL)
    Q_PROPERTY(QString defaultWallpaperPath READ defaultWallpaperPath WRITE setDefaultWallpaperPath NOTIFY defaultWallpaperPathChanged FINAL)
    Q_PROPERTY(QString defaultTlpSudoPassword READ defaultTlpSudoPassword WRITE setDefaultTlpSudoPassword NOTIFY defaultTlpSudoPasswordChanged FINAL)

    Q_PROPERTY(QString wallpaperPath READ wallpaperPath NOTIFY wallpaperPathChanged FINAL)
    Q_PROPERTY(QString wallpaperLibraryPath READ wallpaperLibraryPath NOTIFY wallpaperLibraryPathChanged FINAL)
    Q_PROPERTY(bool wallpaperPywalEnabled READ wallpaperPywalEnabled NOTIFY wallpaperPywalEnabledChanged FINAL)
    Q_PROPERTY(bool wallpaperCustomCommandEnabled READ wallpaperCustomCommandEnabled NOTIFY wallpaperCustomCommandEnabledChanged FINAL)
    Q_PROPERTY(QString wallpaperCustomCommand READ wallpaperCustomCommand NOTIFY wallpaperCustomCommandChanged FINAL)
    Q_PROPERTY(QString wallpaperTransitionType READ wallpaperTransitionType NOTIFY wallpaperTransitionTypeChanged FINAL)
    Q_PROPERTY(int wallpaperTransitionStep READ wallpaperTransitionStep NOTIFY wallpaperTransitionStepChanged FINAL)
    Q_PROPERTY(double wallpaperTransitionDuration READ wallpaperTransitionDuration NOTIFY wallpaperTransitionDurationChanged FINAL)
    Q_PROPERTY(int wallpaperTransitionFps READ wallpaperTransitionFps NOTIFY wallpaperTransitionFpsChanged FINAL)
    Q_PROPERTY(int wallpaperTransitionAngle READ wallpaperTransitionAngle NOTIFY wallpaperTransitionAngleChanged FINAL)
    Q_PROPERTY(QString wallpaperTransitionPosition READ wallpaperTransitionPosition NOTIFY wallpaperTransitionPositionChanged FINAL)
    Q_PROPERTY(QString wallpaperTransitionBezier READ wallpaperTransitionBezier NOTIFY wallpaperTransitionBezierChanged FINAL)
    Q_PROPERTY(QString wallpaperTransitionWave READ wallpaperTransitionWave NOTIFY wallpaperTransitionWaveChanged FINAL)
    Q_PROPERTY(bool wallpaperTransitionInvertY READ wallpaperTransitionInvertY NOTIFY wallpaperTransitionInvertYChanged FINAL)
    Q_PROPERTY(QString iconFontFamily READ iconFontFamily NOTIFY iconFontFamilyChanged FINAL)
    Q_PROPERTY(QString textFontFamily READ textFontFamily NOTIFY textFontFamilyChanged FINAL)
    Q_PROPERTY(QString heroFontFamily READ heroFontFamily NOTIFY heroFontFamilyChanged FINAL)
    Q_PROPERTY(QString timeFontFamily READ timeFontFamily NOTIFY timeFontFamilyChanged FINAL)
    Q_PROPERTY(QString clockFormat READ clockFormat NOTIFY clockFormatChanged FINAL)
    Q_PROPERTY(QString tlpSudoPassword READ tlpSudoPassword NOTIFY tlpSudoPasswordChanged FINAL)
    Q_PROPERTY(QString tlpPermissionMode READ tlpPermissionMode NOTIFY tlpPermissionModeChanged FINAL)

    Q_PROPERTY(int workspaceOverviewWindowDragButton READ workspaceOverviewWindowDragButton NOTIFY workspaceOverviewWindowDragButtonChanged FINAL)

    Q_PROPERTY(int dynamicIslandPrimaryButton READ dynamicIslandPrimaryButton NOTIFY dynamicIslandPrimaryButtonChanged FINAL)
    Q_PROPERTY(QString dynamicIslandPrimaryAction READ dynamicIslandPrimaryAction NOTIFY dynamicIslandPrimaryActionChanged FINAL)
    Q_PROPERTY(int dynamicIslandSecondaryButton READ dynamicIslandSecondaryButton NOTIFY dynamicIslandSecondaryButtonChanged FINAL)
    Q_PROPERTY(QString dynamicIslandSecondaryAction READ dynamicIslandSecondaryAction NOTIFY dynamicIslandSecondaryActionChanged FINAL)
    Q_PROPERTY(QVariantList dynamicIslandLeftSwipeItems READ dynamicIslandLeftSwipeItems NOTIFY dynamicIslandLeftSwipeItemsChanged FINAL)
    Q_PROPERTY(bool disableAutoExpandOnTrackChange READ disableAutoExpandOnTrackChange NOTIFY disableAutoExpandOnTrackChangeChanged FINAL)
    Q_PROPERTY(int hoverExpandAction READ hoverExpandAction NOTIFY hoverExpandActionChanged FINAL)
    Q_PROPERTY(bool islandAutoHideEnabled READ islandAutoHideEnabled NOTIFY islandAutoHideEnabledChanged FINAL)
    Q_PROPERTY(int islandAutoHideDelayMs READ islandAutoHideDelayMs NOTIFY islandAutoHideDelayMsChanged FINAL)

    Q_PROPERTY(int islandWidth READ islandWidth NOTIFY islandWidthChanged FINAL)
    Q_PROPERTY(int islandHeight READ islandHeight NOTIFY islandHeightChanged FINAL)
    Q_PROPERTY(bool islandHeightOverrideEnabled READ islandHeightOverrideEnabled NOTIFY islandHeightOverrideEnabledChanged FINAL)
    Q_PROPERTY(int islandExclusiveZone READ islandExclusiveZone NOTIFY islandExclusiveZoneChanged FINAL)
    Q_PROPERTY(int islandTopMargin READ islandTopMargin NOTIFY islandTopMarginChanged FINAL)
    Q_PROPERTY(int islandScale READ islandScale NOTIFY islandScaleChanged FINAL)
    Q_PROPERTY(int islandCornerRadius READ islandCornerRadius NOTIFY islandCornerRadiusChanged FINAL)
    Q_PROPERTY(int islandBottomGap READ islandBottomGap NOTIFY islandBottomGapChanged FINAL)
    Q_PROPERTY(bool islandReserveSpace READ islandReserveSpace NOTIFY islandReserveSpaceChanged FINAL)
    Q_PROPERTY(int statusBarIslandGap READ statusBarIslandGap NOTIFY statusBarIslandGapChanged FINAL)
    Q_PROPERTY(int statusBarItemSpacing READ statusBarItemSpacing NOTIFY statusBarItemSpacingChanged FINAL)
    Q_PROPERTY(int statusBarBaselineOffset READ statusBarBaselineOffset NOTIFY statusBarBaselineOffsetChanged FINAL)
    Q_PROPERTY(int islandPositionX READ islandPositionX NOTIFY islandPositionXChanged FINAL)
    Q_PROPERTY(bool islandMacNotchStyle READ islandMacNotchStyle NOTIFY islandMacNotchStyleChanged FINAL)
    Q_PROPERTY(int islandBackgroundOpacity READ islandBackgroundOpacity NOTIFY islandBackgroundOpacityChanged FINAL)
    Q_PROPERTY(int bodyFontSize READ bodyFontSize NOTIFY bodyFontSizeChanged FINAL)
    Q_PROPERTY(int titleFontSize READ titleFontSize NOTIFY titleFontSizeChanged FINAL)
    Q_PROPERTY(int iconFontSize READ iconFontSize NOTIFY iconFontSizeChanged FINAL)

    Q_PROPERTY(bool statusBarEnabled READ statusBarEnabled NOTIFY statusBarEnabledChanged FINAL)
    Q_PROPERTY(int statusBarSideMargin READ statusBarSideMargin NOTIFY statusBarSideMarginChanged FINAL)
    Q_PROPERTY(int statusBarOpacity READ statusBarOpacity NOTIFY statusBarOpacityChanged FINAL)
    Q_PROPERTY(bool statusBarShowWorkspaces READ statusBarShowWorkspaces NOTIFY statusBarShowWorkspacesChanged FINAL)
    Q_PROPERTY(bool statusBarShowActiveWindow READ statusBarShowActiveWindow NOTIFY statusBarShowActiveWindowChanged FINAL)
    Q_PROPERTY(bool statusBarShowStatusIcons READ statusBarShowStatusIcons NOTIFY statusBarShowStatusIconsChanged FINAL)
    Q_PROPERTY(bool statusBarShowClock READ statusBarShowClock NOTIFY statusBarShowClockChanged FINAL)
    Q_PROPERTY(bool statusBarShowDateOnHover READ statusBarShowDateOnHover NOTIFY statusBarShowDateOnHoverChanged FINAL)
    Q_PROPERTY(bool statusBarFadeWithIsland READ statusBarFadeWithIsland NOTIFY statusBarFadeWithIslandChanged FINAL)
    Q_PROPERTY(bool statusBarShowRecordingPill READ statusBarShowRecordingPill NOTIFY statusBarShowRecordingPillChanged FINAL)
    Q_PROPERTY(int statusBarHeight READ statusBarHeight NOTIFY statusBarHeightChanged FINAL)
    Q_PROPERTY(int statusBarTopMargin READ statusBarTopMargin NOTIFY statusBarTopMarginChanged FINAL)
    Q_PROPERTY(int statusBarFontSize READ statusBarFontSize NOTIFY statusBarFontSizeChanged FINAL)
    Q_PROPERTY(int statusBarClockFontSize READ statusBarClockFontSize NOTIFY statusBarClockFontSizeChanged FINAL)
    Q_PROPERTY(int statusBarIconSize READ statusBarIconSize NOTIFY statusBarIconSizeChanged FINAL)
    Q_PROPERTY(int statusBarFontWeight READ statusBarFontWeight NOTIFY statusBarFontWeightChanged FINAL)
    Q_PROPERTY(int statusBarTextOpacity READ statusBarTextOpacity NOTIFY statusBarTextOpacityChanged FINAL)
    Q_PROPERTY(int statusBarDimAmount READ statusBarDimAmount NOTIFY statusBarDimAmountChanged FINAL)
    Q_PROPERTY(int statusBarIconSpacing READ statusBarIconSpacing NOTIFY statusBarIconSpacingChanged FINAL)
    Q_PROPERTY(int statusBarWorkspaceDotSize READ statusBarWorkspaceDotSize NOTIFY statusBarWorkspaceDotSizeChanged FINAL)
    Q_PROPERTY(int statusBarWorkspaceActiveWidth READ statusBarWorkspaceActiveWidth NOTIFY statusBarWorkspaceActiveWidthChanged FINAL)
    Q_PROPERTY(int statusBarWorkspaceSpacing READ statusBarWorkspaceSpacing NOTIFY statusBarWorkspaceSpacingChanged FINAL)
    Q_PROPERTY(int statusBarWorkspaceMinimumCount READ statusBarWorkspaceMinimumCount NOTIFY statusBarWorkspaceMinimumCountChanged FINAL)
    Q_PROPERTY(int statusBarBatteryScale READ statusBarBatteryScale NOTIFY statusBarBatteryScaleChanged FINAL)
    Q_PROPERTY(int statusBarActiveWindowMaxWidth READ statusBarActiveWindowMaxWidth NOTIFY statusBarActiveWindowMaxWidthChanged FINAL)
    Q_PROPERTY(int statusBarActiveWindowOpacity READ statusBarActiveWindowOpacity NOTIFY statusBarActiveWindowOpacityChanged FINAL)
    Q_PROPERTY(int statusBarBackgroundOpacity READ statusBarBackgroundOpacity NOTIFY statusBarBackgroundOpacityChanged FINAL)
    Q_PROPERTY(int statusBarBackgroundRadius READ statusBarBackgroundRadius NOTIFY statusBarBackgroundRadiusChanged FINAL)
    Q_PROPERTY(int statusBarBackgroundMargin READ statusBarBackgroundMargin NOTIFY statusBarBackgroundMarginChanged FINAL)
    Q_PROPERTY(bool statusBarUseIslandBaseline READ statusBarUseIslandBaseline NOTIFY statusBarUseIslandBaselineChanged FINAL)
    Q_PROPERTY(bool statusBarTextShadow READ statusBarTextShadow NOTIFY statusBarTextShadowChanged FINAL)
    Q_PROPERTY(bool statusBarBackgroundEnabled READ statusBarBackgroundEnabled NOTIFY statusBarBackgroundEnabledChanged FINAL)
    Q_PROPERTY(bool statusBarShowWifi READ statusBarShowWifi NOTIFY statusBarShowWifiChanged FINAL)
    Q_PROPERTY(bool statusBarShowBluetooth READ statusBarShowBluetooth NOTIFY statusBarShowBluetoothChanged FINAL)
    Q_PROPERTY(bool statusBarShowBattery READ statusBarShowBattery NOTIFY statusBarShowBatteryChanged FINAL)
    Q_PROPERTY(bool statusBarShowMute READ statusBarShowMute NOTIFY statusBarShowMuteChanged FINAL)
    Q_PROPERTY(bool statusBarShowDate READ statusBarShowDate NOTIFY statusBarShowDateChanged FINAL)
    Q_PROPERTY(bool statusBarShowSeconds READ statusBarShowSeconds NOTIFY statusBarShowSecondsChanged FINAL)
    Q_PROPERTY(QString statusBarTextColor READ statusBarTextColor NOTIFY statusBarTextColorChanged FINAL)
    Q_PROPERTY(QString statusBarBackgroundColor READ statusBarBackgroundColor NOTIFY statusBarBackgroundColorChanged FINAL)
    Q_PROPERTY(QString captureVideoDirectory READ captureVideoDirectory NOTIFY captureVideoDirectoryChanged FINAL)
    Q_PROPERTY(QString captureScreenshotDirectory READ captureScreenshotDirectory NOTIFY captureScreenshotDirectoryChanged FINAL)
    Q_PROPERTY(QString captureAnnotationTool READ captureAnnotationTool NOTIFY captureAnnotationToolChanged FINAL)
    Q_PROPERTY(bool captureRecordAudio READ captureRecordAudio NOTIFY captureRecordAudioChanged FINAL)
    Q_PROPERTY(bool captureCopyToClipboard READ captureCopyToClipboard NOTIFY captureCopyToClipboardChanged FINAL)
    Q_PROPERTY(bool captureNotify READ captureNotify NOTIFY captureNotifyChanged FINAL)
    Q_PROPERTY(bool captureShowScreenshotPreview READ captureShowScreenshotPreview NOTIFY captureShowScreenshotPreviewChanged FINAL)
    Q_PROPERTY(int captureScreenshotPreviewSeconds READ captureScreenshotPreviewSeconds NOTIFY captureScreenshotPreviewSecondsChanged FINAL)

public:
    explicit UserConfigBackend(QObject *parent = nullptr);

    QString userConfigPath() const;
    QString configError() const;
    QString defaultWallpaperPath() const;
    QString defaultTlpSudoPassword() const;
    QString wallpaperPath() const;
    QString wallpaperLibraryPath() const;
    bool wallpaperPywalEnabled() const;
    bool wallpaperCustomCommandEnabled() const;
    QString wallpaperCustomCommand() const;
    QString wallpaperTransitionType() const;
    int wallpaperTransitionStep() const;
    double wallpaperTransitionDuration() const;
    int wallpaperTransitionFps() const;
    int wallpaperTransitionAngle() const;
    QString wallpaperTransitionPosition() const;
    QString wallpaperTransitionBezier() const;
    QString wallpaperTransitionWave() const;
    bool wallpaperTransitionInvertY() const;
    QString iconFontFamily() const;
    QString textFontFamily() const;
    QString heroFontFamily() const;
    QString timeFontFamily() const;
    QString clockFormat() const;
    QString tlpSudoPassword() const;
    QString tlpPermissionMode() const;
    int workspaceOverviewWindowDragButton() const;
    int dynamicIslandPrimaryButton() const;
    QString dynamicIslandPrimaryAction() const;
    int dynamicIslandSecondaryButton() const;
    QString dynamicIslandSecondaryAction() const;
    const QVariantList &dynamicIslandLeftSwipeItems() const;
    bool disableAutoExpandOnTrackChange() const;
    int hoverExpandAction() const;
    bool islandAutoHideEnabled() const;
    int islandAutoHideDelayMs() const;
    int islandWidth() const;
    int islandHeight() const;
    bool islandHeightOverrideEnabled() const;
    int islandExclusiveZone() const;
    int islandTopMargin() const;
    int islandScale() const;
    int islandCornerRadius() const;
    int islandBottomGap() const;
    bool islandReserveSpace() const;
    int statusBarIslandGap() const;
    int statusBarItemSpacing() const;
    int statusBarBaselineOffset() const;
    int islandPositionX() const;
    bool islandMacNotchStyle() const;
    int islandBackgroundOpacity() const;
    int bodyFontSize() const;
    int titleFontSize() const;
    int iconFontSize() const;
    bool statusBarEnabled() const;
    int statusBarSideMargin() const;
    int statusBarOpacity() const;
    bool statusBarShowWorkspaces() const;
    bool statusBarShowActiveWindow() const;
    bool statusBarShowStatusIcons() const;
    bool statusBarShowClock() const;
    bool statusBarShowDateOnHover() const;
    bool statusBarFadeWithIsland() const;
    bool statusBarShowRecordingPill() const;
    int statusBarHeight() const;
    int statusBarTopMargin() const;
    int statusBarFontSize() const;
    int statusBarClockFontSize() const;
    int statusBarIconSize() const;
    int statusBarFontWeight() const;
    int statusBarTextOpacity() const;
    int statusBarDimAmount() const;
    int statusBarIconSpacing() const;
    int statusBarWorkspaceDotSize() const;
    int statusBarWorkspaceActiveWidth() const;
    int statusBarWorkspaceSpacing() const;
    int statusBarWorkspaceMinimumCount() const;
    int statusBarBatteryScale() const;
    int statusBarActiveWindowMaxWidth() const;
    int statusBarActiveWindowOpacity() const;
    int statusBarBackgroundOpacity() const;
    int statusBarBackgroundRadius() const;
    int statusBarBackgroundMargin() const;
    bool statusBarUseIslandBaseline() const;
    bool statusBarTextShadow() const;
    bool statusBarBackgroundEnabled() const;
    bool statusBarShowWifi() const;
    bool statusBarShowBluetooth() const;
    bool statusBarShowBattery() const;
    bool statusBarShowMute() const;
    bool statusBarShowDate() const;
    bool statusBarShowSeconds() const;
    QString statusBarTextColor() const;
    QString statusBarBackgroundColor() const;
    QString captureVideoDirectory() const;
    QString captureScreenshotDirectory() const;
    QString captureAnnotationTool() const;
    bool captureRecordAudio() const;
    bool captureCopyToClipboard() const;
    bool captureNotify() const;
    bool captureShowScreenshotPreview() const;
    int captureScreenshotPreviewSeconds() const;
    void setDefaultWallpaperPath(const QString &path);
    void setDefaultTlpSudoPassword(const QString &password);

    Q_INVOKABLE int mouseButton(const QVariant &button) const;
    Q_INVOKABLE int mouseButtonsMask(const QVariant &buttons) const;
    Q_INVOKABLE void reload();

signals:
    void configErrorChanged();
    void defaultWallpaperPathChanged();
    void defaultTlpSudoPasswordChanged();
    void wallpaperPathChanged();
    void wallpaperLibraryPathChanged();
    void wallpaperPywalEnabledChanged();
    void wallpaperCustomCommandEnabledChanged();
    void wallpaperCustomCommandChanged();
    void wallpaperTransitionTypeChanged();
    void wallpaperTransitionStepChanged();
    void wallpaperTransitionDurationChanged();
    void wallpaperTransitionFpsChanged();
    void wallpaperTransitionAngleChanged();
    void wallpaperTransitionPositionChanged();
    void wallpaperTransitionBezierChanged();
    void wallpaperTransitionWaveChanged();
    void wallpaperTransitionInvertYChanged();
    void iconFontFamilyChanged();
    void textFontFamilyChanged();
    void heroFontFamilyChanged();
    void timeFontFamilyChanged();
    void clockFormatChanged();
    void tlpSudoPasswordChanged();
    void tlpPermissionModeChanged();
    void workspaceOverviewWindowDragButtonChanged();
    void dynamicIslandPrimaryButtonChanged();
    void dynamicIslandPrimaryActionChanged();
    void dynamicIslandSecondaryButtonChanged();
    void dynamicIslandSecondaryActionChanged();
    void dynamicIslandLeftSwipeItemsChanged();
    void disableAutoExpandOnTrackChangeChanged();
    void hoverExpandActionChanged();
    void islandAutoHideEnabledChanged();
    void islandAutoHideDelayMsChanged();
    void islandWidthChanged();
    void islandHeightChanged();
    void islandHeightOverrideEnabledChanged();
    void islandExclusiveZoneChanged();
    void islandTopMarginChanged();
    void islandScaleChanged();
    void islandCornerRadiusChanged();
    void islandBottomGapChanged();
    void islandReserveSpaceChanged();
    void statusBarIslandGapChanged();
    void statusBarItemSpacingChanged();
    void statusBarBaselineOffsetChanged();
    void islandPositionXChanged();
    void islandMacNotchStyleChanged();
    void islandBackgroundOpacityChanged();
    void bodyFontSizeChanged();
    void titleFontSizeChanged();
    void iconFontSizeChanged();
    void statusBarEnabledChanged();
    void statusBarSideMarginChanged();
    void statusBarOpacityChanged();
    void statusBarShowWorkspacesChanged();
    void statusBarShowActiveWindowChanged();
    void statusBarShowStatusIconsChanged();
    void statusBarShowClockChanged();
    void statusBarShowDateOnHoverChanged();
    void statusBarFadeWithIslandChanged();
    void statusBarShowRecordingPillChanged();
    void statusBarHeightChanged();
    void statusBarTopMarginChanged();
    void statusBarFontSizeChanged();
    void statusBarClockFontSizeChanged();
    void statusBarIconSizeChanged();
    void statusBarFontWeightChanged();
    void statusBarTextOpacityChanged();
    void statusBarDimAmountChanged();
    void statusBarIconSpacingChanged();
    void statusBarWorkspaceDotSizeChanged();
    void statusBarWorkspaceActiveWidthChanged();
    void statusBarWorkspaceSpacingChanged();
    void statusBarWorkspaceMinimumCountChanged();
    void statusBarBatteryScaleChanged();
    void statusBarActiveWindowMaxWidthChanged();
    void statusBarActiveWindowOpacityChanged();
    void statusBarBackgroundOpacityChanged();
    void statusBarBackgroundRadiusChanged();
    void statusBarBackgroundMarginChanged();
    void statusBarUseIslandBaselineChanged();
    void statusBarTextShadowChanged();
    void statusBarBackgroundEnabledChanged();
    void statusBarShowWifiChanged();
    void statusBarShowBluetoothChanged();
    void statusBarShowBatteryChanged();
    void statusBarShowMuteChanged();
    void statusBarShowDateChanged();
    void statusBarShowSecondsChanged();
    void statusBarTextColorChanged();
    void statusBarBackgroundColorChanged();
    void captureVideoDirectoryChanged();
    void captureScreenshotDirectoryChanged();
    void captureAnnotationToolChanged();
    void captureRecordAudioChanged();
    void captureCopyToClipboardChanged();
    void captureNotifyChanged();
    void captureShowScreenshotPreviewChanged();
    void captureScreenshotPreviewSecondsChanged();

private:
    void scheduleReload();
    void loadConfig();
    void updateWatchedPaths();
    QString configHome() const;

    QString m_userConfigPath;
    QString m_configError;
    QString m_defaultWallpaperPath;
    QString m_defaultTlpSudoPassword;
    QString m_wallpaperPath;
    QString m_wallpaperLibraryPath;
    bool m_wallpaperPywalEnabled = false;
    bool m_wallpaperCustomCommandEnabled = false;
    QString m_wallpaperCustomCommand;
    QString m_wallpaperTransitionType = QStringLiteral("center");
    int m_wallpaperTransitionStep = 5;
    double m_wallpaperTransitionDuration = 3.0;
    int m_wallpaperTransitionFps = 60;
    int m_wallpaperTransitionAngle = 45;
    QString m_wallpaperTransitionPosition = QStringLiteral("center");
    QString m_wallpaperTransitionBezier = QStringLiteral(".54,0,.34,.99");
    QString m_wallpaperTransitionWave = QStringLiteral("20,20");
    bool m_wallpaperTransitionInvertY = false;
    QString m_iconFontFamily = QStringLiteral("JetBrainsMono Nerd Font");
    QString m_textFontFamily = QStringLiteral("Inter Display");
    QString m_heroFontFamily = QStringLiteral("Inter Display");
    QString m_timeFontFamily = QStringLiteral("Inter Display");
    QString m_clockFormat = QStringLiteral("12");
    QString m_tlpSudoPassword;
    QString m_tlpPermissionMode = QStringLiteral("skip");
    int m_workspaceOverviewWindowDragButton = 1;
    int m_dynamicIslandPrimaryButton = 1;
    QString m_dynamicIslandPrimaryAction = QStringLiteral("toggleExpandedPlayer");
    int m_dynamicIslandSecondaryButton = 3;
    QString m_dynamicIslandSecondaryAction = QStringLiteral("toggleControlCenter");
    QVariantList m_dynamicIslandLeftSwipeItems;
    bool m_disableAutoExpandOnTrackChange = false;
    int m_hoverExpandAction = 1;
    bool m_islandAutoHideEnabled = true;
    int m_islandAutoHideDelayMs = 1000;
    int m_islandWidth = 125;
    int m_islandBackgroundOpacity = 100;
    int m_islandHeight = 37;
    bool m_islandHeightOverrideEnabled = false;
    int m_islandExclusiveZone = 45;
    int m_islandTopMargin = 11;
    int m_islandScale = 100;
    int m_islandCornerRadius = 32;
    int m_islandBottomGap = 8;
    bool m_islandReserveSpace = true;
    int m_statusBarIslandGap = 14;
    int m_statusBarItemSpacing = 14;
    int m_statusBarBaselineOffset = 0;
    int m_islandPositionX = 50;
    bool m_islandMacNotchStyle = true;
    int m_bodyFontSize = 16;
    int m_titleFontSize = 20;
    int m_iconFontSize = 18;
    bool m_statusBarEnabled = true;
    int m_statusBarSideMargin = 22;
    int m_statusBarOpacity = 100;
    bool m_statusBarShowWorkspaces = true;
    bool m_statusBarShowActiveWindow = true;
    bool m_statusBarShowStatusIcons = true;
    bool m_statusBarShowClock = true;
    bool m_statusBarShowDateOnHover = true;
    bool m_statusBarFadeWithIsland = true;
    bool m_statusBarShowRecordingPill = true;
    int m_statusBarHeight = 34;
    int m_statusBarTopMargin = 0;
    int m_statusBarFontSize = 13;
    int m_statusBarClockFontSize = 13;
    int m_statusBarIconSize = 13;
    int m_statusBarFontWeight = 600;
    int m_statusBarTextOpacity = 100;
    int m_statusBarDimAmount = 40;
    int m_statusBarIconSpacing = 9;
    int m_statusBarWorkspaceDotSize = 7;
    int m_statusBarWorkspaceActiveWidth = 18;
    int m_statusBarWorkspaceSpacing = 6;
    int m_statusBarWorkspaceMinimumCount = 4;
    int m_statusBarBatteryScale = 100;
    int m_statusBarActiveWindowMaxWidth = 0;
    int m_statusBarActiveWindowOpacity = 100;
    int m_statusBarBackgroundOpacity = 45;
    int m_statusBarBackgroundRadius = 0;
    int m_statusBarBackgroundMargin = 0;
    bool m_statusBarUseIslandBaseline = true;
    bool m_statusBarTextShadow = true;
    bool m_statusBarBackgroundEnabled = false;
    bool m_statusBarShowWifi = true;
    bool m_statusBarShowBluetooth = true;
    bool m_statusBarShowBattery = true;
    bool m_statusBarShowMute = true;
    bool m_statusBarShowDate = false;
    bool m_statusBarShowSeconds = false;
    QString m_statusBarTextColor = QStringLiteral("#ffffff");
    QString m_statusBarBackgroundColor = QStringLiteral("#000000");
    QString m_captureVideoDirectory;
    QString m_captureScreenshotDirectory;
    QString m_captureAnnotationTool;
    bool m_captureRecordAudio = true;
    bool m_captureCopyToClipboard = true;
    bool m_captureNotify = true;
    bool m_captureShowScreenshotPreview = true;
    int m_captureScreenshotPreviewSeconds = 6;

    QFileSystemWatcher m_watcher;
    QTimer m_reloadTimer;
};
