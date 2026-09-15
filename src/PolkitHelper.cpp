#include "PolkitHelper.h"

#include <QDebug>

PolkitHelper::PolkitHelper(QObject *parent)
    : QObject(parent)
{
}

void PolkitHelper::execute(const QString &program, const QStringList &args)
{
    if (m_running) {
        emit finished(false, tr("Un'altra operazione privilegiata e' gia' in corso."));
        return;
    }

    if (!isPrivilegedProgramAllowed(program)) {
        emit finished(false, tr("Programma privilegiato non consentito: %1").arg(program));
        return;
    }

    m_running = true;
    m_allOutput.clear();
    m_lineBuffer.clear();
    emit runningChanged();

    m_process = new QProcess(this);
    m_process->setProcessChannelMode(QProcess::MergedChannels);
    connect(m_process, &QProcess::readyReadStandardOutput,
            this, &PolkitHelper::onReadyRead);
    connect(m_process, &QProcess::errorOccurred,
            this, &PolkitHelper::onProcessError);
    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &PolkitHelper::onProcessFinished);

    QStringList fullArgs;
    fullArgs << program << args;
    m_process->start("/usr/bin/pkexec", fullArgs);
}

bool PolkitHelper::launchUnprivileged(const QString &program, const QStringList &args)
{
    if (!isUnprivilegedProgramAllowed(program)) {
        qWarning() << "PolkitHelper: programma non privilegiato non consentito:" << program;
        return false;
    }
    return QProcess::startDetached(program, args);
}

void PolkitHelper::onReadyRead()
{
    if (m_process)
        consumeOutput(m_process->readAllStandardOutput());
}

void PolkitHelper::onProcessFinished(int exitCode, QProcess::ExitStatus status)
{
    if (!m_process)
        return;

    consumeOutput(m_process->readAllStandardOutput(), true);
    const bool success = status == QProcess::NormalExit && exitCode == 0;
    const QString output = m_allOutput.trimmed();

    m_process->deleteLater();
    m_process = nullptr;
    m_running = false;
    emit runningChanged();
    emit finished(success, output);
}

void PolkitHelper::onProcessError(QProcess::ProcessError error)
{
    if (!m_process || error != QProcess::FailedToStart)
        return;
    finishWithError(tr("Impossibile avviare pkexec: %1").arg(m_process->errorString()));
}

bool PolkitHelper::isPrivilegedProgramAllowed(const QString &program) const
{
    return program == QStringLiteral("/usr/bin/rk")
        || program == QStringLiteral("/usr/bin/bootc");
}

bool PolkitHelper::isUnprivilegedProgramAllowed(const QString &program) const
{
    return program == QStringLiteral("/usr/bin/kcmshell6");
}

void PolkitHelper::consumeOutput(const QByteArray &data, bool flushPartial)
{
    if (!data.isEmpty()) {
        m_allOutput += QString::fromUtf8(data);
        m_lineBuffer += data;
    }

    qsizetype newline = -1;
    while ((newline = m_lineBuffer.indexOf('\n')) >= 0) {
        QByteArray lineData = m_lineBuffer.left(newline);
        m_lineBuffer.remove(0, newline + 1);
        if (!lineData.isEmpty() && lineData.endsWith('\r'))
            lineData.chop(1);
        if (!lineData.isEmpty())
            emit line(QString::fromUtf8(lineData));
    }

    if (flushPartial && !m_lineBuffer.isEmpty()) {
        emit line(QString::fromUtf8(m_lineBuffer));
        m_lineBuffer.clear();
    }
}

void PolkitHelper::finishWithError(const QString &message)
{
    if (m_process) {
        m_process->deleteLater();
        m_process = nullptr;
    }
    m_running = false;
    m_lineBuffer.clear();
    emit runningChanged();
    emit finished(false, message);
}
