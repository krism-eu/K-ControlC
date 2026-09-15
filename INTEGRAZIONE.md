# Integrazione K-ControlC nell'immagine raku

K-ControlC è un'applicazione standalone Qt 6/QML. Va installata nell'immagine bootc insieme alla desktop entry, all'icona e alla policy Polkit.

## Runtime richiesto

- Qt 6 Core/Gui/Qml/Quick/DBus
- `bootc`, `rpm`, `dnf5`, `pkexec`
- `/usr/bin/rk` e `/var/lib/raku-kris/packages.list`
- systemd/logind e NetworkManager per i moduli integrati

Strumenti come Plasma System Settings, Info Center, Partition Manager, firewall-config, Discover, KSystemLog, virt-manager, fwupd e Konsole sono opzionali. Il catalogo Strumenti viene generato dai file `.desktop` effettivamente installati.

## Privilegi

Non aggiungere wrapper shell generici. `PolkitHelper` consente soltanto combinazioni esplicite per `rk`, `bootc` e le sei azioni runtime firewalld. La policy usa `exec.path` + `exec.argv1` e `auth_admin` senza retention.

## BootC

Lo stato viene richiesto con `bootc status --json --format-version=1`; se la versione installata non lo supporta, l'interfaccia ripiega sul formato human-readable. Upgrade e rollback sono sempre eseguiti dal binario bootc.

## Verifica immagine

Prima di creare il tag di release eseguire almeno:

```bash
./tests/e2e-readonly.sh
kcmshell6 --list | grep -i flatpak || true
bootc status --json --format-version=1
```

Poi verificare manualmente autenticazione Polkit, `rk sync/add/rm`, upgrade/rollback bootc, session actions logind, restart servizi e quick actions firewalld.
