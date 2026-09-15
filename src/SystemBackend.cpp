#include "SystemBackend.h"

#include <QClipboard>
#include <QDBusInterface>
#include <QDBusPendingCallWatcher>
#include <QDBusReply>
#include <QDBusVariant>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QProcess>
#include <QRegularExpression>
#include <QSettings>
#include <QStandardPaths>
#include <QStorageInfo>
#include <QSysInfo>
#include <QTextStream>
#include <QTimeZone>
#include <QUrl>

#include <algorithm>

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
    scanDesktopEntries();
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

QString SystemBackend::timeZone() const
{
    return QString::fromUtf8(QTimeZone::systemTimeZoneId());
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
    out << "Timezone: " << timeZone() << '\n';
    out << "Network: " << networkState() << '\n';
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
        {QStringLiteral("firewall"), QStringLiteral("firewall-config")},
        {QStringLiteral("printer"), QStringLiteral("system-config-printer")},
        {QStringLiteral("discover"), QStringLiteral("plasma-discover")},
        {QStringLiteral("virtmanager"), QStringLiteral("virt-manager")},
        {QStringLiteral("ksystemlog"), QStringLiteral("ksystemlog")},
        {QStringLiteral("konsole"), QStringLiteral("konsole")}
    };
    return resolveExecutable(names.value(toolId));
}

bool SystemBackend::toolAvailable(const QString &toolId) const
{
    if (m_desktopTools.contains(toolId))
        return true;
    return !toolProgram(toolId).isEmpty();
}

bool SystemBackend::launchTool(const QString &toolId) const
{
    const auto desktopIt = m_desktopTools.constFind(toolId);
    if (desktopIt != m_desktopTools.cend())
        return launchDesktopEntry(desktopIt.value());

    // Resolve once. Do not call toolAvailable(), which would repeat lookup.
    const QString program = toolProgram(toolId);
    if (program.isEmpty())
        return false;
    const QFileInfo info(program);
    if (!info.exists() || !info.isExecutable())
        return false;
    return QProcess::startDetached(program, {});
}

bool SystemBackend::launchKcm(const QString &kcmId) const
{
    static const QSet<QString> allowed = {
        QStringLiteral("kcm_users"),
        QStringLiteral("kcm_clock"),
        QStringLiteral("kcm_networkmanagement"),
        QStringLiteral("kcm_bluetooth"),
        QStringLiteral("kcm_printer_manager"),
        QStringLiteral("kcm_flatpak")
    };
    if (!allowed.contains(kcmId))
        return false;

    const QString kcmshell = resolveExecutable(QStringLiteral("kcmshell6"));
    return !kcmshell.isEmpty() && QProcess::startDetached(kcmshell, {kcmId});
}

bool SystemBackend::launchFlatpakManager() const
{
    const QString kcmshell = resolveExecutable(QStringLiteral("kcmshell6"));
    if (!kcmshell.isEmpty()) {
        QProcess probe;
        probe.start(kcmshell, {QStringLiteral("--list")});
        if (probe.waitForFinished(1500)
            && QString::fromUtf8(probe.readAllStandardOutput()).contains(QStringLiteral("kcm_flatpak"))) {
            return QProcess::startDetached(kcmshell, {QStringLiteral("kcm_flatpak")});
        }
    }

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
    if (actionId == QStringLiteral("journal")) {
        const QString journalctl = resolveExecutable(QStringLiteral("journalctl"));
        return !journalctl.isEmpty()
            && QProcess::startDetached(konsole, {QStringLiteral("-e"), journalctl,
                                                 QStringLiteral("-b"), QStringLiteral("-p"), QStringLiteral("warning")});
    }
    if (actionId == QStringLiteral("firmware")) {
        const QString fwupdmgr = resolveExecutable(QStringLiteral("fwupdmgr"));
        return !fwupdmgr.isEmpty()
            && QProcess::startDetached(konsole, {QStringLiteral("-e"), fwupdmgr,
                                                 QStringLiteral("get-updates")});
    }
    return false;
}

bool SystemBackend::programAvailable(const QString &program) const
{
    return !resolveExecutable(program).isEmpty();
}

QString SystemBackend::serviceState(const QString &service) const
{
    if (!allowedServices().contains(service) && service != QStringLiteral("firewalld.service"))
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
        if (call->isError())
            notify(tr("Riavvio servizio non riuscito"), call->error().message());
        else
            notify(tr("Servizio riavviato"), service);
        call->deleteLater();
    });
    return true;
}

QString SystemBackend::networkState() const
{
    QDBusInterface nm(QStringLiteral("org.freedesktop.NetworkManager"),
                      QStringLiteral("/org/freedesktop/NetworkManager"),
                      QStringLiteral("org.freedesktop.NetworkManager"),
                      QDBusConnection::systemBus());
    if (!nm.isValid())
        return tr("NetworkManager non disponibile");

    switch (nm.property("State").toUInt()) {
    case 70: return tr("connesso");
    case 60: return tr("connettività sito");
    case 50: return tr("connettività locale");
    case 40: return tr("connessione in corso");
    case 30: return tr("disconnesso");
    case 20: return tr("disconnessione in corso");
    case 10: return tr("sospeso");
    default: return tr("stato sconosciuto");
    }
}

bool SystemBackend::ntpEnabled() const
{
    QDBusInterface timedate(QStringLiteral("org.freedesktop.timedate1"),
                            QStringLiteral("/org/freedesktop/timedate1"),
                            QStringLiteral("org.freedesktop.timedate1"),
                            QDBusConnection::systemBus());
    return timedate.isValid() && timedate.property("NTP").toBool();
}

bool SystemBackend::setNtpEnabled(bool enabled)
{
    QDBusInterface timedate(QStringLiteral("org.freedesktop.timedate1"),
                            QStringLiteral("/org/freedesktop/timedate1"),
                            QStringLiteral("org.freedesktop.timedate1"),
                            QDBusConnection::systemBus());
    if (!timedate.isValid())
        return false;

    auto *watcher = new QDBusPendingCallWatcher(
        timedate.asyncCall(QStringLiteral("SetNTP"), enabled, true), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this,
            [this, enabled](QDBusPendingCallWatcher *call) {
        notify(call->isError() ? tr("Impostazione NTP non riuscita") : tr("NTP aggiornato"),
               call->isError() ? call->error().message()
                               : (enabled ? tr("Sincronizzazione automatica attivata")
                                          : tr("Sincronizzazione automatica disattivata")));
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
        if (call->isError())
            notify(tr("Azione di sessione non riuscita"), call->error().message());
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

QStringList SystemBackend::splitDesktopList(const QString &value)
{
    return value.split(QLatin1Char(';'), Qt::SkipEmptyParts);
}

bool SystemBackend::desktopEntryVisible(const QString &path) const
{
    QSettings entry(path, QSettings::IniFormat);
    entry.beginGroup(QStringLiteral("Desktop Entry"));
    if (entry.value(QStringLiteral("Type")).toString() != QStringLiteral("Application")
        || entry.value(QStringLiteral("Hidden"), false).toBool()
        || entry.value(QStringLiteral("NoDisplay"), false).toBool()) {
        return false;
    }

    const QStringList categories = splitDesktopList(entry.value(QStringLiteral("Categories")).toString());
    if (!categories.contains(QStringLiteral("System")) && !categories.contains(QStringLiteral("Settings")))
        return false;

    const QString currentDesktop = qEnvironmentVariable("XDG_CURRENT_DESKTOP");
    const QStringList desktops = currentDesktop.split(QLatin1Char(':'), Qt::SkipEmptyParts);
    const QStringList onlyShow = splitDesktopList(entry.value(QStringLiteral("OnlyShowIn")).toString());
    const QStringList notShow = splitDesktopList(entry.value(QStringLiteral("NotShowIn")).toString());
    if (!onlyShow.isEmpty()) {
        bool matched = false;
        for (const QString &desktop : desktops)
            matched = matched || onlyShow.contains(desktop);
        if (!matched)
            return false;
    }
    for (const QString &desktop : desktops) {
        if (notShow.contains(desktop))
            return false;
    }

    const QString tryExec = entry.value(QStringLiteral("TryExec")).toString();
    return tryExec.isEmpty() || !resolveExecutable(tryExec).isEmpty();
}

void SystemBackend::scanDesktopEntries()
{
    QStringList directories = {QStringLiteral("/usr/share/applications")};
    const QString userApplications = QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation);
    if (!userApplications.isEmpty())
        directories << userApplications;

    for (const QString &directory : directories) {
        QDir dir(directory);
        const QFileInfoList files = dir.entryInfoList({QStringLiteral("*.desktop")}, QDir::Files | QDir::Readable);
        for (const QFileInfo &file : files) {
            if (!desktopEntryVisible(file.absoluteFilePath()))
                continue;

            QSettings entry(file.absoluteFilePath(), QSettings::IniFormat);
            entry.beginGroup(QStringLiteral("Desktop Entry"));
            const QString exec = entry.value(QStringLiteral("Exec")).toString().trimmed();
            const QString title = entry.value(QStringLiteral("Name")).toString().trimmed();
            if (exec.isEmpty() || title.isEmpty())
                continue;

            const QStringList categories = splitDesktopList(entry.value(QStringLiteral("Categories")).toString());
            QString category = tr("Sistema");
            if (categories.contains(QStringLiteral("Network"))) category = tr("Rete");
            else if (categories.contains(QStringLiteral("Security"))) category = tr("Sicurezza");
            else if (categories.contains(QStringLiteral("HardwareSettings"))) category = tr("Hardware");

            DesktopTool tool;
            tool.id = QStringLiteral("desktop:") + file.fileName();
            tool.title = title;
            tool.description = entry.value(QStringLiteral("Comment")).toString().trimmed();
            tool.category = category;
            tool.icon = entry.value(QStringLiteral("Icon")).toString();
            tool.exec = exec;
            m_desktopTools.insert(tool.id, tool); // user entries override system entries by id
        }
    }

    QList<DesktopTool> sorted = m_desktopTools.values();
    std::sort(sorted.begin(), sorted.end(), [](const DesktopTool &a, const DesktopTool &b) {
        return a.title.localeAwareCompare(b.title) < 0;
    });

    for (const DesktopTool &tool : sorted) {
        QVariantMap map;
        map.insert(QStringLiteral("toolId"), tool.id);
        map.insert(QStringLiteral("title"), tool.title);
        map.insert(QStringLiteral("description"), tool.description);
        map.insert(QStringLiteral("category"), tool.category);
        map.insert(QStringLiteral("icon"), tool.icon);
        m_toolList.append(map);
    }
}

bool SystemBackend::launchDesktopEntry(const DesktopTool &tool) const
{
    QStringList command = QProcess::splitCommand(tool.exec);
    if (command.isEmpty())
        return false;

    // Remove freedesktop field codes. No shell is involved.
    static const QRegularExpression fieldCode(QStringLiteral("%[fFuUdDnNickvm]") );
    for (QString &token : command) {
        token.replace(QStringLiteral("%%"), QStringLiteral("%"));
        token.remove(fieldCode);
    }
    command.removeAll(QString());
    if (command.isEmpty())
        return false;

    const QString program = resolveExecutable(command.takeFirst());
    return !program.isEmpty() && QProcess::startDetached(program, command);
}
