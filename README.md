# PuliziaMac

App nativa macOS (SwiftUI) per liberare spazio e mantenere pulito il Mac, in stile
CleanMyMac. Costruita con Swift Package Manager, senza bisogno di Xcode.

Vedi il [CHANGELOG](CHANGELOG.md) per la cronologia delle versioni.

## Funzioni

1. **Panoramica** — spazio su disco (usato/libero), spazio totale liberato da PuliziaMac
   nel tempo, accesso rapido a tutte le altre sezioni.
2. **Barra dei menù** — icona nella barra dei menù con spazio libero/liberato a colpo
   d'occhio e un accesso rapido alla finestra principale (anche direttamente su Pulizia
   Automatica) senza doverla tenere aperta.
3. **Pulizia Automatica** — esegue la stessa scansione sicura della Cache (più il flush
   della cache DNS di sistema), ma seleziona già tutto tranne il Cestino: basta
   controllare l'elenco e confermare una volta, invece di scegliere categoria per
   categoria. Volutamente **non** include duplicati/file grandi: quelli richiedono di
   scegliere a mano le cartelle e possono contenere documenti personali, non solo cache.
4. **Cache e file temporanei** — cache per-app (`~/Library/Caches`), log
   (`~/Library/Logs`), Cestino, DerivedData/Archives di Xcode, cache npm/pip, installer
   scaricati (`.dmg`/`.pkg`/`.zip` in `~/Downloads`).
5. **App Intel su ARM** — trova le app senza slice `arm64` (girano solo via Rosetta 2).
   Per le app **universali** (contengono sia Intel sia ARM) puoi anche rimuovere la
   parte Intel per risparmiare spazio: l'app viene "assottigliata" con `lipo` e
   ri-firmata ad-hoc. **Nessun backup automatico**: alcune app (soprattutto con
   protezioni anti-manomissione o scaricate dal Mac App Store) possono smettere di
   funzionare e richiedere la reinstallazione — per questo le app Mac App Store sono
   sempre escluse dall'operazione.
6. **File duplicati** — cerca file con contenuto identico (hash SHA256) in cartelle a
   scelta.
7. **File di grandi dimensioni** — trova i file più pesanti in una o più cartelle a
   scelta, con soglia minima selezionabile (100MB–5GB).
8. **Esplora Disco** — navigazione del disco cartella per cartella (come
   DaisyDisk/OmniDiskSweeper) con la dimensione reale di ogni voce, per trovare spazio
   occupato ovunque, non solo nelle categorie fisse degli altri moduli. Vista **Elenco**
   (lista) o **Grafica** (treemap: rettangoli con area proporzionale alla dimensione,
   algoritmo "squarified" come DaisyDisk/WinDirStat).
9. **Allegati Mail** — cache degli allegati scaricati/aperti tramite Mail.app (non gli
   allegati "veri" nel database dei messaggi: rimuovere questa cache non cancella email).
10. **Disinstallatore** — rimuove un'app e i suoi file residui noti (preferenze, cache,
    application support, log, stato salvato, container). Se l'app è di proprietà di root
    (comune per quelle del Mac App Store), ritenta con privilegi di amministratore.
11. **Elementi di avvio** — elenca gli agenti di avvio (LaunchAgents utente e sistema) e
    permette di disattivarli. Non copre i classici "Elementi di Login" di Impostazioni di
    Sistema, che usano un formato interno non documentato da Apple.
12. **Aggiornamenti** — controlla e applica aggiornamenti per pacchetti Homebrew e app
    Mac App Store (via `mas-cli`, se installato). Per le altre app non esiste un modo
    generico e affidabile per controllare gli aggiornamenti: va fatto dal menu dell'app
    stessa.
13. **Impostazioni** — lingua (Italiano/English, cambia subito tutta l'interfaccia senza
    riavviare), tema (Sistema/Chiaro/Scuro + colore d'accento a scelta tra 8 varianti),
    cartelle escluse dalle scansioni e possibilità di nascondere l'icona dal Dock
    (l'app resta accessibile dalla barra dei menù).

Scorciatoie da tastiera: **⌘1**–**⌘9** per passare rapidamente tra le prime nove sezioni
della sidebar, **⌘,** per le Impostazioni (menù "Vai a").

**Principio di sicurezza**: nessuna azione cancella mai in modo permanente. Ogni pulizia
sposta gli elementi nel Cestino di macOS (tranne "svuota Cestino", che per definizione è
l'azione finale), così ogni operazione resta recuperabile.

## Compilare ed eseguire

```bash
./Scripts/build_app.sh
open dist/PuliziaMac.app
```

Lo script compila in release e impacchetta un vero bundle `PuliziaMac.app` (icona,
finestra, Dock) senza bisogno di Xcode — bastano le Command Line Tools.

Per lavorare da riga di comando senza pacchettizzare:

```bash
swift build          # compila
swift test            # esegue i test
swift run PuliziaMac   # avvia (senza icona Dock/bundle completo)
```

## Permessi richiesti

macOS blocca l'accesso a cartelle protette (Desktop, Documents, Downloads, Mail, ecc.)
finché non concedi **Accesso completo al disco** a PuliziaMac:

Impostazioni di Sistema → Privacy e Sicurezza → Accesso completo al disco → abilita
PuliziaMac (l'app mostra anche un banner con lo stesso collegamento quando rileva
cartelle non leggibili).

## Limiti noti

- **Firma ad-hoc**: senza un account sviluppatore Apple, l'app è firmata ad-hoc. Ad ogni
  ricompilazione la firma cambia, quindi macOS potrebbe richiedere di riconcedere
  l'Accesso completo al disco dopo ogni build da zero. Con un Apple ID sviluppatore
  (Team ID) si può firmare in modo stabile.
- **Niente App Sandbox**: per accedere liberamente alle cache di sistema/altre app,
  l'app gira senza sandbox — quindi non è distribuibile tramite Mac App Store, solo per
  uso personale/locale.
- **Test**: questa macchina ha solo le Command Line Tools (niente Xcode.app), che non
  includono `XCTest.framework`. I test usano quindi `swift-testing` come dipendenza SPM
  (vedi commento in `Package.swift`) invece del modulo `Testing` integrato nel toolchain,
  che richiede Xcode.
- **Aggiornamenti**: coperti solo Homebrew e Mac App Store; non esiste un modo affidabile
  per controllare aggiornamenti di app scaricate da siti esterni senza integrare il
  meccanismo proprietario di ciascuna (es. Sparkle).
