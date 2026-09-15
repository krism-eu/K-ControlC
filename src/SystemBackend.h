#pragma once

#include <QObject>
#include <QString>

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

public:
    explicit SystemBackend(QObject *parent = nullptr);

    QString osName() const;
    QString kernelVersion() const;
    QString architecture() const;
    QString hostName() const;
    QString memorySummary() const;
    QString storageSummary() const;
    QString desktopSession() const;

    Q_INVOKABLE QString quickSystemInfo() const;
    Q_INVOKABLE void copyToClipboard(const QString &text) const;
    Q_INVOKABLE bool toolAvailable(const QString &toolId) const;
    Q_INVOKABLE bool launchTool(const QString &toolId) const;

private:
    QString readOsName() const;
    QString toolProgram(const QString &toolId) const;
};
