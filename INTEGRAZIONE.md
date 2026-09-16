# Integrazione KCC in KrisOS / Fedora bootc

KCC 0.4 è un'applicazione standalone Qt 6/Kirigami pensata per uso personale su Fedora bootc. Non duplica Plasma System Settings: integra solo le funzioni specifiche del sistema e gli strumenti di manutenzione che è utile avere in un unico posto.

## Runtime

- Qt 6 Core/Gui/Qml/Quick/DBus
- KF6 Kirigami
- `bootc`, `rpm`, `dnf5`, `dnf5-plugins`, `pkexec`, `tar`
- `/usr/bin/rk` come helper del layer persistente KrisOS
- systemd/logind per sessione e restart servizi

Info Center, Partition Manager, KSystemLog, System Monitor, Konsole, Flatpak, Podman e fwupd sono opzionali: i relativi controlli vengono disabilitati o mostrano lo stato non disponibile se il programma non è presente.

## Compatibilità dati KrisOS

KCC usa come layout primario quello attuale di KrisOS:

- `/var/lib/krisos/packages.list`
- `/usr/share/krisos/owned-packages.txt`

Per non rompere installazioni già avviate con il layout precedente, il backend mantiene temporaneamente un fallback in sola lettura verso:

- `/var/lib/raku-kris/packages.list`
- `/usr/share/raku-kris/owned-packages.txt`

Il nuovo percorso ha sempre precedenza. Il fallback legacy potrà essere rimosso solo dopo avere verificato che tutte le installazioni migrate usino esclusivamente `/var/lib/krisos` e `/usr/share/krisos`.

`/usr/bin/rk` non viene rinominato: è ancora il nome dell'helper nel repository KrisOS corrente e cambiarlo unilateralmente romperebbe le operazioni persistenti e la policy Polkit.

## Modello software

La base del sistema resta image-based e si aggiorna esclusivamente tramite BootC. KCC usa DNF5 in lettura per catalogo, inventario, aggiornamenti disponibili, pacchetti recenti e repository; `rk` resta il punto di modifica del layer persistente.

L'abilitazione/disabilitazione dei repository usa `dnf5 config-manager`, che richiede il pacchetto `dnf5-plugins`.

## Privilegi

Non aggiungere wrapper shell generici. `PolkitHelper` valida programma e argomenti completi. La policy usa `auth_admin` senza retention e restringe le azioni tramite `exec.path`/`exec.argv1` per `rk`, `bootc` e `dnf5 config-manager`.

## Backup personali

Gli snapshot config/home sono normali archivi `tar.gz` eseguiti come utente. Non fanno parte del deployment BootC e non richiedono privilegi. Prima di avviare lo snapshot KCC richiede almeno 1 GiB libero per la configurazione e 5 GiB per la home. Non viene effettuato ripristino automatico: l'archivio resta ispezionabile e ripristinabile manualmente.

## Pipeline immagine

Il repository KCC produce un RPM testato. Il flusso consigliato è:

```text
KCC source -> CI/test -> RPM -> build context KrisOS -> immagine BootC
```

La build KrisOS può pescare l'RPM prodotto separatamente e installarlo nella base. L'ordine è importante: **KCC deve essere installato prima che KrisOS generi `/usr/share/krisos/owned-packages.txt` e `owned-nevra.txt`**. In questo modo KCC viene classificato correttamente come pacchetto della base immutabile e `rk` non proverà mai a trattarlo come pacchetto persistente dell'overlay.

La build deve fallire se l'RPM richiesto non è disponibile o non si installa correttamente; non è consigliato continuare creando un'immagine parziale. Dopo l'installazione dell'RPM, eseguire almeno `rpm -q`, `rpm -V` e lo smoke test dell'eseguibile prima dello snapshot finale dei pacchetti owned.

Per compatibilità con installazioni esistenti, il nome tecnico del pacchetto/eseguibile resta temporaneamente `k-controlc` mentre l'identità utente è già `KCC`. Una rinomina tecnica del NEVRA va fatta solo insieme a `Provides/Obsoletes` e alla pipeline KrisOS, così l'upgrade non lascia due pacchetti concorrenti.

## Verifica reale prima del tag

Provare sulla macchina reale:

```bash
sudo bootc status --format json | head -c 500
dnf5 repo list --all --json
dnf5 config-manager --help
rpm -q k-controlc
rpm -V k-controlc
```

Poi verificare manualmente `rk sync/add/rm`, ricerca RPM con dimensioni e preview dipendenze, Flatpak, Podman, repository enable/disable, upgrade/rollback BootC, restart NetworkManager/CUPS/Bluetooth e creazione dei backup.
