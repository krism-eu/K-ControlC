# K-ControlC

K-ControlC è un **Control Center personale Kirigami per Fedora bootc**. Non vuole sostituire Plasma System Settings: rete, utenti, firewall, display, audio e preferenze desktop restano agli strumenti KDE già presenti.

## Cosa gestisce

- **Panoramica**: sistema, BootC, storage, pacchetti persistenti e Quick System Info.
- **Software**: ricerca RPM, installati, aggiornabili, pacchetti recenti, repository DNF5 e layer persistente gestito da `rk`.
- **Discover**: applicazioni grafiche e Flatpak vengono delegati a Plasma Discover.
- **BootC**: stato deployment JSON, upgrade, download/apply e rollback.
- **Strumenti**: pulizia Flatpak, analisi RPM non necessari, log dell'ultimo boot, firmware, dischi, monitor e restart rapido di NetworkManager/CUPS/Bluetooth.
- **Recovery e backup**: rollback BootC, `rk sync`, azioni di sessione e snapshot `tar.gz` della configurazione o della home.

Gli snapshot vengono salvati in `~/K-ControlC Backups`. Il backup della home esclude cache, cestino e la cartella stessa dei backup; prima di partire verifica anche che nel filesystem di destinazione ci sia uno spazio libero minimo di sicurezza.

## Sicurezza

Le modifiche privilegiate passano da `pkexec` con una allowlist C++ stretta. La policy non usa `auth_admin_keep`. Sono ammesse soltanto le combinazioni previste per `rk`, `bootc` e l'abilitazione/disabilitazione dei repository tramite `dnf5 config-manager`. Non vengono eseguite shell root generiche.

Le query DNF5 sono read-only. La ricerca usa `dnf5 repoquery --available ... '*term*'`; inventario, aggiornamenti e pacchetti recenti usano le API JSON di DNF5. I test che richiedono metadata remoti sono separati dai controlli locali obbligatori, per evitare falsi negativi quando i mirror non sono raggiungibili.

## Compatibilità attuale con il sistema

K-ControlC è ora identificato in modo autonomo (`org.kcontrolc`). Per non rompere il collaudo sull'installazione attuale, il backend mantiene temporaneamente l'integrazione con `/usr/bin/rk` e con i percorsi dati legacy usati dal sistema corrente. Questi punti verranno migrati insieme al futuro rinomina dell'OS, non prima.

## Build locale

Dipendenze Fedora:

```bash
dnf install gcc-c++ cmake ninja-build qt6-qtbase-devel qt6-qtdeclarative-devel kf6-kirigami-devel
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
./build/k-controlc
```

## RPM

Lo spec è in `packaging/k-controlc.spec`. La CI Fedora 44 costruisce automaticamente sia il binario/staging sia l'RPM `k-controlc-0.4.0-*.rpm`, installa l'RPM nel container e riesegue lo smoke test. L'RPM prodotto è disponibile come artifact del workflow e può essere copiato direttamente nel build context della tua immagine BootC.

Esempio manuale:

```bash
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
git archive --format=tar.gz --prefix=k-controlc-0.4.0/ \
  -o ~/rpmbuild/SOURCES/k-controlc-0.4.0.tar.gz HEAD
cp packaging/k-controlc.spec ~/rpmbuild/SPECS/
rpmbuild -ba ~/rpmbuild/SPECS/k-controlc.spec
```

## Test reale

La CI verifica compilazione, caricamento QML/Kirigami, controlli DNF5 locali, spec RPM, installazione di staging e installazione/smoke dell'RPM. Prima di considerare una release definitiva vanno comunque provati sulla macchina reale: `rk add/rm/sync`, autenticazione Polkit, repository enable/disable, upgrade/rollback BootC, restart servizi e backup della home/configurazione.
