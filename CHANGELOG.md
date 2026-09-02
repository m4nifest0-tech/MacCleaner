# Changelog

Tutte le modifiche rilevanti a questo progetto sono documentate qui. Il formato
segue [Keep a Changelog](https://keepachangelog.com/it/1.0.0/).

## [1.1.0] - 2026-09-02

### Aggiunte
- **Esplora Disco** — navigazione del disco cartella per cartella, vista Elenco o Grafica (treemap: rettangoli con area proporzionale alla dimensione).
- **Allegati Mail** — sezione dedicata (prima categoria dentro Cache) per la cache degli allegati Mail.app.
- **Barra dei menù** — spazio libero/liberato a colpo d'occhio, accesso rapido alla finestra principale o a Pulizia Automatica.
- **Nascondi icona dal Dock** (Impostazioni) — l'app resta accessibile dalla barra dei menù.
- **Scorciatoie da tastiera** — ⌘1–⌘9 per le sezioni, ⌘, per Impostazioni.

## [1.0.3] - 2026-08-31

### Aggiunte
- **Panoramica** — spazio su disco (usato/libero), spazio totale liberato da PuliziaMac nel tempo, accesso rapido a tutte le sezioni.
- **Pulizia Automatica** — la stessa scansione sicura della Cache (più il flush della cache DNS di sistema), con tutto già selezionato tranne il Cestino: basta controllare e confermare una volta.
- **File di Grandi Dimensioni** — trova i file più pesanti in cartelle a scelta, con soglia minima selezionabile (100MB–5GB).
- **Elementi di Avvio** — elenca e disattiva gli agenti di avvio (LaunchAgents utente e sistema).
- **Cartelle escluse** (in Impostazioni) — cartelle che cache/duplicati/file grandi non toccano mai.

### Corrette
- Il Disinstallatore falliva silenziosamente sulle app di proprietà di root (comuni tra quelle scaricate dal Mac App Store), senza errore visibile e senza un modo per completare l'operazione. Ora, se lo spostamento normale fallisce per permessi, ritenta con privilegi di amministratore — e il messaggio d'errore resta visibile invece di sparire subito.
- Diverse sezioni (Aggiornamenti, Cache, Duplicati, File Grandi, App Intel, Elementi di Avvio) centravano l'intero contenuto — inclusa la barra dei pulsanti in alto — invece di ancorare i pulsanti in alto e centrare solo il contenuto sottostante.
- La larghezza della sidebar è ora vincolata esplicitamente, così una sezione con un layout interno largo (es. il Disinstallatore) non può più schiacciarla sotto una larghezza leggibile.
- Il controllo aggiornamenti mostra una percentuale reale di avanzamento (controlli completati/totali), non un'animazione indeterminata.

## [1.0.2] - 2026-08-31

### Corrette
- L'aspetto (Sistema/Chiaro/Scuro) restava bloccato sull'ultimo valore forzato quando si tornava su "Sistema", per un conflitto tra `.preferredColorScheme()` (SwiftUI) e `NSApp.appearance` (AppKit) che gestivano entrambi lo stesso stato.

## [1.0.1] - 2026-08-31

### Corrette
- Cambiare l'aspetto (Sistema/Chiaro/Scuro) dalle Impostazioni non applicava davvero il tema: ora viene impostato a livello di sistema (`NSApp.appearance`).
- Il colore d'accento scelto non si rifletteva nella selezione della sidebar, che restava sempre blu (colore di sistema).

## [1.0.0] - 2026-08-31

### Aggiunte
- Prima release: app nativa macOS (SwiftUI, Apple Silicon) per liberare spazio e mantenere pulito il Mac.
- **Cache e file temporanei** — cache per-app, log, Cestino, DerivedData/Archives Xcode, cache npm/pip, installer scaricati.
- **App Intel su ARM** — trova le app senza slice `arm64` e permette di rimuovere la parte Intel dalle app universali per risparmiare spazio.
- **File duplicati** — rilevamento tramite hash SHA256 in cartelle a scelta.
- **Disinstallatore** — rimuove un'app e i suoi file residui noti.
- **Aggiornamenti** — controllo/applicazione per pacchetti Homebrew e app Mac App Store (via `mas-cli`).
- **Impostazioni** — lingua (Italiano/English) e tema (Sistema/Chiaro/Scuro + colore d'accento).
- Nessuna cancellazione permanente automatica: ogni pulizia sposta gli elementi nel Cestino.

[1.1.0]: https://github.com/m4nifest0-tech/PuliziaMac/releases/tag/v1.1.0
[1.0.3]: https://github.com/m4nifest0-tech/PuliziaMac/releases/tag/v1.0.3
[1.0.2]: https://github.com/m4nifest0-tech/PuliziaMac/releases/tag/v1.0.2
[1.0.1]: https://github.com/m4nifest0-tech/PuliziaMac/releases/tag/v1.0.1
[1.0.0]: https://github.com/m4nifest0-tech/PuliziaMac/releases/tag/v1.0.0
