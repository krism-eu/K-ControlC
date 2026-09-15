#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTimer>
#include <QtQml/qqml.h>

#include "BootcBackend.h"
#include "PackageSearch.h"
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

    // Runtime registration avoids the qmltyperegistrar/QAbstractListModel issue
    // previously found by the Fedora CI build.
    qmlRegisterType<PackageSearch>("raku.cc", 1, 0, "PackageSearch");

    PolkitHelper polkitHelper;
    BootcBackend bootcBackend;
    SystemBackend systemBackend;

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
    engine.rootContext()->setContextProperty(QStringLiteral("SystemBackend"), &systemBackend);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, [] { QCoreApplication::exit(-1); }, Qt::QueuedConnection);

    engine.loadFromModule(QStringLiteral("raku.cc"), QStringLiteral("Main"));

    if (qEnvironmentVariableIsSet("KCONTROLC_SMOKE_TEST"))
        QTimer::singleShot(900, &app, &QCoreApplication::quit);

    return app.exec();
}
