#pragma once

#include <QObject>
#include <QProcess>
#include <QStringList>

class PolkitHelper : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)

public:
    explicit PolkitHelper(QObject *parent = nullptr);

    Q_INVOKABLE void execute(const QString &program, const QStringList &args);
    Q_INVOKABLE bool launchUnprivileged(const QString &program, const QStringList &args = {});

    bool running() const { return m_running; }

signals:
    void runningChanged();
    void line(const QString &text);
    void finished(bool success, const QString &output);

private slots:
    void onReadyRead();
    void onProcessFinished(int exitCode, QProcess::ExitStatus status);
    void onProcessError(QProcess::ProcessError error);

private:
    bool isPrivilegedProgramAllowed(const QString &program) const;
    bool isUnprivilegedProgramAllowed(const QString &program) const;
    void consumeOutput(const QByteArray &data, bool flushPartial = false);
    void finishWithError(const QString &message);

    bool m_running = false;
    QProcess *m_process = nullptr;
    QString m_allOutput;
    QByteArray m_lineBuffer;
};
