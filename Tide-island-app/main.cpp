#include <QCoreApplication>
#include <QGuiApplication>
#include <QDebug>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "backend.hpp"

int main(int argc, char *argv[]) {
    bool ensureNiriShortcuts = false;
    bool validateQml = false;
    QString startupPage;
    for (int index = 1; index < argc; ++index) {
        const QString argument = QString::fromLocal8Bit(argv[index]);
        ensureNiriShortcuts = ensureNiriShortcuts || argument == QStringLiteral("--ensure-niri-shortcuts");
        validateQml = validateQml || argument == QStringLiteral("--validate-qml");
        // `--page wallpaper` (or --page=wallpaper) opens straight onto a page.
        if (argument.startsWith(QStringLiteral("--page="))) {
            startupPage = argument.sliced(7);
        } else if (argument == QStringLiteral("--page") && index + 1 < argc) {
            startupPage = QString::fromLocal8Bit(argv[index + 1]);
            ++index;
        }
    }

    if (ensureNiriShortcuts) {
        QCoreApplication app(argc, argv);
        Backend backend;
        if (!backend.niriShortcutBindingsNeedApply())
            return 0;
        if (backend.ensureNiriShortcutBindings())
            return 0;
        qCritical().noquote() << backend.errorString();
        return 1;
    }

    QGuiApplication app(argc, argv);
    Backend backend;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("backend"), &backend);
    engine.rootContext()->setContextProperty(QStringLiteral("startupPage"), startupPage.trimmed().toLower());
    engine.loadFromModule(QStringLiteral("TideIsland"), QStringLiteral("Main"));
    if (engine.rootObjects().isEmpty()) return -1;
    if (validateQml) return 0;
    return app.exec();
}
