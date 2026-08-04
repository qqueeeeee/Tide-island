pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications
import IslandBackend

// Notification feed for the island. Wraps Quickshell's freedesktop notification
// server and exposes a flat JS array shaped like the React `NotifyItem`:
// { id, app, title, body, age, urgent, glyph, tint, notification }
Item {
    id: root

    readonly property var userConfig: UserConfig

    property var items: []
    property bool dnd: false
    readonly property int count: root.items.length

    readonly property int historyLimit: Math.max(5, Math.min(200, userConfig.notificationsHistoryLimit))

    function normalizedList(raw) {
        const list = raw || [];
        const out = [];
        for (let i = 0; i < list.length; i++)
            out.push(String(list[i]).toLowerCase());
        return out;
    }

    readonly property var blockedApps: root.normalizedList(userConfig.notificationsBlockedApps)
    readonly property var allowedApps: root.normalizedList(userConfig.notificationsAllowedApps)

    function isAppAllowed(appName) {
        const name = String(appName === undefined || appName === null ? "" : appName).toLowerCase();
        for (let i = 0; i < root.blockedApps.length; i++) {
            if (name.indexOf(root.blockedApps[i]) !== -1)
                return false;
        }
        if (root.allowedApps.length === 0)
            return true;
        for (let i = 0; i < root.allowedApps.length; i++) {
            if (name.indexOf(root.allowedApps[i]) !== -1)
                return true;
        }
        return false;
    }

    function parseTimeOfDay(value) {
        const text = String(value === undefined || value === null ? "" : value);
        const match = text.match(/^(\d{1,2}):(\d{2})$/);
        if (!match)
            return -1;
        return (parseInt(match[1], 10) * 60) + parseInt(match[2], 10);
    }

    readonly property bool withinDndSchedule: {
        if (!userConfig.dndScheduleEnabled)
            return false;
        const start = root.parseTimeOfDay(userConfig.dndStartTime);
        const end = root.parseTimeOfDay(userConfig.dndEndTime);
        if (start < 0 || end < 0)
            return false;
        const now = new Date();
        const minutes = now.getHours() * 60 + now.getMinutes();
        if (start === end)
            return false;
        if (start < end)
            return minutes >= start && minutes < end;
        // Wraps past midnight, e.g. 22:00 -> 08:00.
        return minutes >= start || minutes < end;
    }

    readonly property bool effectiveDnd: userConfig.doNotDisturbEnabled || root.withinDndSchedule

    signal received(var item)

    visible: false
    width: 0
    height: 0

    IslandTokens { id: tokens }

    NotificationServer {
        id: server

        actionsSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false

        onNotification: (notification) => {
            if (!root.isAppAllowed(notification.appName)) {
                notification.dismiss();
                return;
            }

            notification.tracked = true;

            const item = root.describe(notification);
            root.items = [item].concat(root.items).slice(0, root.historyLimit);
            if (!root.dnd)
                root.received(item);
        }
    }

    onEffectiveDndChanged: root.dnd = root.effectiveDnd
    Component.onCompleted: root.dnd = root.effectiveDnd

    Timer {
        // Reevaluate the DND schedule window periodically.
        interval: 30000
        running: userConfig.dndScheduleEnabled
        repeat: true
        onTriggered: root.dnd = root.effectiveDnd
    }

    Timer {
        // Keeps the relative "2m" ages fresh while the centre is open.
        interval: 30000
        running: root.items.length > 0
        repeat: true
        onTriggered: root.items = root.items.map((item) => {
            item.age = root.ageText(item.time);
            return item;
        });
    }

    function glyphFor(appName) {
        const name = String(appName === undefined || appName === null ? "" : appName).toLowerCase();
        if (name.indexOf("mail") !== -1 || name.indexOf("thunderbird") !== -1)
            return tokens.glyphMail;
        if (name.indexOf("discord") !== -1 || name.indexOf("message") !== -1
            || name.indexOf("signal") !== -1 || name.indexOf("telegram") !== -1)
            return tokens.glyphMessage;
        if (name.indexOf("spotify") !== -1 || name.indexOf("music") !== -1)
            return tokens.glyphMusic;
        if (name.indexOf("pacman") !== -1 || name.indexOf("update") !== -1)
            return tokens.glyphPackage;
        if (name.indexOf("kitty") !== -1 || name.indexOf("term") !== -1)
            return tokens.glyphTerminal;
        return tokens.glyphBell;
    }

    function tintFor(appName) {
        const name = String(appName === undefined || appName === null ? "" : appName).toLowerCase();
        if (name.indexOf("mail") !== -1 || name.indexOf("thunderbird") !== -1)
            return tokens.accent3;
        if (name.indexOf("discord") !== -1 || name.indexOf("message") !== -1)
            return tokens.accept;
        if (name.indexOf("spotify") !== -1 || name.indexOf("music") !== -1)
            return tokens.accent2;
        if (name.indexOf("pacman") !== -1 || name.indexOf("update") !== -1)
            return tokens.nav;
        return tokens.accent;
    }

    function ageText(time) {
        const seconds = Math.max(0, Math.round((Date.now() - time) / 1000));
        if (seconds < 45)
            return "now";
        if (seconds < 3600)
            return Math.round(seconds / 60) + "m";
        if (seconds < 86400)
            return Math.round(seconds / 3600) + "h";
        return Math.round(seconds / 86400) + "d";
    }

    function describe(notification) {
        const app = String(notification.appName ? notification.appName : "System");
        const now = Date.now();
        return {
            id: String(notification.id),
            app: app,
            title: String(notification.summary ? notification.summary : app),
            body: String(notification.body ? notification.body : ""),
            image: String(notification.image ? notification.image : ""),
            urgent: notification.urgency === NotificationUrgency.Critical,
            glyph: root.glyphFor(app),
            tint: root.tintFor(app),
            time: now,
            age: "now",
            notification: notification
        };
    }

    function dismiss(id) {
        const target = root.items.find((item) => item.id === id);
        if (target && target.notification)
            target.notification.dismiss();
        root.items = root.items.filter((item) => item.id !== id);
    }

    function dismissApp(app) {
        root.items.filter((item) => item.app === app).forEach((item) => {
            if (item.notification)
                item.notification.dismiss();
        });
        root.items = root.items.filter((item) => item.app !== app);
    }

    function clearAll() {
        root.items.forEach((item) => {
            if (item.notification)
                item.notification.dismiss();
        });
        root.items = [];
    }

    function groups() {
        const order = [];
        const map = ({});
        for (let index = 0; index < root.items.length; ++index) {
            const item = root.items[index];
            if (map[item.app] === undefined) {
                map[item.app] = [];
                order.push(item.app);
            }
            map[item.app].push(item);
        }
        return order.map((app) => ({ app: app, items: map[app] }));
    }
}
