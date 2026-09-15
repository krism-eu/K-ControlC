# K-ControlC / rakuCC

K-ControlC è un **Control Center standalone per sistemi Fedora bootc/raku**, scritto in C++ e Qt 6/QML.

L'interfaccia combina tre idee: categorie e ricerca in stile YaST, un unico centro amministrativo come Mageia Control Center e utility rapide nello spirito di MX Tools. Le operazioni specifiche del sistema image-based restano però native di bootc: niente emulazione di un package manager tradizionale per il sistema base.

## Funzioni

- **Panoramica** con OS, kernel, memoria, storage, stato BootC e pacchetti persistenti.
- **Quick System Info** copiabile negli appunti per diagnosi/supporto.
- **Software**: ricerca RPM asincrona con `dnf5 repoquery`, stato installato/base, add/rm/sync tramite `rk`, accesso Flatpak.
- **Aggiornamenti BootC**: stato, check, upgrade, download-only, apply/reboot e rollback.
- **Sistema**: informazioni locali e scorciatoie verso configurazione desktop.
- **Strumenti**: launcher ricercabile e categorizzato per System Settings, Info Center, Partition Manager, firewall, stampanti, Discover, virt-manager, KSystemLog e terminale. Gli strumenti mancanti risultano disabilitati, non vengono installati automaticamente.

## Sicurezza

Le operazioni privilegiate passano esclusivamente da `pkexec` e sono limitate a:

- `/usr/bin/rk`: `sync`, `add <pacchetto>`, `rm <pacchetto>`;
- `/usr/bin/bootc`: `upgrade`, `upgrade --check`, `upgrade --download-only`, `upgrade --apply`, `rollback`, `rollback --apply`.

La policy Polkit installata autorizza solo i due binari previsti. `kcmshell6` e le utility desktop sono avviati senza privilegi e usano, quando necessario, i propri meccanismi Polkit.

## Dipendenze di build

- CMake >= 3.22
- compilatore C++17
- Qt >= 6.5: Core, Gui, Qml, Quick

Dipendenze runtime per tutte le funzioni:

- Qt Quick Controls 2 e Qt Quick Layouts
- `rpm` e `dnf5` per la ricerca software
- `polkit`/`pkexec` per le azioni amministrative
- `bootc` su sistemi image-based
- `/usr/bin/rk` e `/var/lib/raku-kris/packages.list` per il layer persistente raku

Le utility grafiche esterne sono opzionali.

## Build

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
./build/k-controlc
```

Installazione di sistema:

```bash
sudo cmake --install build --prefix /usr
```

Questo installa l'eseguibile, la desktop entry e la policy Polkit.

## Struttura

```text
CMakeLists.txt
src/
  main.cpp
  BootcBackend.{h,cpp}
  SystemBackend.{h,cpp}
  PackageSearch.{h,cpp}
  PolkitHelper.{h,cpp}
qml/
  Main.qml
  components/ToolCard.qml
  modules/
    DashboardModule.qml
    SoftwareModule.qml
    BootcModule.qml
    SystemModule.qml
    ToolsModule.qml
data/
  k-controlc.desktop
  org.raku.controlcenter.policy
```

## Stato

La repository è ora una applicazione standalone, non più soltanto il bundle di integrazione originario. Il passo successivo consigliato è aggiungere CI su Fedora e testare il pacchetto direttamente nell'immagine raku/bootc di destinazione.
