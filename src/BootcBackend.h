#pragma once

#include <QObject>
#include <QProcess>
#include <QString>

class BootcBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool bootcAvailable READ bootcAvailable CONSTANT)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusChanged)
    Q_PROPERTY(QString errorText READ errorText NOTIFY statusChanged)
    Q_PROPERTY(QString persistentPackages READ persistentPackages NOTIFY packagesChanged)
    Q_PROPERTY(int persistentPackageCount READ persistentPackageCount NOTIFY packagesChanged)

public:
    explicit BootcBackend(QObject *parent = nullptr);

    bool bootcAvailable() const;
    bool busy() const { return m_busy; }
    QString statusText() const { return m_statusText; }
    QString errorText() const { return m_errorText; }
    QString persistentPackages() const { return m_persistentPackages; }
    int persistentPackageCount() const { return m_persistentPackageCount; }

    Q_INVOKABLE void refreshStatus();
    Q_INVOKABLE void refreshPackages();
    Q_INVOKABLE QString rkStatus() const { return m_persistentPackages; }

signals:
    void busyChanged();
    void statusChanged();
    void packagesChanged();

private:
    void setBusy(bool busy);
    void loadPackages();

    QProcess *m_process = nullptr;
    bool m_busy = false;
    QString m_statusText;
    QString m_errorText;
    QString m_persistentPackages;
    int m_persistentPackageCount = 0;
};
