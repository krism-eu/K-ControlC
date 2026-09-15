#pragma once

#include <QHash>
#include <QObject>
#include <QSet>
#include <QString>
#include <QStringList>
#include <QVariantList>

class SystemBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString osName READ osName CONSTANT)
    Q_PROPERTY(QString kernelVersion READ kernelVersion CONSTANT)
    Q_PROPERTY(QString architecture READ architecture CONSTANT)
    Q_PROPERTY(QString hostName READ hostName CONSTANT)
    Q_PROPERTY(QString memorySummary READ memorySummary CONSTANT)
    Q_PROPERTY(QString storageSummary READ storageSummary CONSTANT)
    Q_PROPERTY(QString desktopSession READ desktopSession CONSTANT)
    Q_PROPERTY(QString timeZone READ timeZone CONSTANT)
    Q_PROPERTY(QVariantList tools READ tools CONSTANT)

public:
    explicit SystemBackend(QObject *parent = nullptr);

    QString osName() const;
    QString kernelVersion() const;
    QString architecture() const;
    QString hostName() const;
    QString memorySummary() const;
    QString storageSummary() const;
    QString desktopSession() const;
    QString timeZone() const;
    QVariantList tools() const { return m_toolList; }

    Q_INVOKABLE QString quickSystemInfo() const;
    Q_INVOKABLE void copyToClipboard(const QString &text) const;
    Q_INVOKABLE bool toolAvailable(const QString &toolId) const;
    Q_INVOKABLE bool launchTool(const QString &toolId) const;
    Q_INVOKABLE bool launchKcm(const QString &kcmId) const;
    Q_INVOKABLE bool launchFlatpakManager() const;
    Q_INVOKABLE bool launchQuickAction(const QString &actionId) const;
    Q_INVOKABLE bool programAvailable(const QString &program) const;

    Q_INVOKABLE QString serviceState(const QString &service) const;
    Q_INVOKABLE bool restartService(const QString &service);
    Q_INVOKABLE QString networkState() const;
    Q_INVOKABLE bool ntpEnabled() const;
    Q_INVOKABLE bool setNtpEnabled(bool enabled);
    Q_INVOKABLE bool sessionAction(const QString &action);
    Q_INVOKABLE void notify(const QString &summary, const QString &body = QString()) const;

private:
    struct DesktopTool {
        QString id;
        QString title;
        QString description;
        QString category;
        QString icon;
        QString exec;
    };

    QString readOsName() const;
    QString toolProgram(const QString &toolId) const;
    QString resolveExecutable(const QString &program) const;
    void scanDesktopEntries();
    bool desktopEntryVisible(const QString &path) const;
    bool launchDesktopEntry(const DesktopTool &tool) const;
    static QStringList splitDesktopList(const QString &value);

    QVariantList m_toolList;
    QHash<QString, DesktopTool> m_desktopTools;
};
