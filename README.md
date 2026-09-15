# K-ControlC / rakuCC

K-ControlC è un **Control Center standalone Qt 6/QML per sistemi Fedora bootc/raku**. Unisce navigazione modulare in stile YaST/Mageia e utility pratiche nello spirito di MX Tools, mantenendo però il modello image-based di bootc.

## Moduli

- Panoramica e Quick System Info
- Software persistente via `rk` + Flatpak
- Deployment BootC: JSON status, staged/booted/rollback, upgrade e rollback
- Sistema: data/ora, NTP e sessione via systemd-logind
- Rete e NetworkManager
- Utenti tramite KCM Plasma
- Servizi: NetworkManager, CUPS, Bluetooth
- Hardware
- Storage
- Sicurezza/Firewall con azioni runtime SSH/HTTP/HTTPS
- Diagnostica e log
- Firmware/fwupd
- Recovery
- Strumenti dinamici da file `.desktop` System/Settings
- Ricerca globale su moduli, strumenti installati e pacchetti RPM

## Scelte tecniche e sicurezza

`PackageSearch` usa `dnf5 repoquery` con package-spec posizionale (`*term*`): `repoquery --search` non esiste. I caratteri glob forniti dall'utente vengono scartati e l'elenco RPM installato viene riusato finché non cambia il mtime del database RPM (`/usr/lib/sysimage/rpm/rpmdb.sqlite`, con fallback `/var/lib/rpm/rpmdb.sqlite`). Le ricerche obsolete vengono invalidate con una generation id; i processi vengono prima terminati gentilmente e solo dopo 3 secondi eventualmente uccisi.

Le operazioni privilegiate passano da `pkexec`, ma la GUI mantiene una allowlist esatta di programma+argomenti. La policy non usa `auth_admin_keep`: ogni invocazione richiede una decisione fresca e le azioni `rk`/`bootc` sono separate con `org.freedesktop.policykit.exec.argv1`. Anche le azioni rapide firewalld sono limitate a un singolo `argv1` previsto.

Il sistema base non usa `dnf distro-sync`: aggiornamento e recovery della base passano da `bootc`; `rk sync` riguarda il layer persistente. Flatpak resta separato.

## Build

```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
./build/k-controlc
```

Installazione:

```bash
sudo cmake --install build --prefix /usr
```

È presente anche `packaging/k-controlc.spec` per la costruzione RPM nell'immagine raku.

## CI e test

GitHub Actions usa Fedora 44 e verifica:

1. configurazione CMake e compilazione C++/QML;
2. avvio QML headless;
3. `dnf5 repoquery` reale con package-spec posizionale;
4. assenza del vecchio `--search` nel sorgente;
5. parsing dello spec RPM;
6. install staging e pubblicazione dell'artifact.

`tests/e2e-readonly.sh` esegue inoltre probe read-only di bootc quando disponibile. Le operazioni mutanti (`rk add/rm`, `bootc upgrade/rollback`, firewall, reboot) devono essere collaudate nell'immagine raku reale prima della release finale.

## Flatpak

K-ControlC verifica `kcmshell6 --list` quando si apre la gestione Flatpak. Se `kcm_flatpak` non è presente su Plasma 6, usa `plasma-discover` come fallback.

## i18n

Le nuove stringhe QML usano `qsTr()` e il C++ usa `tr()`: il codice è predisposto per cataloghi Qt Translation. Vedi `i18n/README.md`.

## Licenza

MIT, vedi `LICENSE`.

## Stato 0.3.0

La CI non è più un passo futuro: è parte del repository. Il gate finale prima del tag `v0.3.0` è l'E2E sull'immagine bootc raku di destinazione, in particolare PolicyKit, logind, KCM Plasma, fwupd, firewalld e le operazioni mutanti bootc/rk.
