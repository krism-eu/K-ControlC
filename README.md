# K-ControlC / rakuCC

Bundle sorgente per integrare il modulo **Software** nel raku Control Center su Fedora bootc.

Il repository riflette direttamente il contenuto utile del pacchetto di integrazione originario: lo ZIP non viene mantenuto nel tree.

## Struttura

- `src/PackageSearch.{h,cpp}` — modello Qt asincrono per ricerca pacchetti tramite `rpm` e `dnf5 repoquery`.
- `src/PolkitHelper.{h,cpp}` — esecuzione privilegiata limitata a `/usr/bin/rk` e `/usr/bin/bootc`, con output in streaming e gestione errori `QProcess`.
- `qml/modules/SoftwareModule.qml` — UI Software: ricerca RPM, add/rm/sync via `rk`, gestione Flatpak tramite `kcmshell6` senza privilegi.
- `INTEGRAZIONE.md` — istruzioni per innestare questi file nel progetto rakuCC completo.

## Correzioni applicate

- ricerca `PackageSearch` non bloccante: nessun `waitForFinished()` sul thread GUI;
- formato DNF5 con newline esplicito (`\\n`) e separatore tab;
- istanza QML reale di `PackageSearch` invece di usarne il nome del tipo come singleton;
- cancellazione della ricerca precedente quando cambia il testo;
- allowlist per i programmi privilegiati;
- `kcmshell6` avviato senza `pkexec`;
- gestione di `FailedToStart`, exit status e righe stdout parziali;
- rimosso `cc-merge.zip`.

## Nota

Questo repository contiene **l'innesto Software**, non tutti i file del Control Center base (CMakeLists, `main.cpp`, BootcBackend, gli altri moduli e il packaging). Per l'integrazione nel progetto completo seguire `INTEGRAZIONE.md`.
