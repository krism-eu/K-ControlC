#pragma once

#include <QAbstractListModel>
#include <QStringList>

// Ricerca pacchetti RPM disponibili (read-only, nessun pkexec):
// dnf5 repoquery --search <term>, arricchito con
//   - installed: presente nella rpmdb
//   - owned:     nella base immutabile (owned-packages.txt) -> rk rifiuterebbe
// Il modello alimenta la lista della pagina Software.
class PackageSearch : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        SummaryRole,
        InstalledRole,
        OwnedRole
    };

    explicit PackageSearch(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void search(const QString &term);

signals:
    void searchFinished();

private:
    struct Entry {
        QString name;
        QString summary;
        bool installed = false;
        bool owned = false;
    };
    QList<Entry> m_results;
    QStringList m_owned;
    QStringList m_installed;
};
