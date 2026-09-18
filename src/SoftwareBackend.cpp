#include "SoftwareBackend.h"

#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTimer>

#include <algorithm>

SoftwareBackend::SoftwareBackend(QObject *parent)
    : QObject(parent)
{
}

void SoftwareBackend::refreshRepositories()
{
    if (m_busy)
        return;

    const QFileInfo dnf5(QStringLiteral("/usr/bin/dnf5"));
    if (!dnf5.exists() || !dnf5.isExecutable()) {
        setError(tr("dnf5 non disponibile."));
        return;
    }

    setBusy(true);
    setError({});

    auto *process = new QProcess(this);
    const QPointer<QProcess> guard(process);
    m_process = process;
    process->setProcessChannelMode(QProcess::SeparateChannels);

    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this, guard](int exitCode, QProcess::ExitStatus status) {
        if (!guard || guard != m_process)
            return;

        const bool timedOut = guard->property("krisccTimedOut").toBool();
        const QByteArray output = guard->readAllStandardOutput();
        const QString stderrText = QString::fromUtf8(guard->readAllStandardError()).trimmed();
        m_process = nullptr;
        guard->deleteLater();
        setBusy(false);

        if (timedOut || status != QProcess::NormalExit || exitCode != 0) {
            setError(timedOut ? tr("Tempo massimo superato durante la lettura dei repository DNF5.")
                              : (stderrText.isEmpty() ? tr("Impossibile leggere i repository DNF5.") : stderrText));
            return;
        }

        QJsonParseError parseError;
        const QJsonDocument document = QJsonDocument::fromJson(output, &parseError);
        if (parseError.error != QJsonParseError::NoError || !document.isArray()) {
            setError(tr("Output repository DNF5 non valido: %1").arg(parseError.errorString()));
            return;
        }

        QVariantList repos;
        for (const QJsonValue &value : document.array()) {
            const QJsonObject object = value.toObject();
            const QString id = object.value(QStringLiteral("id")).toString();
            if (id.isEmpty())
                continue;
            QVariantMap repo;
            repo.insert(QStringLiteral("id"), id);
            repo.insert(QStringLiteral("name"), object.value(QStringLiteral("name")).toString(id));
            repo.insert(QStringLiteral("enabled"), object.value(QStringLiteral("is_enabled")).toBool());
            repos.append(repo);
        }

        std::sort(repos.begin(), repos.end(), [](const QVariant &left, const QVariant &right) {
            const QVariantMap a = left.toMap();
            const QVariantMap b = right.toMap();
            return a.value(QStringLiteral("id")).toString().localeAwareCompare(
                       b.value(QStringLiteral("id")).toString()) < 0;
        });

        m_repositories = repos;
        emit repositoriesChanged();
    });

    connect(process, &QProcess::errorOccurred, this,
            [this, guard](QProcess::ProcessError error) {
        if (!guard || guard != m_process || error != QProcess::FailedToStart)
            return;
        const QString reason = guard->errorString();
        m_process = nullptr;
        guard->deleteLater();
        setBusy(false);
        setError(tr("Impossibile avviare dnf5: %1").arg(reason));
    });

    process->start(QStringLiteral("/usr/bin/dnf5"),
                   {QStringLiteral("repo"), QStringLiteral("list"),
                    QStringLiteral("--all"), QStringLiteral("--json")});
    QTimer::singleShot(60 * 1000, process, [this, guard] {
        if (!guard || guard != m_process || guard->state() == QProcess::NotRunning)
            return;
        guard->setProperty("krisccTimedOut", true);
        guard->terminate();
        QTimer::singleShot(2000, guard, [guard] {
            if (guard && guard->state() != QProcess::NotRunning)
                guard->kill();
        });
    });
}

void SoftwareBackend::setBusy(bool busy)
{
    if (m_busy == busy)
        return;
    m_busy = busy;
    emit busyChanged();
}

void SoftwareBackend::setError(const QString &error)
{
    if (m_errorText == error)
        return;
    m_errorText = error;
    emit errorTextChanged();
}
