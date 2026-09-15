# K-ControlC / rakuCC integration bundle

Bundle di integrazione per **rakuCC**, Control Center destinato a Fedora BootC.

Questo branch normalizza il contenuto di `cc-merge.zip` direttamente nella struttura del progetto. Il pacchetto è un bundle di integrazione, non un'applicazione standalone completa.

## Struttura materializzata

```text
.
├── INTEGRAZIONE.md
├── qml/
│   └── modules/
│       └── SoftwareModule.qml
└── src/
    ├── PackageSearch.h
    ├── PolkitHelper.cpp
    └── PolkitHelper.h
```

`src/PackageSearch.cpp` è presente nel pacchetto originale ma non è stato materializzato dal connettore GitHub: resta quindi conservato in `cc-merge.zip` finché non viene aggiunto esplicitamente. Nel file ZIP il suo nome presenta inoltre una discrepanza interna (`PackageSearcc.cpp` nell'indice locale contro `PackageSearch.cpp` nell'indice centrale); il nome canonico da usare nel repository è `PackageSearch.cpp`.

## Componenti

- **PackageSearch**: ricerca read-only dei pacchetti RPM tramite `dnf5 repoquery`, con stato installato e marcatura dei pacchetti appartenenti alla base immutabile.
- **PolkitHelper**: esecuzione tramite `pkexec` delle operazioni privilegiate, con output progressivo verso la UI.
- **SoftwareModule.qml**: UI per ricerca/installazione/rimozione RPM, sincronizzazione dell'overlay e accesso alla gestione Flatpak.
- **INTEGRAZIONE.md**: note per innestare questi file nella base rakuCC.

## Integrazione nella base rakuCC

La guida completa è in [`INTEGRAZIONE.md`](INTEGRAZIONE.md). Prima del merge definitivo vanno risolti i punti emersi dalla revisione: registrazione/uso QML di `PackageSearch`, parsing dell'output DNF5, esecuzione non privilegiata di `kcmshell6` e gestione robusta degli errori dei processi.
