#include "PackageSearch.h"

#include <QFile>
#include <QTextStream>

PackageSearch::PackageSearch(QObject *parent)
    : QAbstractListModel(parent)
{
    QFile file("/usr/share/raku-kris/owned-packages.txt");
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
    const QString trimmed = term.trimmed();
    ++m_generation;
    stopActiveProcess();

    if (trimmed.size() < 2) {
        clearResults();
        setSearching(false);
        emit searchFinished();
        return;
    }

    m_installed.clear();
    setSearching(true);
    startInstalledQuery(trimmed);
}

void PackageSearch::startInstalledQuery(const QString &term)
{
    const quint64 generation = m_generation;
    auto *process = new QProcess(this);
    m_process = process;

    connect(process, &QProcess::finished, this,
            [this, process, term, generation](int exitCode, QProcess::ExitStatus status) {
        if (process != m_process || generation != m_generation) {
            process->deleteLater();
            return;
        }

        if (status == QProcess::NormalExit && exitCode == 0) {
            const auto lines = process->readAllStandardOutput().split('\n');
            for (const QByteArray &line : lines) {
                const QString name = QString::fromUtf8(line).trimmed();
                if (!name.isEmpty())
                    m_installed.insert(name);
            }
        }

        m_process = nullptr;
        process->deleteLater();
        startRepoQuery(term);
    });

    connect(process, &QProcess::errorOccurred, this,
            [this, process, term, generation](QProcess::ProcessError error) {
        if (process != m_process || generation != m_generation || error != QProcess::FailedToStart)
            return;
        m_process = nullptr;
        process->deleteLater();
        emit searchError(tr("Impossibile avviare rpm per leggere i pacchetti installati."));
        startRepoQuery(term);
    });

    process->start("/usr/bin/rpm", {"-qa", "--qf", "%{NAME}\\n"});
}

void PackageSearch::startRepoQuery(const QString &term)
{
    const quint64 generation = m_generation;
    auto *process = new QProcess(this);
    m_process = process;

    connect(process, &QProcess::finished, this,
            [this, process, generation](int exitCode, QProcess::ExitStatus status) {
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

    connect(process, &QProcess::errorOccurred, this,
            [this, process, generation](QProcess::ProcessError error) {
        if (process != m_process || generation != m_generation || error != QProcess::FailedToStart)
            return;
        m_process = nullptr;
        process->deleteLater();
        clearResults();
        setSearching(false);
        emit searchError(tr("Impossibile avviare dnf5."));
        emit searchFinished();
    });

    process->start("/usr/bin/dnf5",
                   {"repoquery", "--available", "--search", term,
                    "--queryformat", "%{name}\t%{summary}\\n"});
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
    disconnect(m_process, nullptr, this, nullptr);
    m_process->kill();
    m_process->deleteLater();
    m_process = nullptr;
}
