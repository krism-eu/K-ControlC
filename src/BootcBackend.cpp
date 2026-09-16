#include "BootcBackend.h"

#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTimer>

#include <unistd.h>

namespace {
QString jsonString(const QJsonObject &object, const QString &key)
{
    const QJsonValue value = object.value(key);
    return value.isString() ? value.toString() : QString();
}

QString firstExistingPath(const QStringList &paths)
{
    for (const QString &path : paths) {
        if (QFileInfo::exists(path))
            return path;
    }
    return paths.isEmpty() ? QString() : paths.constFirst();
}

QVariantMap deploymentMap(const QString &role, const QJsonObject &deployment)
{
    QVariantMap map;
    map.insert(QStringLiteral("role"), role);

    const QJsonObject imageStatus = deployment.value(QStringLiteral("image")).toObject();
    const QJsonObject imageReference = imageStatus.value(QStringLiteral("image")).toObject();
    const QJsonObject ostree = deployment.value(QStringLiteral("ostree")).toObject();

    QString image = jsonString(imageReference, QStringLiteral("image"));
    if (image.isEmpty())
        image = jsonString(imageReference, QStringLiteral("reference"));
    if (image.isEmpty())
        image = jsonString(imageStatus, QStringLiteral("image"));
    if (image.isEmpty() && deployment.value(QStringLiteral("image")).isString())
        image = deployment.value(QStringLiteral("image")).toString();

    QString version = jsonString(imageStatus, QStringLiteral("version"));
    if (version.isEmpty())
        version = jsonString(deployment, QStringLiteral("version"));

    QString digest = jsonString(imageStatus, QStringLiteral("imageDigest"));
    if (digest.isEmpty())
        digest = jsonString(imageReference, QStringLiteral("imageDigest"));
    if (digest.isEmpty())
        digest = jsonString(imageReference, QStringLiteral("digest"));
    if (digest.isEmpty())
        digest = jsonString(deployment, QStringLiteral("imageDigest"));

    QString checksum = jsonString(ostree, QStringLiteral("checksum"));
    if (checksum.isEmpty())
        checksum = jsonString(deployment, QStringLiteral("checksum"));

    QString timestamp = jsonString(imageStatus, QStringLiteral("timestamp"));
    if (timestamp.isEmpty())
        timestamp = jsonString(deployment, QStringLiteral("timestamp"));

    map.insert(QStringLiteral("image"), image);
    map.insert(QStringLiteral("version"), version);
    map.insert(QStringLiteral("digest"), digest);
    map.insert(QStringLiteral("checksum"), checksum);
    map.insert(QStringLiteral("pinned"), deployment.value(QStringLiteral("pinned")).toBool(false));
    map.insert(QStringLiteral("timestamp"), timestamp);
    return map;
}

void startBootcStatus(QProcess *process, const QString &format)
{
    const QStringList bootcArgs = {
        QStringLiteral("status"), QStringLiteral("--format"), format
    };

    if (::geteuid() == 0) {
        process->start(QStringLiteral("/usr/bin/bootc"), bootcArgs);
        return;
    }

    QStringList pkexecArgs = {QStringLiteral("/usr/bin/bootc")};
    pkexecArgs.append(bootcArgs);
    process->start(QStringLiteral("/usr/bin/pkexec"), pkexecArgs);
}
}

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
        m_deployments.clear();
        emit statusChanged();
        return;
    }

    setBusy(true);
    m_errorText.clear();
    m_deployments.clear();

    auto *rawProcess = new QProcess(this);
    const QPointer<QProcess> process(rawProcess);
    m_process = rawProcess;
    rawProcess->setProcessChannelMode(QProcess::SeparateChannels);

    connect(rawProcess, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this, process](int exitCode, QProcess::ExitStatus status) {
        if (!process || process != m_process)
            return;

        const QByteArray stdoutData = process->readAllStandardOutput();
        const QString stderrText = QString::fromUtf8(process->readAllStandardError()).trimmed();
        m_process = nullptr;
        process->deleteLater();

        if (status == QProcess::NormalExit && exitCode == 0) {
            parseJsonStatus(stdoutData);
            setBusy(false);
            emit statusChanged();
            return;
        }

        startHumanStatus(stderrText.isEmpty()
                             ? tr("bootc status --format json e' terminato con codice %1.").arg(exitCode)
                             : stderrText);
    });

    connect(rawProcess, &QProcess::errorOccurred, this,
            [this, process](QProcess::ProcessError error) {
        if (!process || process != m_process || error != QProcess::FailedToStart)
            return;
        const QString reason = process->errorString();
        m_process = nullptr;
        process->deleteLater();
        startHumanStatus(tr("Impossibile avviare bootc JSON: %1").arg(reason));
    });

    startBootcStatus(rawProcess, QStringLiteral("json"));
}

void BootcBackend::startHumanStatus(const QString &previousError)
{
    auto *rawProcess = new QProcess(this);
    const QPointer<QProcess> process(rawProcess);
    m_process = rawProcess;
    rawProcess->setProcessChannelMode(QProcess::MergedChannels);

    connect(rawProcess, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this, process, previousError](int exitCode, QProcess::ExitStatus status) {
        if (!process || process != m_process)
            return;
        const QString output = QString::fromUtf8(process->readAllStandardOutput()).trimmed();
        const bool ok = status == QProcess::NormalExit && exitCode == 0;
        m_process = nullptr;
        process->deleteLater();
        m_statusText = output.isEmpty() ? tr("Nessun output da bootc status.") : output;
        m_errorText = ok ? previousError
                         : tr("bootc status e' terminato con codice %1. %2").arg(exitCode).arg(previousError);
        setBusy(false);
        emit statusChanged();
    });

    connect(rawProcess, &QProcess::errorOccurred, this,
            [this, process, previousError](QProcess::ProcessError error) {
        if (!process || process != m_process || error != QProcess::FailedToStart)
            return;
        m_errorText = tr("Impossibile avviare bootc: %1. %2")
                          .arg(process->errorString(), previousError);
        m_statusText.clear();
        m_process = nullptr;
        process->deleteLater();
        setBusy(false);
        emit statusChanged();
    });

    startBootcStatus(rawProcess, QStringLiteral("humanreadable"));
}

void BootcBackend::parseJsonStatus(const QByteArray &data)
{
    QJsonParseError error;
    const QJsonDocument document = QJsonDocument::fromJson(data, &error);
    if (error.error != QJsonParseError::NoError || !document.isObject()) {
        m_statusText = QString::fromUtf8(data).trimmed();
        m_errorText = tr("Output JSON di bootc non valido: %1").arg(error.errorString());
        return;
    }

    const QJsonObject root = document.object();
    const QJsonObject status = root.value(QStringLiteral("status")).toObject();
    m_deployments.clear();

    const struct { const char *key; const char *label; } roles[] = {
        {"staged", "Staged"},
        {"booted", "Booted"},
        {"rollback", "Rollback"}
    };
    for (const auto &role : roles) {
        const QJsonObject deployment = status.value(QLatin1String(role.key)).toObject();
        if (!deployment.isEmpty())
            m_deployments.append(deploymentMap(QLatin1String(role.label), deployment));
    }

    m_statusText = QString::fromUtf8(document.toJson(QJsonDocument::Indented)).trimmed();
    m_errorText.clear();
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
    const QString statePath = firstExistingPath({
        QStringLiteral("/var/lib/krisos/packages.list"),
        QStringLiteral("/var/lib/raku-kris/packages.list")
    });
    QFile file(statePath);
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
