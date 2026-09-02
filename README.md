# PuliziaMac

App nativa macOS per liberare spazio e mantenere pulito il Mac, in stile CleanMyMac.

Vedi il [CHANGELOG](CHANGELOG.md) per la cronologia delle versioni.

## Download

Scarica `PuliziaMac.app.zip` dall'ultima [Release](https://github.com/m4nifest0-tech/PuliziaMac/releases/latest),
decomprimilo e sposta `PuliziaMac.app` in Applicazioni.

L'app non è firmata con un account sviluppatore Apple: al primo avvio macOS potrebbe
avvisare che non può verificarne l'origine. Basta fare clic destro sull'app → **Apri**,
poi confermare nella finestra che compare.

## Funzionalità

1. **Panoramica** — spazio su disco (usato/libero, con indicatore ad anello), spazio
   totale liberato da PuliziaMac nel tempo, accesso rapido a tutte le altre sezioni ed
   esportazione di un report PDF (con anteprima prima del salvataggio).
   La sidebar ha una barra di ricerca per trovare rapidamente una funzionalità per
   nome o sinonimo (es. "doppi" trova File Duplicati).
2. **Barra dei menù** — icona nella barra dei menù con spazio libero/liberato a colpo
   d'occhio e un accesso rapido alla finestra principale (anche direttamente su Pulizia
   Automatica) senza doverla tenere aperta.
3. **Pulizia Automatica** — esegue la stessa scansione sicura della Cache (più il flush
   della cache DNS di sistema), ma seleziona già tutto tranne il Cestino: basta
   controllare l'elenco e confermare una volta, invece di scegliere categoria per
   categoria. Volutamente **non** include duplicati/file grandi: quelli richiedono di
   scegliere a mano le cartelle e possono contenere documenti personali, non solo cache.
4. **Cache e file temporanei** — cache per-app, log, Cestino, DerivedData/Archives di
   Xcode, cache npm/pip, installer scaricati (`.dmg`/`.pkg`/`.zip` in `~/Downloads`).
5. **App Intel su ARM** — trova le app senza slice `arm64` (girano solo via Rosetta 2),
   con barra di ricerca per nome. Per le app **universali** (contengono sia Intel sia
   ARM) puoi anche rimuovere la parte Intel per risparmiare spazio. **Nessun backup
   automatico**: alcune app (soprattutto con protezioni anti-manomissione o scaricate
   dal Mac App Store) possono smettere di funzionare e richiedere la reinstallazione —
   per questo le app Mac App Store sono sempre escluse dall'operazione.
6. **File duplicati** — cerca file con contenuto identico (hash SHA256) in cartelle a
   scelta.
7. **File di grandi dimensioni** — trova i file più pesanti in una o più cartelle a
   scelta, con soglia minima selezionabile (100MB–5GB).
8. **Esplora Disco** — navigazione del disco cartella per cartella (come
   DaisyDisk/OmniDiskSweeper) con la dimensione reale di ogni voce, per trovare spazio
   occupato ovunque, non solo nelle categorie fisse degli altri moduli. Vista **Elenco**
   (lista) o **Grafica** (anello proporzionale alla dimensione con legenda interattiva
   per selezionare o navigare).
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

## Permessi richiesti

macOS blocca l'accesso a cartelle protette (Desktop, Documents, Downloads, Mail, ecc.)
finché non concedi **Accesso completo al disco** a PuliziaMac:

Impostazioni di Sistema → Privacy e Sicurezza → Accesso completo al disco → abilita
PuliziaMac (l'app mostra anche un banner con lo stesso collegamento quando rileva
cartelle non leggibili).
