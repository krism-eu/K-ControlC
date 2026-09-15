#include "BootcBackend.h"

#include <QFile>
#include <QFileInfo>
#include <QTimer>

BootcBackend::BootcBackend(QObject *parent)
    : QObject(parent)
{
    loadPackages();
    QTimer::singleShot(0, this, &BootcBackend::refreshStatus);
}

bool BootcBackend::bootcAvailable() const
{
    const QFileInfo info(QStringLiteral("/usr/bin/bootc"));
    return info.exists() && info.isExecutable();
}

void BootcBackend::refreshStatus()
{
    if (m_busy)
        return;

    if (!bootcAvailable()) {
        m_statusText = tr("bootc non disponibile su questo sistema.");
        m_errorText.clear();
        emit statusChanged();
        return;
    }

    setBusy(true);
    m_errorText.clear();
    m_process = new QProcess(this);
    m_process->setProcessChannelMode(QProcess::MergedChannels);

    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this](int exitCode, QProcess::ExitStatus status) {
        if (!m_process)
            return;
        const QString output = QString::fromUtf8(m_process->readAllStandardOutput()).trimmed();
        const bool ok = status == QProcess::NormalExit && exitCode == 0;
        m_statusText = output.isEmpty() ? tr("Nessun output da bootc status.") : output;
        if (!ok)
            m_errorText = tr("bootc status e' terminato con codice %1.").arg(exitCode);
        m_process->deleteLater();
        m_process = nullptr;
        setBusy(false);
        emit statusChanged();
    });

    connect(m_process, &QProcess::errorOccurred, this,
            [this](QProcess::ProcessError error) {
        if (!m_process || error != QProcess::FailedToStart)
            return;
        m_errorText = tr("Impossibile avviare bootc: %1").arg(m_process->errorString());
        m_statusText.clear();
        m_process->deleteLater();
        m_process = nullptr;
        setBusy(false);
        emit statusChanged();
    });

    m_process->start(QStringLiteral("/usr/bin/bootc"),
                     {QStringLiteral("status"), QStringLiteral("--format=humanreadable")});
}

void BootcBackend::refreshPackages()
{
    loadPackages();
    emit packagesChanged();
}

void BootcBackend::setBusy(bool busy)
{
    if (m_busy == busy)
        return;
    m_busy = busy;
    emit busyChanged();
}

void BootcBackend::loadPackages()
{
    QFile file(QStringLiteral("/var/lib/raku-kris/packages.list"));
    QStringList packages;
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        while (!file.atEnd()) {
            const QString line = QString::fromUtf8(file.readLine()).trimmed();
            if (!line.isEmpty() && !line.startsWith('#'))
                packages.append(line);
        }
    }

    m_persistentPackageCount = packages.size();
    if (packages.isEmpty()) {
        m_persistentPackages = tr("nessuno");
    } else if (packages.size() <= 12) {
        m_persistentPackages = packages.join(QStringLiteral(", "));
    } else {
        m_persistentPackages = packages.mid(0, 12).join(QStringLiteral(", "))
                             + tr(" … (+%1)").arg(packages.size() - 12);
    }
}
