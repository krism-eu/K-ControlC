#pragma once

#include <QObject>
#include <QPointer>
#include <QProcess>
#include <QString>

class UtilityBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY stateChanged)
    Q_PROPERTY(QString title READ title NOTIFY stateChanged)
    Q_PROPERTY(QString output READ output NOTIFY stateChanged)

public:
    explicit UtilityBackend(QObject *parent = nullptr);

    bool busy() const { return m_busy; }
    QString title() const { return m_title; }
    QString output() const { return m_output; }

    Q_INVOKABLE bool runBookmark(const QString &id);
    Q_INVOKABLE bool previewRpmInstall(const QString &packageName);
    Q_INVOKABLE bool runFlatpak(const QString &mode, const QString &query = QString());
    Q_INVOKABLE bool addFlathubUser();
    Q_INVOKABLE bool runPodman(const QString &mode, const QString &container = QString(), const QString &value = QString());

signals:
    void stateChanged();

private:
    bool start(const QString &program, const QStringList &args, const QString &title);
    bool validPackageName(const QString &name) const;
    bool validContainerName(const QString &name) const;
    void finish(const QString &message = QString());

    QPointer<QProcess> m_process;
    bool m_busy = false;
    QString m_title;
    QString m_output;
};
