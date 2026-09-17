# krisCC

krisCC è un **Control Center personale Kirigami per KrisOS / Fedora bootc**. Non vuole sostituire Plasma System Settings: rete, utenti, firewall, display, audio e preferenze desktop restano agli strumenti KDE già presenti. L'interfaccia resta volutamente nello stile Breeze/Plasma, usando componenti Kirigami e icone KDE senza introdurre un tema proprietario.

## Cosa gestisce

- **Panoramica**: sistema, BootC, storage, pacchetti persistenti e Quick System Info.
- **Software RPM**: ricerca, installati, aggiornabili, pacchetti recenti, provenienza Base/Persistente/Locale e piano della transazione tramite la stessa policy `rk` usata per installare.
- **Flatpak**: ricerca strutturata, installati, aggiornamenti, update singolo o completo del profilo utente, remote e integrazione Flathub senza dipendere da Discover.
- **Container / Podman**: elenco container, stato, immagine, dimensione, informazioni, log, start/stop/restart e rinomina. Nessuna rimozione automatica.
- **BootC**: stato del deployment, controllo del registry remoto con `bootc upgrade --check`, download/preparazione e applicazione. KrisOS supporta un solo deployment e krisCC non espone rollback.
- **Strumenti e comandi**: utility amministrative mirate, servizi rapidi e launcher KDE disponibili sul sistema.
- **Backup e recovery**: `rk sync`, azioni di sessione e snapshot `tar.gz` della configurazione o della home.

## Sicurezza

Le modifiche privilegiate passano da `pkexec` con una allowlist C++ stretta. La policy non usa `auth_admin_keep`. Sono ammesse soltanto le combinazioni previste per `rk` e `bootc`; krisCC non espone più mutazioni arbitrarie dei repository DNF5 e non esegue shell root generiche.

Le query DNF5 sono read-only e limitate ai repository `fedora` e `updates`, gli stessi repository ammessi da `rk`. L'anteprima RPM usa `rk plan`, quindi la UI non presenta una transazione che l'installazione reale rifiuterebbe. Le operazioni Flatpak restano rootless nel profilo utente; anche gli aggiornamenti usano `flatpak update --user`. Le operazioni Podman dell'utente restano rootless.

## Compatibilità KrisOS

krisCC usa in via primaria il layout corrente di KrisOS:

- `/var/lib/krisos/packages.list`
- `/usr/share/krisos/owned-packages.txt`
- `/usr/bin/rk`

Per la fase di migrazione mantiene un fallback in sola lettura verso i vecchi percorsi `/var/lib/raku-kris` e `/usr/share/raku-kris`. Il layout KrisOS ha sempre precedenza.

Il pacchetto RPM e l'eseguibile hanno una sola identità tecnica: **`krisCC`**. Non sono previsti alias, binari o compatibilità RPM con i vecchi nomi sperimentali.

krisCC è parte della base immutabile di KrisOS: le release normali del control center arrivano insieme a una nuova immagine KrisOS, non tramite `rk` o un aggiornamento RPM separato sul sistema installato.

## Build locale

Dipendenze Fedora:

```bash
dnf install gcc-c++ cmake ninja-build qt6-qtbase-devel qt6-qtdeclarative-devel kf6-kirigami-devel
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
./build/krisCC
```

È disponibile anche `--background` per l'avvio di sessione senza mostrare la finestra principale. L'istanza registra un servizio D-Bus di sessione; un successivo avvio dal menu riattiva la stessa finestra invece di creare un secondo processo:

```bash
./build/krisCC --background
```

## RPM e integrazione nell'immagine

Lo spec RPM è `packaging/krisCC.spec` e produce **`krisCC-0.4.0-*.rpm`**. La CI Fedora 44 costruisce l'RPM, lo installa in un ambiente pulito, riesegue lo smoke test e produce `SHA256SUMS` dell'artefatto RPM.

Il flusso previsto per KrisOS è:

```text
krisCC source -> CI/test -> RPM identificato + SHA256 -> build KrisOS -> snapshot owned packages -> immagine BootC
```

L'RPM deve essere installato **prima** della generazione di `/usr/share/krisos/owned-packages.txt` e `owned-nevra.txt`, così krisCC viene riconosciuto come parte della base immutabile e non come pacchetto dell'overlay. La build KrisOS deve consumare un artefatto krisCC verificabile, non ricostruire implicitamente un altro repository durante la build dell'OS.

Esempio manuale:

```bash
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
git archive --format=tar.gz --prefix=krisCC-0.4.0/ \
  -o ~/rpmbuild/SOURCES/krisCC-0.4.0.tar.gz HEAD
cp packaging/krisCC.spec ~/rpmbuild/SPECS/krisCC.spec
rpmbuild -ba ~/rpmbuild/SPECS/krisCC.spec
```

Repository: https://github.com/krism-eu/krisCC

## Test reale

La CI verifica compilazione, caricamento QML/Kirigami, controlli DNF5 locali, spec RPM, installazione di staging e installazione/smoke dell'RPM. Prima di considerare una release definitiva vanno comunque provati sulla macchina reale: `rk plan/add/rm/sync`, autenticazione Polkit, ricerca RPM con dimensioni e dipendenze, aggiornamenti Flatpak, Podman, `bootc upgrade --check`, download/apply BootC, restart servizi e backup della home/configurazione.
