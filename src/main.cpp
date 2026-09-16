#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTimer>
#include <QtQml/qqml.h>

#include "BootcBackend.h"
#include "PackageSearch.h"
#include "PolkitHelper.h"
#include "SoftwareBackend.h"
#include "SystemBackend.h"
#include "UtilityBackend.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName(QStringLiteral("krisCC"));
    QCoreApplication::setApplicationName(QStringLiteral("krisCC"));
    QCoreApplication::setApplicationVersion(QStringLiteral(KRISCC_VERSION));

    qmlRegisterType<PackageSearch>("org.kriscc", 1, 0, "PackageSearch");

    PolkitHelper polkitHelper;
    BootcBackend bootcBackend;
    SoftwareBackend softwareBackend;
    SystemBackend systemBackend;
    UtilityBackend utilityBackend;

    QObject::connect(&polkitHelper, &PolkitHelper::finished, &systemBackend,
                     [&systemBackend](bool success, const QString &output) {
        const QString title = success
            ? QCoreApplication::translate("main", "Operazione completata")
            : QCoreApplication::translate("main", "Operazione non riuscita");
        systemBackend.notify(title, output.left(500));
    });

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("PolkitHelper"), &polkitHelper);
    engine.rootContext()->setContextProperty(QStringLiteral("BootcBackend"), &bootcBackend);
    engine.rootContext()->setContextProperty(QStringLiteral("SoftwareBackend"), &softwareBackend);
    engine.rootContext()->setContextProperty(QStringLiteral("SystemBackend"), &systemBackend);
    engine.rootContext()->setContextProperty(QStringLiteral("UtilityBackend"), &utilityBackend);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, [] { QCoreApplication::exit(-1); }, Qt::QueuedConnection);

    engine.loadFromModule(QStringLiteral("org.kriscc"), QStringLiteral("Main"));

    if (qEnvironmentVariableIsSet("KRISCC_SMOKE_TEST"))
        QTimer::singleShot(900, &app, &QCoreApplication::quit);

    return app.exec();
}
