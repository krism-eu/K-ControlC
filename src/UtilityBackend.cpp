#include "UtilityBackend.h"

#include <QFileInfo>
#include <QRegularExpression>
#include <QStandardPaths>

UtilityBackend::UtilityBackend(QObject *parent)
    : QObject(parent)
{
}

bool UtilityBackend::validPackageName(const QString &name) const
{
    static const QRegularExpression pattern(QStringLiteral("^[A-Za-z0-9][A-Za-z0-9._+:-]{0,127}$"));
    return pattern.match(name).hasMatch();
}

bool UtilityBackend::validContainerName(const QString &name) const
{
    static const QRegularExpression pattern(QStringLiteral("^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$"));
    return pattern.match(name).hasMatch();
}

bool UtilityBackend::start(const QString &program, const QStringList &args, const QString &title)
{
    if (m_busy)
        return false;

    const QString executable = program.startsWith(QLatin1Char('/'))
        ? (QFileInfo(program).isExecutable() ? program : QString())
        : QStandardPaths::findExecutable(program);
    if (executable.isEmpty()) {
        m_title = title;
        m_output = tr("Comando non disponibile: %1").arg(program);
        emit stateChanged();
        return false;
    }

    m_busy = true;
    m_title = title;
    m_output.clear();
    emit stateChanged();

    auto *process = new QProcess(this);
    m_process = process;
    process->setProcessChannelMode(QProcess::MergedChannels);

    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this](int exitCode, QProcess::ExitStatus status) {
        if (!m_process)
            return;
        const QString text = QString::fromUtf8(m_process->readAllStandardOutput()).trimmed();
        const bool ok = status == QProcess::NormalExit && exitCode == 0;
        finish(text.isEmpty() ? (ok ? tr("Nessun output.") : tr("Comando terminato con codice %1.").arg(exitCode)) : text);
    });

    connect(process, &QProcess::errorOccurred, this,
            [this](QProcess::ProcessError error) {
        if (!m_process || error != QProcess::FailedToStart)
            return;
        finish(tr("Impossibile avviare il comando: %1").arg(m_process->errorString()));
    });

    process->start(executable, args);
    return true;
}

void UtilityBackend::finish(const QString &message)
{
    if (m_process) {
        m_process->deleteLater();
        m_process = nullptr;
    }
    m_busy = false;
    m_output = message;
    emit stateChanged();
}

bool UtilityBackend::runBookmark(const QString &id)
{
    if (id == QStringLiteral("failed-units"))
        return start(QStringLiteral("systemctl"), {QStringLiteral("--failed"), QStringLiteral("--no-pager"), QStringLiteral("--plain")}, tr("Unità systemd fallite"));
    if (id == QStringLiteral("timers"))
        return start(QStringLiteral("systemctl"), {QStringLiteral("list-timers"), QStringLiteral("--all"), QStringLiteral("--no-pager")}, tr("Timer systemd"));
    if (id == QStringLiteral("ports"))
        return start(QStringLiteral("ss"), {QStringLiteral("-lntu")}, tr("Porte in ascolto"));
    if (id == QStringLiteral("sessions"))
        return start(QStringLiteral("loginctl"), {QStringLiteral("list-sessions"), QStringLiteral("--no-legend")}, tr("Sessioni attive"));
    if (id == QStringLiteral("mounts"))
        return start(QStringLiteral("findmnt"), {QStringLiteral("-o"), QStringLiteral("TARGET,SOURCE,FSTYPE,OPTIONS")}, tr("Mount attivi"));
    if (id == QStringLiteral("top-cpu"))
        return start(QStringLiteral("ps"), {QStringLiteral("-eo"), QStringLiteral("pid,comm,%cpu,%mem"), QStringLiteral("--sort=-%cpu")}, tr("Processi per CPU"));
    if (id == QStringLiteral("top-memory"))
        return start(QStringLiteral("ps"), {QStringLiteral("-eo"), QStringLiteral("pid,comm,%mem,%cpu"), QStringLiteral("--sort=-%mem")}, tr("Processi per memoria"));
    if (id == QStringLiteral("selinux"))
        return start(QStringLiteral("getenforce"), {}, tr("SELinux"));
    if (id == QStringLiteral("services-active"))
        return start(QStringLiteral("systemctl"), {QStringLiteral("list-units"), QStringLiteral("--type=service"), QStringLiteral("--state=running"), QStringLiteral("--no-pager"), QStringLiteral("--plain")}, tr("Servizi attivi"));
    return false;
}

bool UtilityBackend::previewRpmInstall(const QString &packageName)
{
    if (!validPackageName(packageName)) {
        m_title = tr("Anteprima RPM");
        m_output = tr("Nome pacchetto non valido.");
        emit stateChanged();
        return false;
    }
    return start(QStringLiteral("/usr/bin/rk"),
                 {QStringLiteral("plan"), packageName},
                 tr("Piano installazione persistente: %1").arg(packageName));
}

bool UtilityBackend::runFlatpak(const QString &mode, const QString &query)
{
    if (mode == QStringLiteral("installed"))
        return start(QStringLiteral("/usr/bin/flatpak"),
                     {QStringLiteral("list"), QStringLiteral("--app"),
                      QStringLiteral("--columns=name,application,version,origin")},
                     tr("Flatpak installati"));
    if (mode == QStringLiteral("updates"))
        return start(QStringLiteral("/usr/bin/flatpak"),
                     {QStringLiteral("remote-ls"), QStringLiteral("--updates"), QStringLiteral("--app"),
                      QStringLiteral("--columns=name,application,version,origin")},
                     tr("Aggiornamenti Flatpak"));
    if (mode == QStringLiteral("remotes"))
        return start(QStringLiteral("/usr/bin/flatpak"),
                     {QStringLiteral("remotes"), QStringLiteral("--columns=name,title,url,options")},
                     tr("Remote Flatpak"));
    if (mode == QStringLiteral("search") && query.trimmed().size() >= 2)
        return start(QStringLiteral("/usr/bin/flatpak"),
                     {QStringLiteral("search"), QStringLiteral("--columns=name,description,application,version,branch,remotes"), query.trimmed()},
                     tr("Ricerca Flatpak: %1").arg(query.trimmed()));
    if (mode == QStringLiteral("install") && validPackageName(query.trimmed()))
        return start(QStringLiteral("/usr/bin/flatpak"),
                     {QStringLiteral("install"), QStringLiteral("--user"), QStringLiteral("--noninteractive"), QStringLiteral("flathub"), query.trimmed()},
                     tr("Installazione Flatpak: %1").arg(query.trimmed()));
    if (mode == QStringLiteral("remove") && validPackageName(query.trimmed()))
        return start(QStringLiteral("/usr/bin/flatpak"),
                     {QStringLiteral("uninstall"), QStringLiteral("--user"), QStringLiteral("--noninteractive"), query.trimmed()},
                     tr("Rimozione Flatpak: %1").arg(query.trimmed()));
    return false;
}

bool UtilityBackend::addFlathubUser()
{
    return start(QStringLiteral("/usr/bin/flatpak"),
                 {QStringLiteral("remote-add"), QStringLiteral("--user"), QStringLiteral("--if-not-exists"),
                  QStringLiteral("flathub"), QStringLiteral("https://flathub.org/repo/flathub.flatpakrepo")},
                 tr("Aggiunta Flathub per l'utente"));
}

bool UtilityBackend::runPodman(const QString &mode, const QString &container, const QString &value)
{
    if (mode == QStringLiteral("list"))
        return start(QStringLiteral("/usr/bin/podman"),
                     {QStringLiteral("ps"), QStringLiteral("--all"), QStringLiteral("--size"), QStringLiteral("--format"), QStringLiteral("json")},
                     tr("Container Podman"));

    const QString name = container.trimmed();
    if (!validContainerName(name))
        return false;

    if (mode == QStringLiteral("info"))
        return start(QStringLiteral("/usr/bin/podman"), {QStringLiteral("inspect"), name}, tr("Info container: %1").arg(name));
    if (mode == QStringLiteral("logs"))
        return start(QStringLiteral("/usr/bin/podman"), {QStringLiteral("logs"), QStringLiteral("--tail"), QStringLiteral("200"), name}, tr("Log container: %1").arg(name));
    if (mode == QStringLiteral("start"))
        return start(QStringLiteral("/usr/bin/podman"), {QStringLiteral("start"), name}, tr("Avvio container: %1").arg(name));
    if (mode == QStringLiteral("stop"))
        return start(QStringLiteral("/usr/bin/podman"), {QStringLiteral("stop"), name}, tr("Arresto container: %1").arg(name));
    if (mode == QStringLiteral("restart"))
        return start(QStringLiteral("/usr/bin/podman"), {QStringLiteral("restart"), name}, tr("Riavvio container: %1").arg(name));
    if (mode == QStringLiteral("rename") && validContainerName(value.trimmed()))
        return start(QStringLiteral("/usr/bin/podman"), {QStringLiteral("rename"), name, value.trimmed()}, tr("Rinomina container: %1").arg(name));

    return false;
}
