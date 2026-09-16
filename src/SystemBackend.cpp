#include "SystemBackend.h"

#include <QClipboard>
#include <QDateTime>
#include <QDBusInterface>
#include <QDBusObjectPath>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusReply>
#include <QDBusVariant>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QHash>
#include <QProcess>
#include <QSet>
#include <QStandardPaths>
#include <QStorageInfo>
#include <QSysInfo>
#include <QTextStream>
#include <QTimeZone>
#include <QUrl>

namespace {
QString humanGiB(quint64 bytes)
{
    return QString::number(double(bytes) / (1024.0 * 1024.0 * 1024.0), 'f', 1)
         + QStringLiteral(" GiB");
}

const QSet<QString> &allowedServices()
{
    static const QSet<QString> services = {
        QStringLiteral("NetworkManager.service"),
        QStringLiteral("cups.service"),
        QStringLiteral("bluetooth.service")
    };
    return services;
}
}

SystemBackend::SystemBackend(QObject *parent)
    : QObject(parent)
{
}

QString SystemBackend::osName() const
{
    return readOsName();
}

QString SystemBackend::kernelVersion() const
{
    return QSysInfo::kernelType() + QStringLiteral(" ") + QSysInfo::kernelVersion();
}

QString SystemBackend::architecture() const
{
    return QSysInfo::currentCpuArchitecture();
}

QString SystemBackend::hostName() const
{
    return QSysInfo::machineHostName();
}

QString SystemBackend::memorySummary() const
{
    QFile file(QStringLiteral("/proc/meminfo"));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return tr("Non disponibile");

    while (!file.atEnd()) {
        const QByteArray line = file.readLine();
        if (!line.startsWith("MemTotal:"))
            continue;
        const QList<QByteArray> parts = line.simplified().split(' ');
        if (parts.size() >= 2) {
            bool ok = false;
            const quint64 kib = parts.at(1).toULongLong(&ok);
            if (ok)
                return humanGiB(kib * 1024ULL);
        }
    }
    return tr("Non disponibile");
}

QString SystemBackend::storageSummary() const
{
    const QStorageInfo root(QDir::rootPath());
    if (!root.isValid() || !root.isReady())
        return tr("Non disponibile");
    return tr("%1 liberi su %2").arg(humanGiB(root.bytesAvailable()), humanGiB(root.bytesTotal()));
}

QString SystemBackend::desktopSession() const
{
    const QString desktop = qEnvironmentVariable("XDG_CURRENT_DESKTOP", tr("Desktop sconosciuto"));
    const QString session = qEnvironmentVariable("XDG_SESSION_TYPE", QStringLiteral("?"));
    return desktop + QStringLiteral(" · ") + session;
}

QString SystemBackend::quickSystemInfo() const
{
    QString text;
    QTextStream out(&text);
    out << "K-ControlC Quick System Info\n";
    out << "OS: " << osName() << '\n';
    out << "Host: " << hostName() << '\n';
    out << "Kernel: " << kernelVersion() << '\n';
    out << "Arch: " << architecture() << '\n';
    out << "RAM: " << memorySummary() << '\n';
    out << "Storage /: " << storageSummary() << '\n';
    out << "Desktop: " << desktopSession() << '\n';
    out << "Timezone: " << QString::fromUtf8(QTimeZone::systemTimeZoneId()) << '\n';
    out << "Qt: " << qVersion() << '\n';
    return text.trimmed();
}

void SystemBackend::copyToClipboard(const QString &text) const
{
    if (QGuiApplication::clipboard())
        QGuiApplication::clipboard()->setText(text);
}

QString SystemBackend::resolveExecutable(const QString &program) const
{
    if (program.isEmpty())
        return {};
    if (program.startsWith(QLatin1Char('/'))) {
        const QFileInfo info(program);
        return info.exists() && info.isExecutable() ? info.absoluteFilePath() : QString();
    }
    return QStandardPaths::findExecutable(program);
}

QString SystemBackend::toolProgram(const QString &toolId) const
{
    static const QHash<QString, QString> names = {
        {QStringLiteral("systemsettings"), QStringLiteral("systemsettings")},
        {QStringLiteral("kinfocenter"), QStringLiteral("kinfocenter")},
        {QStringLiteral("partitionmanager"), QStringLiteral("partitionmanager")},
        {QStringLiteral("discover"), QStringLiteral("plasma-discover")},
        {QStringLiteral("ksystemlog"), QStringLiteral("ksystemlog")},
        {QStringLiteral("systemmonitor"), QStringLiteral("plasma-systemmonitor")},
        {QStringLiteral("konsole"), QStringLiteral("konsole")}
    };
    return resolveExecutable(names.value(toolId));
}

bool SystemBackend::toolAvailable(const QString &toolId) const
{
    return !toolProgram(toolId).isEmpty();
}

bool SystemBackend::launchTool(const QString &toolId) const
{
    const QString program = toolProgram(toolId);
    if (program.isEmpty())
        return false;
    const QFileInfo info(program);
    return info.exists() && info.isExecutable() && QProcess::startDetached(program, {});
}

bool SystemBackend::launchFlatpakManager() const
{
    const QString discover = resolveExecutable(QStringLiteral("plasma-discover"));
    return !discover.isEmpty() && QProcess::startDetached(discover, {});
}

bool SystemBackend::launchQuickAction(const QString &actionId) const
{
    const QString konsole = resolveExecutable(QStringLiteral("konsole"));
    if (konsole.isEmpty())
        return false;

    if (actionId == QStringLiteral("flatpak-unused")) {
        const QString flatpak = resolveExecutable(QStringLiteral("flatpak"));
        return !flatpak.isEmpty()
            && QProcess::startDetached(konsole, {QStringLiteral("-e"), flatpak,
                                                 QStringLiteral("uninstall"), QStringLiteral("--unused")});
    }
    if (actionId == QStringLiteral("journal-errors")) {
        const QString journalctl = resolveExecutable(QStringLiteral("journalctl"));
        return !journalctl.isEmpty()
            && QProcess::startDetached(konsole, {QStringLiteral("-e"), journalctl,
                                                 QStringLiteral("-b"), QStringLiteral("-p"), QStringLiteral("warning")});
    }
    if (actionId == QStringLiteral("unneeded")) {
        const QString dnf5 = resolveExecutable(QStringLiteral("dnf5"));
        return !dnf5.isEmpty()
            && QProcess::startDetached(konsole, {QStringLiteral("-e"), dnf5,
                                                 QStringLiteral("repoquery"), QStringLiteral("--installed"),
                                                 QStringLiteral("--unneeded")});
    }
    if (actionId == QStringLiteral("firmware")) {
        const QString fwupdmgr = resolveExecutable(QStringLiteral("fwupdmgr"));
        return !fwupdmgr.isEmpty()
            && QProcess::startDetached(konsole, {QStringLiteral("-e"), fwupdmgr,
                                                 QStringLiteral("get-updates")});
    }
    if (actionId == QStringLiteral("disks")) {
        const QString lsblk = resolveExecutable(QStringLiteral("lsblk"));
        return !lsblk.isEmpty()
            && QProcess::startDetached(konsole, {QStringLiteral("-e"), lsblk,
                                                 QStringLiteral("-o"),
                                                 QStringLiteral("NAME,SIZE,FSTYPE,FSUSE%,MOUNTPOINTS,MODEL")});
    }
    return false;
}

bool SystemBackend::programAvailable(const QString &program) const
{
    return !resolveExecutable(program).isEmpty();
}

QString SystemBackend::serviceState(const QString &service) const
{
    if (!allowedServices().contains(service))
        return tr("non consentito");

    QDBusInterface manager(QStringLiteral("org.freedesktop.systemd1"),
                           QStringLiteral("/org/freedesktop/systemd1"),
                           QStringLiteral("org.freedesktop.systemd1.Manager"),
                           QDBusConnection::systemBus());
    const QDBusReply<QDBusObjectPath> unitReply = manager.call(QStringLiteral("GetUnit"), service);
    if (!unitReply.isValid())
        return tr("non disponibile");

    QDBusInterface properties(QStringLiteral("org.freedesktop.systemd1"), unitReply.value().path(),
                              QStringLiteral("org.freedesktop.DBus.Properties"),
                              QDBusConnection::systemBus());
    const QDBusReply<QDBusVariant> stateReply = properties.call(
        QStringLiteral("Get"), QStringLiteral("org.freedesktop.systemd1.Unit"), QStringLiteral("ActiveState"));
    return stateReply.isValid() ? stateReply.value().variant().toString() : tr("sconosciuto");
}

bool SystemBackend::restartService(const QString &service)
{
    if (!allowedServices().contains(service))
        return false;

    QDBusInterface manager(QStringLiteral("org.freedesktop.systemd1"),
                           QStringLiteral("/org/freedesktop/systemd1"),
                           QStringLiteral("org.freedesktop.systemd1.Manager"),
                           QDBusConnection::systemBus());
    if (!manager.isValid())
        return false;

    auto *watcher = new QDBusPendingCallWatcher(
        manager.asyncCall(QStringLiteral("RestartUnit"), service, QStringLiteral("replace")), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this,
            [this, service](QDBusPendingCallWatcher *call) {
        const QDBusPendingReply<QDBusObjectPath> reply(*call);
        notify(reply.isError() ? tr("Riavvio servizio non riuscito") : tr("Servizio riavviato"),
               reply.isError() ? reply.error().message() : service);
        call->deleteLater();
    });
    return true;
}

bool SystemBackend::sessionAction(const QString &action)
{
    static const QHash<QString, QString> methods = {
        {QStringLiteral("poweroff"), QStringLiteral("PowerOff")},
        {QStringLiteral("reboot"), QStringLiteral("Reboot")},
        {QStringLiteral("suspend"), QStringLiteral("Suspend")}
    };
    if (!methods.contains(action))
        return false;

    QDBusInterface login(QStringLiteral("org.freedesktop.login1"),
                         QStringLiteral("/org/freedesktop/login1"),
                         QStringLiteral("org.freedesktop.login1.Manager"),
                         QDBusConnection::systemBus());
    if (!login.isValid())
        return false;

    auto *watcher = new QDBusPendingCallWatcher(login.asyncCall(methods.value(action), true), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this,
            [this](QDBusPendingCallWatcher *call) {
        const QDBusPendingReply<> reply(*call);
        if (reply.isError())
            notify(tr("Azione di sessione non riuscita"), reply.error().message());
        call->deleteLater();
    });
    return true;
}

void SystemBackend::notify(const QString &summary, const QString &body) const
{
    QDBusInterface notifications(QStringLiteral("org.freedesktop.Notifications"),
                                 QStringLiteral("/org/freedesktop/Notifications"),
                                 QStringLiteral("org.freedesktop.Notifications"),
                                 QDBusConnection::sessionBus());
    if (!notifications.isValid())
        return;
    notifications.asyncCall(QStringLiteral("Notify"), QStringLiteral("K-ControlC"), 0u,
                            QStringLiteral("k-controlc"), summary, body,
                            QStringList(), QVariantMap(), 5000);
}

bool SystemBackend::createSnapshot(const QString &kind)
{
    if (m_backupBusy)
        return false;

    const QString tar = resolveExecutable(QStringLiteral("tar"));
    if (tar.isEmpty()) {
        setBackupResult(tr("tar non disponibile."));
        return false;
    }

    const QString home = QDir::homePath();
    QDir backupDir(home + QStringLiteral("/K-ControlC Backups"));
    if (!backupDir.exists() && !backupDir.mkpath(QStringLiteral("."))) {
        setBackupResult(tr("Impossibile creare la cartella dei backup."));
        return false;
    }

    const QStorageInfo backupStorage(backupDir.absolutePath());
    if (backupStorage.isValid() && backupStorage.isReady()) {
        const quint64 oneGiB = 1024ULL * 1024ULL * 1024ULL;
        const quint64 minimumFree = kind == QStringLiteral("home") ? 5ULL * oneGiB : oneGiB;
        if (backupStorage.bytesAvailable() < minimumFree) {
            setBackupResult(tr("Spazio libero insufficiente per lo snapshot: disponibili %1, richiesti almeno %2.")
                                .arg(humanGiB(backupStorage.bytesAvailable()), humanGiB(minimumFree)));
            return false;
        }
    }

    const QString stamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd-HHmmss"));
    const QString label = kind == QStringLiteral("home") ? QStringLiteral("home") : QStringLiteral("config");
    const QString output = backupDir.filePath(QStringLiteral("%1-%2.tar.gz").arg(label, stamp));

    QStringList args = {QStringLiteral("-czf"), output};
    if (kind == QStringLiteral("home")) {
        args << QStringLiteral("--exclude=./.cache")
             << QStringLiteral("--exclude=./.local/share/Trash")
             << QStringLiteral("--exclude=./K-ControlC Backups")
             << QStringLiteral("-C") << home << QStringLiteral(".");
    } else if (kind == QStringLiteral("config")) {
        QStringList entries;
        const QStringList candidates = {
            QStringLiteral(".config"),
            QStringLiteral(".local/share/applications"),
            QStringLiteral(".local/share/konsole"),
            QStringLiteral(".local/share/kxmlgui5"),
            QStringLiteral(".local/share/plasma"),
            QStringLiteral(".local/share/kwin")
        };
        for (const QString &candidate : candidates) {
            if (QFileInfo::exists(home + QLatin1Char('/') + candidate))
                entries << candidate;
        }
        if (entries.isEmpty()) {
            setBackupResult(tr("Nessuna cartella di configurazione trovata."));
            return false;
        }
        args << QStringLiteral("-C") << home;
        args << entries;
    } else {
        setBackupResult(tr("Tipo di snapshot non consentito."));
        return false;
    }

    auto *process = new QProcess(this);
    m_backupProcess = process;
    process->setProcessChannelMode(QProcess::MergedChannels);
    setBackupBusy(true);
    setBackupResult(tr("Creazione snapshot in corso…"), output);

    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this, output](int exitCode, QProcess::ExitStatus status) {
        if (!m_backupProcess)
            return;
        const QString details = QString::fromUtf8(m_backupProcess->readAllStandardOutput()).trimmed();
        const bool ok = status == QProcess::NormalExit && exitCode == 0;
        m_backupProcess->deleteLater();
        m_backupProcess = nullptr;
        setBackupBusy(false);
        if (ok) {
            setBackupResult(tr("Snapshot creato correttamente."), output);
            notify(tr("Backup completato"), output);
        } else {
            QFile::remove(output);
            setBackupResult(details.isEmpty() ? tr("Snapshot non riuscito (codice %1).").arg(exitCode) : details);
        }
    });
    connect(process, &QProcess::errorOccurred, this,
            [this, output](QProcess::ProcessError error) {
        if (!m_backupProcess || error != QProcess::FailedToStart)
            return;
        const QString message = m_backupProcess->errorString();
        m_backupProcess->deleteLater();
        m_backupProcess = nullptr;
        QFile::remove(output);
        setBackupBusy(false);
        setBackupResult(tr("Impossibile avviare il backup: %1").arg(message));
    });

    process->start(tar, args);
    return true;
}

bool SystemBackend::openBackupFolder() const
{
    const QString path = QDir::homePath() + QStringLiteral("/K-ControlC Backups");
    QDir().mkpath(path);
    return QDesktopServices::openUrl(QUrl::fromLocalFile(path));
}

void SystemBackend::setBackupBusy(bool busy)
{
    if (m_backupBusy == busy)
        return;
    m_backupBusy = busy;
    emit backupBusyChanged();
}

void SystemBackend::setBackupResult(const QString &status, const QString &path)
{
    m_backupStatus = status;
    m_backupPath = path;
    emit backupStatusChanged();
}

QString SystemBackend::readOsName() const
{
    QFile file(QStringLiteral("/etc/os-release"));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return QSysInfo::prettyProductName();

    while (!file.atEnd()) {
        QString line = QString::fromUtf8(file.readLine()).trimmed();
        if (!line.startsWith(QStringLiteral("PRETTY_NAME=")))
            continue;
        QString value = line.mid(QStringLiteral("PRETTY_NAME=").size());
        if (value.size() >= 2 && value.startsWith('"') && value.endsWith('"'))
            value = value.mid(1, value.size() - 2);
        return value;
    }
    return QSysInfo::prettyProductName();
}
