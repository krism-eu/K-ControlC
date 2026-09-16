# Integrazione K-ControlC in un'immagine Fedora bootc

K-ControlC 0.4 è un'applicazione standalone Qt 6/Kirigami pensata per uso personale su Fedora bootc. Non duplica Plasma System Settings: integra solo le funzioni specifiche del sistema e gli strumenti di manutenzione che è utile avere in un unico posto.

## Runtime

- Qt 6 Core/Gui/Qml/Quick/DBus
- KF6 Kirigami
- `bootc`, `rpm`, `dnf5`, `dnf5-plugins`, `pkexec`, `tar`
- `/usr/bin/rk` come helper del layer persistente
- systemd/logind per sessione e restart servizi

Discover, Info Center, Partition Manager, KSystemLog, System Monitor, Konsole, Flatpak e fwupd sono opzionali: i relativi pulsanti vengono disabilitati se il programma non è disponibile.

## Compatibilità dati durante il rinomina OS

L'identità dell'app è autonoma (`org.kcontrolc`). Per non rompere il collaudo sul sistema attuale, il backend continua temporaneamente a leggere i percorsi dati legacy usati da `rk`:

- `/var/lib/raku-kris/packages.list`
- `/usr/share/raku-kris/owned-packages.txt`

Questi due percorsi vanno migrati insieme al rinomina dell'OS/helper. Fino ad allora non vanno cambiati nell'app da sola.

## Modello software

La base del sistema resta image-based e si aggiorna esclusivamente tramite BootC. K-ControlC usa DNF5 in lettura per catalogo, inventario, aggiornamenti disponibili, pacchetti recenti e repository; `rk` resta il punto di modifica del layer persistente.

L'abilitazione/disabilitazione dei repository usa `dnf5 config-manager`, che richiede il pacchetto `dnf5-plugins`.

## Privilegi

Non aggiungere wrapper shell generici. `PolkitHelper` valida programma e argomenti completi. La policy usa `auth_admin` senza retention e restringe le azioni tramite `exec.path`/`exec.argv1` per `rk`, `bootc` e `dnf5 config-manager`.

## Backup personali

Gli snapshot config/home sono archivi `tar.gz` eseguiti come utente e salvati in `~/K-ControlC Backups`. Non fanno parte del deployment BootC e non richiedono privilegi. Prima di avviare lo snapshot K-ControlC richiede almeno 1 GiB libero per la configurazione e 5 GiB per la home. Non viene effettuato ripristino automatico: l'archivio resta ispezionabile e ripristinabile manualmente.

## Pipeline immagine

Il workflow del repository produce un RPM testato. Il flusso consigliato è:

```text
K-ControlC source -> CI/test -> RPM -> build context OS -> immagine BootC
```

Il Containerfile dell'immagine può copiare l'RPM nel build context e installarlo con DNF5. Se l'RPM non viene prodotto, la build deve fallire invece di creare un'immagine senza K-ControlC.

## Verifica reale prima del tag

Provare sulla macchina reale:

```bash
bootc status --format json | head -c 500
kcmshell6 --list || true
dnf5 repo list --all --json
dnf5 config-manager --help
```

Poi verificare manualmente `rk sync/add/rm`, repository enable/disable, upgrade/rollback BootC, restart NetworkManager/CUPS/Bluetooth, Discover e creazione dei due tipi di backup.
