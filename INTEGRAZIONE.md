# Architettura K-ControlC

K-ControlC è ora un'applicazione standalone Qt 6/QML per il sistema raku/Fedora bootc.

## Principi

1. **Sistema base image-based**: aggiornamenti e rollback passano da `bootc`.
2. **Pacchetti persistenti raku**: add/rm/sync passano da `/usr/bin/rk`.
3. **Ricerca read-only**: `PackageSearch` usa `rpm` e `dnf5 repoquery` senza privilegi e senza bloccare il thread GUI.
4. **Privilegi minimi**: `PolkitHelper` accetta solo combinazioni esplicite di programma+argomenti; la policy Polkit è limitata a `rk` e `bootc`.
5. **Utility esterne opzionali**: strumenti desktop vengono lanciati senza privilegi e restano disabilitati se non presenti.

## Componenti C++

### `PackageSearch`

`QAbstractListModel` esposto al modulo QML `raku.cc`. Gestisce ricerche asincrone, cancella la query precedente quando l'utente continua a digitare e marca i pacchetti installati e quelli appartenenti alla base immutabile.

### `PolkitHelper`

Wrapper stretto su `pkexec` con streaming dell'output e gestione degli errori `QProcess`. Le invocazioni ammesse sono definite nel codice, non costruite liberamente dal QML.

### `BootcBackend`

Legge lo stato BootC in modo asincrono e mantiene lo stato della lista di pacchetti persistenti. Il testo di `bootc status --format=humanreadable` viene mostrato, non analizzato programmaticamente.

### `SystemBackend`

Raccoglie informazioni locali senza privilegi e gestisce una allowlist di utility grafiche opzionali.

## Interfaccia

- `DashboardModule`: panoramica e Quick System Info.
- `SoftwareModule`: ricerca RPM e layer persistente.
- `BootcModule`: aggiornamenti atomici e rollback.
- `SystemModule`: dati locali e configurazione desktop.
- `ToolsModule`: catalogo ricercabile per categorie.

Il layout prende ispirazione funzionale da YaST, Mageia Control Center e MX Tools, ma usa backend e flussi coerenti con Fedora bootc.

## Integrazione nell'immagine raku

Durante la build dell'immagine assicurarsi che siano presenti:

- l'eseguibile `k-controlc`;
- la policy `org.raku.controlcenter.policy` in `/usr/share/polkit-1/actions/`;
- la desktop entry in `/usr/share/applications/`;
- `/usr/bin/rk`;
- `bootc`, `rpm`, `dnf5`, `pkexec`;
- Qt 6 runtime con Qt Quick Controls e Layouts.

Le utility elencate in `ToolsModule.qml` sono intenzionalmente opzionali.
