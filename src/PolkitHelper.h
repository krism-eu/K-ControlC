#pragma once

#include <QObject>
#include <QProcess>
#include <QStringList>

// pkexec wrapper per operazioni privilegiate.
// SOLO helper consentiti dalla policy org.raku.controlcenter.*:
//   /usr/bin/rk, /usr/bin/bootc  (annotate exec.path nella policy).
// Nessun executeRaw: pkexec con programma arbitrario non ha action
// corrispondente e fallirebbe comunque; se mai aggiunta una policy
// catch-all diventerebbe un buco. Rimosso per costruzione.
class PolkitHelper : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)

public:
    explicit PolkitHelper(QObject *parent = nullptr);

    Q_INVOKABLE void execute(const QString &program, const QStringList &args);

    bool running() const { return m_running; }

signals:
    void runningChanged();
    // Emesso riga per riga dallo stdout del processo (progress per
    // operazioni lunghe: bootc upgrade, rk sync, rk add con download).
    void line(const QString &text);
    void finished(bool success, const QString &output);

private slots:
    void onReadyRead();
    void onProcessFinished(int exitCode, QProcess::ExitStatus status);

private:
    bool m_running = false;
    QProcess *m_process = nullptr;
    QString m_allOutput;
};
