#include "SystemBackend.h"

#include <QClipboard>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QProcess>
#include <QStorageInfo>
#include <QSysInfo>
#include <QTextStream>

namespace {
QString humanGiB(quint64 bytes)
{
    return QString::number(double(bytes) / (1024.0 * 1024.0 * 1024.0), 'f', 1) + QStringLiteral(" GiB");
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
    const quint64 total = root.bytesTotal();
    const quint64 free = root.bytesAvailable();
    return tr("%1 liberi su %2").arg(humanGiB(free), humanGiB(total));
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
    out << "Qt: " << qVersion() << '\n';
    return text.trimmed();
}

void SystemBackend::copyToClipboard(const QString &text) const
{
    if (QGuiApplication::clipboard())
        QGuiApplication::clipboard()->setText(text);
}

QString SystemBackend::toolProgram(const QString &toolId) const
{
    if (toolId == QStringLiteral("systemsettings")) return QStringLiteral("/usr/bin/systemsettings");
    if (toolId == QStringLiteral("kinfocenter")) return QStringLiteral("/usr/bin/kinfocenter");
    if (toolId == QStringLiteral("partitionmanager")) return QStringLiteral("/usr/bin/partitionmanager");
    if (toolId == QStringLiteral("firewall")) return QStringLiteral("/usr/bin/firewall-config");
    if (toolId == QStringLiteral("printer")) return QStringLiteral("/usr/bin/system-config-printer");
    if (toolId == QStringLiteral("discover")) return QStringLiteral("/usr/bin/plasma-discover");
    if (toolId == QStringLiteral("virtmanager")) return QStringLiteral("/usr/bin/virt-manager");
    if (toolId == QStringLiteral("ksystemlog")) return QStringLiteral("/usr/bin/ksystemlog");
    if (toolId == QStringLiteral("konsole")) return QStringLiteral("/usr/bin/konsole");
    return {};
}

bool SystemBackend::toolAvailable(const QString &toolId) const
{
    const QString program = toolProgram(toolId);
    const QFileInfo info(program);
    return !program.isEmpty() && info.exists() && info.isExecutable();
}

bool SystemBackend::launchTool(const QString &toolId) const
{
    const QString program = toolProgram(toolId);
    if (program.isEmpty() || !toolAvailable(toolId))
        return false;
    return QProcess::startDetached(program, {});
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
