# krisCC

krisCC è un **Control Center personale Kirigami per KrisOS / Fedora bootc**. Non vuole sostituire Plasma System Settings: rete, utenti, firewall, display, audio e preferenze desktop restano agli strumenti KDE già presenti.

## Cosa gestisce

- **Panoramica**: sistema, BootC, storage, pacchetti persistenti e Quick System Info.
- **Software RPM**: ricerca, installati, aggiornabili, pacchetti recenti, repository DNF5, provenienza Base/Persistente/Locale e anteprima della transazione prima dell'installazione.
- **Flatpak**: ricerca strutturata, installati, aggiornamenti, remote e integrazione Flathub senza dipendere da Discover.
- **Container / Podman**: elenco container, stato, immagine, dimensione, informazioni, log, start/stop/restart e rinomina. Nessuna rimozione automatica.
- **BootC**: stato deployment JSON, upgrade, download/apply e rollback.
- **Strumenti e comandi**: utility amministrative mirate, servizi rapidi e launcher KDE disponibili sul sistema.
- **Recovery e backup**: rollback BootC, `rk sync`, azioni di sessione e snapshot `tar.gz` della configurazione o della home.

## Sicurezza

Le modifiche privilegiate passano da `pkexec` con una allowlist C++ stretta. La policy non usa `auth_admin_keep`. Sono ammesse soltanto le combinazioni previste per `rk`, `bootc` e l'abilitazione/disabilitazione dei repository tramite `dnf5 config-manager`. Non vengono eseguite shell root generiche.

Le query DNF5 sono read-only. L'anteprima delle dipendenze usa DNF5 senza applicare la transazione. Le operazioni Podman dell'utente non introducono un helper root generico.

## Compatibilità KrisOS

krisCC usa in via primaria il layout corrente di KrisOS:

- `/var/lib/krisos/packages.list`
- `/usr/share/krisos/owned-packages.txt`
- `/usr/bin/rk`

Per la fase di migrazione mantiene un fallback in sola lettura verso i vecchi percorsi `/var/lib/raku-kris` e `/usr/share/raku-kris`. Il layout KrisOS ha sempre precedenza.

Il pacchetto RPM e l'eseguibile si chiamano **`krisCC`**. Il namespace QML è `org.kriscc`, le azioni Polkit usano `org.kriscc.controlcenter.*`, il desktop file è `krisCC.desktop` e l'AppStream ID è `org.kriscc.KrisCC`.

Lo spec mantiene `Provides/Obsoletes` soltanto per l'identità storica `k-controlc`. **Non** dichiara `Provides` o `Obsoletes` per `kcc`, perché Fedora distribuisce già un pacchetto non correlato chiamato `kcc` e i due devono poter convivere. Le build transitorie del nostro precedente `kcc-0.4.0` non vengono quindi rimosse automaticamente: se una di quelle build è stata installata manualmente, va verificata e rimossa esplicitamente prima dell'integrazione definitiva.

## Build locale

Dipendenze Fedora:

```bash
dnf install gcc-c++ cmake ninja-build qt6-qtbase-devel qt6-qtdeclarative-devel kf6-kirigami-devel
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
./build/krisCC
```

## RPM e integrazione nell'immagine

Lo spec RPM è `packaging/krisCC.spec` e produce **`krisCC-0.4.0-*.rpm`**. La CI Fedora 44 costruisce l'RPM, lo installa nel container, verifica la sostituzione di un vecchio pacchetto `k-controlc`, verifica la coesistenza con il pacchetto Fedora `kcc` e riesegue lo smoke test con `/usr/bin/krisCC`.

Il flusso previsto per KrisOS è:

```text
krisCC source -> CI/test -> krisCC RPM -> build context KrisOS -> installazione nella base -> snapshot owned packages -> immagine BootC
```

L'RPM deve essere installato **prima** della generazione di `/usr/share/krisos/owned-packages.txt` e `owned-nevra.txt`, così krisCC viene riconosciuto come parte della base immutabile e non come pacchetto dell'overlay.

Esempio manuale:

```bash
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
git archive --format=tar.gz --prefix=krisCC-0.4.0/ \
  -o ~/rpmbuild/SOURCES/krisCC-0.4.0.tar.gz HEAD
cp packaging/krisCC.spec ~/rpmbuild/SPECS/krisCC.spec
rpmbuild -ba ~/rpmbuild/SPECS/krisCC.spec
```

Repository: https://github.com/krism-eu/KCC

## Test reale

La CI verifica compilazione, caricamento QML/Kirigami, controlli DNF5 locali, spec RPM, installazione di staging, sostituzione `k-controlc` → `krisCC`, coesistenza con Fedora `kcc` e installazione/smoke dell'RPM. Prima di considerare una release definitiva vanno comunque provati sulla macchina reale: `rk add/rm/sync`, autenticazione Polkit, ricerca RPM con dimensioni e dipendenze, Flatpak, Podman, repository enable/disable, upgrade/rollback BootC, restart servizi e backup della home/configurazione.
