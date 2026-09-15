# K-ControlC / rakuCC integration bundle

Bundle di integrazione per **rakuCC**, Control Center destinato a Fedora BootC.

Questo repository contiene gli innesti sorgente estratti dal pacchetto `cc-merge.zip` e organizzati direttamente nella struttura del progetto. Non è un'applicazione standalone completa: i file sono pensati per essere integrati nella base rakuCC esistente.

## Struttura

```text
.
├── INTEGRAZIONE.md
├── qml/
│   └── modules/
│       └── SoftwareModule.qml
└── src/
    ├── PackageSearch.cpp
    ├── PackageSearch.h
    ├── PolkitHelper.cpp
    └── PolkitHelper.h
```

## Componenti

- **PackageSearch**: ricerca read-only dei pacchetti RPM tramite `dnf5 repoquery`, con stato installato e marcatura dei pacchetti appartenenti alla base immutabile.
- **PolkitHelper**: esecuzione tramite `pkexec` delle operazioni privilegiate, con output progressivo verso la UI.
- **SoftwareModule.qml**: UI per ricerca/installazione/rimozione RPM, sincronizzazione dell'overlay e accesso alla gestione Flatpak.
- **INTEGRAZIONE.md**: note per innestare questi file nella base rakuCC.

## Integrazione nella base rakuCC

La guida completa è in [`INTEGRAZIONE.md`](INTEGRAZIONE.md). In sintesi servono l'aggiunta di `PackageSearch` al build CMake, la registrazione del tipo QML e l'allineamento con l'URI QML reale della base.

> Nota: il pacchetto sorgente originale contiene alcuni punti da verificare prima del merge definitivo (registrazione/uso QML di `PackageSearch`, lancio non privilegiato di `kcmshell6` e robustezza dei processi). Sono mantenuti nel codice per una revisione esplicita invece di nasconderli nel riordino del repository.
