# Integrazione nel rakuCC base

Questo repository contiene l'innesto del modulo **Software** per il progetto rakuCC completo. La precedente bozza D-Bus resta esclusa: le operazioni privilegiate passano da `pkexec` verso i binari gia' previsti dal sistema (`rk` e `bootc`).

## File da integrare

1. `src/PolkitHelper.{h,cpp}` sostituisce l'helper esistente.
   - streaming riga-per-riga;
   - gestione `QProcess::FailedToStart` e exit status;
   - allowlist privilegiata: solo `/usr/bin/rk` e `/usr/bin/bootc`;
   - `launchUnprivileged()` limitato a `/usr/bin/kcmshell6` per il KCM Flatpak.
2. `src/PackageSearch.{h,cpp}` e' nuovo.
   - ricerca read-only con `rpm` + `dnf5 repoquery`;
   - completamente asincrona, senza `waitForFinished()` sul thread GUI;
   - stato `searching`, cancellazione della ricerca precedente e segnale `searchError`;
   - queryformat DNF5 con separatore tab e sequenza `\\n` esplicita.
3. `qml/modules/SoftwareModule.qml` sostituisce lo stub Software.
   - istanzia `PackageSearch { id: packageSearch }`;
   - install/remove/sync passano da `PolkitHelper.execute("/usr/bin/rk", ...)`;
   - `kcmshell6 kcm_flatpak` viene avviato senza `pkexec` tramite `launchUnprivileged()`.

## Tocchi nel progetto base

### 1. CMakeLists.txt

Aggiungere almeno questi sorgenti allo stesso target/modulo che contiene gli altri backend QML:

```cmake
src/PackageSearch.cpp
src/PackageSearch.h
src/PolkitHelper.cpp
src/PolkitHelper.h
```

`qml/modules/SoftwareModule.qml` deve inoltre essere incluso tra i QML_FILES del modulo.

### 2. Registrazione QML

Registrare `PackageSearch` come tipo istanziabile:

```cpp
#include "PackageSearch.h"

qmlRegisterType<PackageSearch>("raku.cc", 1, 0, "PackageSearch");
```

Il QML corretto crea poi una propria istanza `PackageSearch`; non usa il nome del tipo come singleton.

`PolkitHelper` deve restare esposto con la modalita' gia' usata dal progetto base (singleton/context property), perche' `SoftwareModule.qml` lo usa come oggetto globale.

Verificare che l'URI reale coincida con `import raku.cc`; se il progetto base usa un URI diverso, allineare sia `qmlRegisterType()` sia l'import QML.

### 3. Policy Polkit

La policy deve autorizzare esclusivamente gli helper privilegiati previsti dal progetto, con `exec.path` per:

- `/usr/bin/rk`
- `/usr/bin/bootc`

Non aggiungere una action catch-all per programmi arbitrari. `kcmshell6` non richiede privilegi e non deve comparire nella policy.

### 4. Dipendenze runtime

Il modulo Software presuppone la presenza di:

- `/usr/bin/rpm`
- `/usr/bin/dnf5`
- `/usr/bin/pkexec`
- `/usr/bin/rk`
- `/usr/bin/kcmshell6` per il pulsante Flatpak
- `/usr/share/raku-kris/owned-packages.txt` per marcare i pacchetti della base immutabile

## Non portare dalla vecchia bozza D-Bus

- helper Python `org.raku.Control`;
- unit D-Bus dedicata;
- `org.raku.Control.policy` separata;
- `registry.json`;
- dipendenze Kirigami non necessarie al Fusion dark del progetto base.
