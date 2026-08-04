# 11 — Settings reference (config keys added in the parity pass)


All new config keys use the identical JSON key across: backend/UserConfigBackend.h,
backend/UserConfigBackend.cpp (loadFromJson, jsonBoundedInt/jsonBool/jsonString helpers),
the consuming shell QML, Tide-island-app/ConfigStore.qml defaults, and a Tide-island-app/Page*.qml control.

IMPORTANT: defaults MUST reproduce the shell's current behaviour exactly. Nothing about the live
shell look/behaviour may change when the config file is empty.

## Motion  (consumer: qml/nucleus/IslandMotion.qml)
| key | type | range | default |
|---|---|---|---|
| motionPreset | string | default\|snappy\|bouncy\|custom | "default" |
| motionShapeSpring | int (spring x10) | 10..120 | 36 |
| motionShapeDamping | int (x100) | 10..100 | 42 |
| motionRadiusSpring | int (x10) | 10..120 | 42 |
| motionRadiusDamping | int (x100) | 10..100 | 75 |
| motionContentRevealDuration | int ms | 60..600 | 200 |
| motionPressScale | int (x100) | 85..100 | 97 |
| motionPulseScale | int (x100) | 100..125 | 105 |
| motionLongPressMs | int ms | 150..1200 | 420 |
| motionIdleBreathEnabled | bool | | true |

Presets resolved inside IslandMotion.qml (preset != "custom" overrides the raw numbers):
snappy = shape 52/62, radius 60/85; default = 36/42, 42/75; bouncy = 30/28, 34/55.

## Idle base state  (consumer: qml/nucleus/IdleLayer.qml, and NucleusIslandWindow for style switch)
| idleStyle | string | dot\|orb\|clock\|blank | "dot" |
| idleShowUsageRings | bool | | false |
| idleDotSize | int px | 2..16 | 6 |
| idleDotOpacity | int % | 5..100 | 25 |

## Live activities  (consumer: qml/nucleus/NucleusIslandWindow.qml)
| liveActivityPriority | QVariantList of strings | | ["recording","media"] |
| transientNotificationMs | int | 0..30000 | 6000 |
| transientShotMs | int | 0..30000 | 6000 |
| transientBannerMs | int | 0..30000 | 5000 |
| transientHudMs | int | 0..30000 | 2200 |
| transientClockMs | int | 0..30000 | 2600 |
| notificationAutoExpand | bool | | true |

`activity` resolution must walk liveActivityPriority instead of the hardcoded recording-then-media chain
(unknown ids ignored; anything omitted falls through to idle).

## Control center  (consumer: qml/nucleus/IosControlCenterLayer.qml)
| controlCenterModules | QVariantList | | ["wifi","bluetooth","mic","nightlight"] |
| controlCenterShowVolume | bool | | true |
| controlCenterShowBrightness | bool | | true |

Toggle row is built from controlCenterModules order; unknown ids ignored.

## Media  (consumer: qml/nucleus/MediaSource.qml)
| mediaExcludedPlayers | QVariantList of lowercase substrings | | [] |
| mediaPreferredPlayers | QVariantList | | [] |

## Clipboard  (consumer: qml/nucleus/ClipboardSource.qml)
| clipboardHistoryLimit | int | 5..500 | 50 |
| clipboardExcludedApps | QVariantList | | [] |
| clipboardShowImagePreviews | bool | | true |

## Notifications  (consumer: qml/nucleus/NotifySource.qml)
| notificationsBlockedApps | QVariantList | | [] |
| notificationsAllowedApps | QVariantList (empty = all allowed) | | [] |
| doNotDisturbEnabled | bool | | false |
| dndScheduleEnabled | bool | | false |
| dndStartTime | string "HH:MM" | | "22:00" |
| dndEndTime | string "HH:MM" | | "08:00" |
| notificationsHistoryLimit | int | 5..200 | 30 |

## Capture  (consumer: qml/common/CaptureController.qml)
| captureScreenshotFormat | string png\|jpg | | "png" |
| captureVideoFormat | string mp4\|mkv\|webm | | "mp4" |
| captureScreenshotNamePattern | string (strftime) | | "Screenshot_%Y-%m-%d_%H-%M-%S" |
| captureVideoNamePattern | string (strftime) | | "Recording_%Y-%m-%d_%H-%M-%S" |

## General / monitors  (consumer: shell.qml Variants filtering)
| shellAutostartEnabled | bool | | false |
| islandMonitorMode | string all\|primary\|named | | "all" |
| islandMonitorName | string | | "" |
| statusBarMonitorMode | string all\|primary\|named | | "all" |
| statusBarMonitorName | string | | "" |

## Settings app pages
Existing: PageIsland, PageStatusBar, PageAppearance, PageCapture, PageWallpaper, PageShortcuts, PageAbout.
New: PageMotion.qml (motion + idle), PageActivities.qml (live activity priority, transient durations,
control center modules, media excludes, clipboard), PageNotifications.qml, PageGeneral.qml (autostart, monitors).
