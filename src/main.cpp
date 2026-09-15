#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QCoreApplication>

#include "BootcBackend.h"
#include "PolkitHelper.h"
#include "SystemBackend.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName(QStringLiteral("raku"));
    QCoreApplication::setApplicationName(QStringLiteral("K-ControlC"));
    QCoreApplication::setApplicationVersion(QStringLiteral(KCONTROLC_VERSION));

    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE"))
        qputenv("QT_QUICK_CONTROLS_STYLE", "Fusion");

    PolkitHelper polkitHelper;
    BootcBackend bootcBackend;
    SystemBackend systemBackend;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("PolkitHelper"), &polkitHelper);
    engine.rootContext()->setContextProperty(QStringLiteral("BootcBackend"), &bootcBackend);
    engine.rootContext()->setContextProperty(QStringLiteral("SystemBackend"), &systemBackend);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, [] { QCoreApplication::exit(-1); }, Qt::QueuedConnection);

    engine.loadFromModule(QStringLiteral("raku.cc"), QStringLiteral("Main"));
    return app.exec();
}
