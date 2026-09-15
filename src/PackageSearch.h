#pragma once

#include <QAbstractListModel>
#include <QDateTime>
#include <QPointer>
#include <QProcess>
#include <QSet>
#include <QString>

class PackageSearch : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(bool searching READ searching NOTIFY searchingChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        SummaryRole,
        InstalledRole,
        OwnedRole,
        PersistentRole,
        VersionRole,
        RepositoryRole,
        ArchRole
    };

    explicit PackageSearch(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void search(const QString &term);
    Q_INVOKABLE void loadInstalled();
    Q_INVOKABLE void loadUpgrades();
    Q_INVOKABLE void loadRecent();
    bool searching() const { return m_searching; }
    int count() const { return m_results.size(); }

signals:
    void searchingChanged();
    void countChanged();
    void searchFinished();
    void searchError(const QString &message);

private:
    struct Entry {
        QString name;
        QString summary;
        QString version;
        QString repository;
        QString arch;
        bool installed = false;
        bool owned = false;
        bool persistent = false;
    };

    void clearResults();
    void setSearching(bool searching);
    void startInstalledQuery(const QString &term);
    void startRepoQuery(const QString &term);
    void startListQuery(const QString &filter, bool installedEntries);
    void stopActiveProcess();
    void refreshPersistentSet();
    bool installedCacheCurrent() const;
    QString rpmDatabasePath() const;
    static QString sanitizeTerm(const QString &term);

    QList<Entry> m_results;
    QSet<QString> m_owned;
    QSet<QString> m_installed;
    QSet<QString> m_persistent;
    QPointer<QProcess> m_process;
    QDateTime m_installedCacheMtime;
    QString m_installedCacheDbPath;
    bool m_installedCacheValid = false;
    bool m_searching = false;
    quint64 m_generation = 0;
};
