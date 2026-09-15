#include "PackageSearch.h"

#include <QFile>
#include <QFileInfo>
#include <QTimer>
#include <QTextStream>

PackageSearch::PackageSearch(QObject *parent)
    : QAbstractListModel(parent)
{
    QFile file(QStringLiteral("/usr/share/raku-kris/owned-packages.txt"));
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);
        while (!in.atEnd()) {
            const QString name = in.readLine().trimmed();
            if (!name.isEmpty())
                m_owned.insert(name);
        }
    }
}

int PackageSearch::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_results.size();
}

QVariant PackageSearch::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_results.size())
        return {};

    const Entry &entry = m_results.at(index.row());
    switch (role) {
    case NameRole:      return entry.name;
    case SummaryRole:   return entry.summary;
    case InstalledRole: return entry.installed;
    case OwnedRole:     return entry.owned;
    default:            return {};
    }
}

QHash<int, QByteArray> PackageSearch::roleNames() const
{
    return {
        {NameRole, "name"},
        {SummaryRole, "summary"},
        {InstalledRole, "installed"},
        {OwnedRole, "owned"},
    };
}

void PackageSearch::search(const QString &term)
{
    const QString sanitized = sanitizeTerm(term);

    // Increment first: callbacks from any older process become stale immediately.
    ++m_generation;
    stopActiveProcess();

    if (sanitized.size() < 2) {
        clearResults();
        setSearching(false);
        emit searchFinished();
        return;
    }

    setSearching(true);
    if (installedCacheCurrent())
        startRepoQuery(sanitized);
    else
        startInstalledQuery(sanitized);
}

void PackageSearch::startInstalledQuery(const QString &term)
{
    const quint64 generation = m_generation;
    auto *rawProcess = new QProcess(this);
    const QPointer<QProcess> process(rawProcess);
    m_process = rawProcess;

    connect(rawProcess, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this, process, term, generation](int exitCode, QProcess::ExitStatus status) {
        if (!process)
            return;
        if (process != m_process || generation != m_generation) {
            process->deleteLater();
            return;
        }

        m_installed.clear();
        if (status == QProcess::NormalExit && exitCode == 0) {
            const auto lines = process->readAllStandardOutput().split('\n');
            for (const QByteArray &line : lines) {
                const QString name = QString::fromUtf8(line).trimmed();
                if (!name.isEmpty())
                    m_installed.insert(name);
            }

            m_installedCacheDbPath = rpmDatabasePath();
            const QFileInfo dbInfo(m_installedCacheDbPath);
            m_installedCacheMtime = dbInfo.exists() ? dbInfo.lastModified() : QDateTime();
            m_installedCacheValid = true;
        } else {
            m_installedCacheValid = false;
        }

        m_process = nullptr;
        process->deleteLater();
        startRepoQuery(term);
    });

    connect(rawProcess, &QProcess::errorOccurred, this,
            [this, process, term, generation](QProcess::ProcessError error) {
        if (!process || process != m_process || generation != m_generation
            || error != QProcess::FailedToStart)
            return;

        m_installed.clear();
        m_installedCacheValid = false;
        m_process = nullptr;
        process->deleteLater();
        emit searchError(tr("Impossibile avviare rpm per leggere i pacchetti installati."));
        startRepoQuery(term);
    });

    rawProcess->start(QStringLiteral("/usr/bin/rpm"),
                      {QStringLiteral("-qa"), QStringLiteral("--qf"), QStringLiteral("%{NAME}\\n")});
}

void PackageSearch::startRepoQuery(const QString &term)
{
    const quint64 generation = m_generation;
    auto *rawProcess = new QProcess(this);
    const QPointer<QProcess> process(rawProcess);
    m_process = rawProcess;

    connect(rawProcess, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this, process, generation](int exitCode, QProcess::ExitStatus status) {
        if (!process)
            return;
        if (process != m_process || generation != m_generation) {
            process->deleteLater();
            return;
        }

        const QByteArray stdoutData = process->readAllStandardOutput();
        const QString stderrText = QString::fromUtf8(process->readAllStandardError()).trimmed();
        m_process = nullptr;
        process->deleteLater();

        if (status != QProcess::NormalExit || exitCode != 0) {
            clearResults();
            setSearching(false);
            emit searchError(stderrText.isEmpty()
                                 ? tr("La ricerca dnf5 non e' riuscita.")
                                 : stderrText);
            emit searchFinished();
            return;
        }

        beginResetModel();
        m_results.clear();
        QSet<QString> seen;
        const auto lines = QString::fromUtf8(stdoutData).split('\n', Qt::SkipEmptyParts);
        for (const QString &line : lines) {
            const int tab = line.indexOf('\t');
            const QString name = (tab < 0 ? line : line.left(tab)).trimmed();
            if (name.isEmpty() || seen.contains(name))
                continue;

            seen.insert(name);
            Entry entry;
            entry.name = name;
            entry.summary = (tab < 0 ? QString() : line.mid(tab + 1)).simplified().left(512);
            entry.installed = m_installed.contains(name);
            entry.owned = m_owned.contains(name);
            m_results.append(entry);

            if (m_results.size() >= 200)
                break;
        }
        endResetModel();

        setSearching(false);
        emit searchFinished();
    });

    connect(rawProcess, &QProcess::errorOccurred, this,
            [this, process, generation](QProcess::ProcessError error) {
        if (!process || process != m_process || generation != m_generation
            || error != QProcess::FailedToStart)
            return;
        m_process = nullptr;
        process->deleteLater();
        clearResults();
        setSearching(false);
        emit searchError(tr("Impossibile avviare dnf5."));
        emit searchFinished();
    });

    // repoquery has no --search option. A positional package-spec/glob is the
    // supported form. The glob is built only from our sanitized term.
    const QString packageSpec = QStringLiteral("*") + term + QStringLiteral("*");
    rawProcess->start(QStringLiteral("/usr/bin/dnf5"),
                      {QStringLiteral("repoquery"),
                       QStringLiteral("--available"),
                       QStringLiteral("--queryformat"),
                       QStringLiteral("%{name}\t%{summary}\\n"),
                       packageSpec});
}

void PackageSearch::clearResults()
{
    if (m_results.isEmpty())
        return;
    beginResetModel();
    m_results.clear();
    endResetModel();
}

void PackageSearch::setSearching(bool searching)
{
    if (m_searching == searching)
        return;
    m_searching = searching;
    emit searchingChanged();
}

void PackageSearch::stopActiveProcess()
{
    if (!m_process)
        return;

    const QPointer<QProcess> process = m_process;
    m_process = nullptr;
    disconnect(process, nullptr, this, nullptr);

    if (!process)
        return;
    if (process->state() == QProcess::NotRunning) {
        process->deleteLater();
        return;
    }

    // Give dnf5/rpm a chance to release their resources cleanly. Never block
    // the GUI thread while waiting for cancellation.
    process->terminate();
    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished),
            process, &QObject::deleteLater);
    QTimer::singleShot(3000, process, [process]() {
        if (process && process->state() != QProcess::NotRunning)
            process->kill();
    });
}

bool PackageSearch::installedCacheCurrent() const
{
    if (!m_installedCacheValid)
        return false;

    const QString dbPath = rpmDatabasePath();
    if (dbPath.isEmpty() || dbPath != m_installedCacheDbPath)
        return false;

    const QFileInfo info(dbPath);
    return info.exists() && info.lastModified() == m_installedCacheMtime;
}

QString PackageSearch::rpmDatabasePath() const
{
    static const QStringList candidates = {
        QStringLiteral("/usr/lib/sysimage/rpm/rpmdb.sqlite"),
        QStringLiteral("/var/lib/rpm/rpmdb.sqlite")
    };
    for (const QString &path : candidates) {
        if (QFileInfo::exists(path))
            return path;
    }
    return {};
}

QString PackageSearch::sanitizeTerm(const QString &term)
{
    QString out;
    out.reserve(term.size());
    bool pendingSeparator = false;

    for (const QChar ch : term.trimmed()) {
        if (ch.isLetterOrNumber() || QStringLiteral("._+:-").contains(ch)) {
            if (pendingSeparator && !out.isEmpty())
                out += QLatin1Char('*');
            out += ch;
            pendingSeparator = false;
        } else if (ch.isSpace()) {
            pendingSeparator = true;
        }
        // All user supplied glob/control/shell metacharacters are discarded.
    }

    return out.left(128);
}
