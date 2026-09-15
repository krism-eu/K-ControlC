# Merge: rakuCC (base) + innesti da bozza D-Bus

## Cosa prendere da DOVE

BASE = rakuCC (architettura pkexec + backend C++ + 8 moduli + packaging).
La bozza D-Bus viene **abbandonata**: il suo helper Python/daemon e' una
superflua superficie di manutenzione. pkexec -> rk|bootc con policy
exec.path riusa gli stessi binari che rk gia' protegge: una sola enforcement.

INNESTI dalla bozza D-Bus (questo pacchetto):
1. `src/PolkitHelper.{h,cpp}`  -> SOSTITUISCE il PolkitHelper esistente.
   Aggiunge streaming riga-per-riga (signal `line`) per operazioni lunghe;
   RIMUOVE `executeRaw` (codice morto pericoloso: pkexec arbitrario non ha
   action policy; se mai aggiunta catch-all diventerebbe un buco).
2. `src/PackageSearch.{h,cpp}` -> NUOVO. Ricerca read-only dnf5 repoquery
   + marcatura owned/installed. Nessun pkexec: la lettura e' innocua.
3. `qml/modules/SoftwareModule.qml` -> SOSTITUISCE lo stub esistente:
   ricerca + install/rm via `PolkitHelper.execute("/usr/bin/rk", ...)`,
   sync da lista, Flatpak delegato a kcmshell6 (comando NON privilegiato:
   togliere pkexec — kcmshell6 va lanciato diretto, non come root).

## Integrazione (4 tocchi)

1. CMakeLists.txt: aggiungere `src/PackageSearch.cpp` e `src/PackageSearch.h`
   a qt_add_qml_module(... SOURCES) (stesso blocco di BootcBackend ecc.).
2. main.cpp / contesto: `qmlRegisterType<PackageSearch>("raku.cc", 1, 0, "PackageSearch");`
   (PolkitHelper gia' registrato; verificare il nome modulo import in QML:
   qui uso `import raku.cc` — allineare con l'URI reale del progetto).
3. Nel software module: `kcmshell6` va lanciato SENZA pkexec (e' un'app
   utente). Se serve un runner non privilegiato: `QProcess::startDetached`.
4. Policy: invariata (2 action con exec.path /usr/bin/rk e /usr/bin/bootc).
   Granularita' add-vs-rm non raggiungibile via pkexec (stesso binario):
   accettabile, rk valida comunque ogni operazione.

## Da NON portare dalla bozza D-Bus

- helper Python org.raku.Control, unit Type=dbus, org.raku.Control.policy
- registry.json (il catalogo compilato in ToolModel.cpp e' type-safe)
- Kirigami (il Fusion dark di rakuCC e' portabile e gia' consistente)
