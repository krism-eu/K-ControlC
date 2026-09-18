#pragma once

#include <QObject>
#include <QPointer>
#include <QProcess>
#include <QVariantList>

class SoftwareBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList repositories READ repositories NOTIFY repositoriesChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString errorText READ errorText NOTIFY errorTextChanged)

public:
    explicit SoftwareBackend(QObject *parent = nullptr);

    const QVariantList &repositories() const { return m_repositories; }
    bool busy() const { return m_busy; }
    const QString &errorText() const { return m_errorText; }

    Q_INVOKABLE void refreshRepositories();

signals:
    void repositoriesChanged();
    void busyChanged();
    void errorTextChanged();

private:
    void setBusy(bool busy);
    void setError(const QString &error);

    QVariantList m_repositories;
    QPointer<QProcess> m_process;
    bool m_busy = false;
    QString m_errorText;
};
