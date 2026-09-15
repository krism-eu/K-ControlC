# Integrazione K-ControlC nell'immagine raku

K-ControlC 0.4 è un'applicazione standalone Qt 6/Kirigami pensata per uso personale su raku/Fedora bootc. Non duplica Plasma System Settings: integra solo le funzioni specifiche del sistema e gli strumenti di manutenzione che è utile avere in un unico posto.

## Runtime

- Qt 6 Core/Gui/Qml/Quick/DBus
- KF6 Kirigami
- `bootc`, `rpm`, `dnf5`, `dnf5-plugins`, `pkexec`, `tar`
- `/usr/bin/rk` e `/var/lib/raku-kris/packages.list`
- systemd/logind per sessione e restart servizi

Discover, Info Center, Partition Manager, KSystemLog, System Monitor, Konsole, Flatpak e fwupd sono opzionali: i relativi pulsanti vengono disabilitati se il programma non è disponibile.

## Modello software

La base del sistema resta image-based e si aggiorna esclusivamente tramite BootC. K-ControlC usa DNF5 in lettura per catalogo, inventario, aggiornamenti disponibili, pacchetti recenti e repository; `rk` resta il punto di modifica del layer persistente.

L'abilitazione/disabilitazione dei repository usa `dnf5 config-manager`, che richiede il pacchetto `dnf5-plugins`.

## Privilegi

Non aggiungere wrapper shell generici. `PolkitHelper` valida programma e argomenti completi. La policy usa `auth_admin` senza retention e restringe le azioni tramite `exec.path`/`exec.argv1` per `rk`, `bootc` e `dnf5 config-manager`.

## Backup personali

Gli snapshot config/home sono archivi `tar.gz` eseguiti come utente e salvati in `~/K-ControlC Backups`. Non fanno parte del deployment BootC e non richiedono privilegi. Non viene effettuato ripristino automatico: l'archivio resta ispezionabile e ripristinabile manualmente.

## Pipeline immagine

Il workflow del repository produce un RPM testato. Nella pipeline raku il flusso consigliato è:

```text
K-ControlC source -> CI/test -> RPM -> build context raku -> immagine BootC
```

Il Containerfile dell'immagine può copiare l'RPM nel build context e installarlo con DNF5. Se l'RPM non viene prodotto, la build deve fallire invece di creare un'immagine senza K-ControlC.

## Verifica reale prima del tag

Provare sulla macchina raku:

```bash
bootc status --json --format-version=1
kcmshell6 --list || true
dnf5 repo list --all --json
dnf5 config-manager --help
```

Poi verificare manualmente `rk sync/add/rm`, repository enable/disable, upgrade/rollback BootC, restart NetworkManager/CUPS/Bluetooth, Discover e creazione dei due tipi di backup.
