#include "PolkitHelper.h"
#include <QDebug>

PolkitHelper::PolkitHelper(QObject *parent)
    : QObject(parent)
{
}

void PolkitHelper::execute(const QString &program, const QStringList &args)
{
    if (m_running) {
        qWarning() << "PolkitHelper: operazione gia' in corso";
        return;
    }

    m_running = true;
    m_allOutput.clear();
    emit runningChanged();

    m_process = new QProcess(this);
    connect(m_process, &QProcess::readyReadStandardOutput,
            this, &PolkitHelper::onReadyRead);
    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &PolkitHelper::onProcessFinished);

    QStringList fullArgs;
    fullArgs << program << args;
    m_process->start("pkexec", fullArgs);
}

void PolkitHelper::onReadyRead()
{
    const QByteArray data = m_process->readAllStandardOutput();
    m_allOutput += QString::fromUtf8(data);
    const auto lines = data.split('\n');
    for (const QByteArray &l : lines) {
        if (!l.isEmpty())
            emit line(QString::fromUtf8(l));
    }
}

void PolkitHelper::onProcessFinished(int exitCode, QProcess::ExitStatus status)
{
    Q_UNUSED(status);
    const QByteArray rest = m_process->readAllStandardOutput();
    if (!rest.isEmpty()) {
        m_allOutput += QString::fromUtf8(rest);
        emit line(QString::fromUtf8(rest).trimmed());
    }

    m_running = false;
    QString output = m_allOutput;
    if (exitCode != 0) {
        const QString err = QString::fromUtf8(m_process->readAllStandardError());
        if (!err.isEmpty())
            output = err;
    }

    emit runningChanged();
    emit finished(exitCode == 0, output.trimmed());

    m_process->deleteLater();
    m_process = nullptr;
}
