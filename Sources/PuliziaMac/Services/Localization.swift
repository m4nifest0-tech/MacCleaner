import Foundation

/// Dizionario di stringhe statiche IT/EN. Le stringhe con parti dinamiche (conteggi,
/// dimensioni, nomi di file) restano nelle view come ternari su `settings.language`,
/// per evitare la fragilità di un motore di formattazione generico.
enum Localization {
    struct Entry {
        let it: String
        let en: String
    }

    static func string(_ key: String, language: AppLanguage) -> String {
        guard let entry = table[key] else { return key }
        return language == .italian ? entry.it : entry.en
    }

    private static let table: [String: Entry] = [
        // MARK: Sidebar / sezioni
        "sidebar.cacheCleaner": Entry(it: "Cache e File Temporanei", en: "Cache & Temp Files"),
        "sidebar.archScanner": Entry(it: "App Intel su ARM", en: "Intel Apps on ARM"),
        "sidebar.duplicateFinder": Entry(it: "File Duplicati", en: "Duplicate Files"),
        "sidebar.uninstaller": Entry(it: "Disinstallatore", en: "Uninstaller"),
        "sidebar.updateManager": Entry(it: "Aggiornamenti", en: "Updates"),
        "sidebar.settings": Entry(it: "Impostazioni", en: "Settings"),

        "content.select_section": Entry(it: "Seleziona una sezione", en: "Select a section"),

        // MARK: Comuni
        "common.cancel": Entry(it: "Annulla", en: "Cancel"),
        "common.reveal_finder": Entry(it: "Rivela nel Finder", en: "Reveal in Finder"),
        "common.move_to_trash": Entry(it: "Sposta nel Cestino", en: "Move to Trash"),
        "common.open_system_settings": Entry(it: "Apri Impostazioni di Sistema", en: "Open System Settings"),

        // MARK: Categorie cache
        "category.appCaches": Entry(it: "Cache delle app", en: "App Caches"),
        "category.logs": Entry(it: "Log", en: "Logs"),
        "category.trash": Entry(it: "Cestino", en: "Trash"),
        "category.developer": Entry(it: "File sviluppatore (Xcode/Homebrew/npm/pip)", en: "Developer Files (Xcode/Homebrew/npm/pip)"),
        "category.downloadsInstallers": Entry(it: "Installer scaricati", en: "Downloaded Installers"),

        // MARK: Cache Cleaner
        "cache.scan": Entry(it: "Scansiona", en: "Scan"),
        "cache.clean_selected": Entry(it: "Pulisci selezionati", en: "Clean Selected"),
        "cache.scanning": Entry(it: "Scansione in corso…", en: "Scanning…"),
        "cache.empty": Entry(it: "Nessuna cache o file temporaneo rilevante trovato", en: "No relevant cache or temp files found"),

        // MARK: Permission banner (Full Disk Access)
        "permission.body": Entry(
            it: "Per una scansione completa, apri Impostazioni di Sistema → Privacy e Sicurezza → Accesso completo al disco e abilita PuliziaMac.",
            en: "For a complete scan, open System Settings → Privacy & Security → Full Disk Access and enable PuliziaMac."
        ),

        // MARK: Arch Scanner
        "arch.scan_button": Entry(it: "Scansiona app installate", en: "Scan installed apps"),
        "arch.filter_intel": Entry(it: "Solo Intel (Rosetta)", en: "Intel only (Rosetta)"),
        "arch.filter_universal": Entry(it: "Universali (Intel + ARM)", en: "Universal (Intel + ARM)"),
        "arch.filter_all": Entry(it: "Tutte", en: "All"),
        "arch.explanation": Entry(
            it: "Le app senza slice arm64 girano solo tramite la traduzione Rosetta 2, più lenta della modalità nativa. Le app universali contengono sia Intel sia ARM: puoi rimuovere la parte Intel per risparmiare spazio, tenendo solo il nativo Apple Silicon.",
            en: "Apps without an arm64 slice only run through Rosetta 2 translation, which is slower than native. Universal apps contain both Intel and ARM: you can remove the Intel part to save space, keeping only the native Apple Silicon build."
        ),
        "arch.empty_intel": Entry(it: "Nessuna app Intel-only trovata: tutto nativo su Apple Silicon 🎉", en: "No Intel-only apps found: everything's native on Apple Silicon 🎉"),
        "arch.empty_universal": Entry(it: "Nessuna app universale trovata", en: "No universal apps found"),
        "arch.empty_all": Entry(it: "Nessuna app trovata", en: "No apps found"),
        "arch.analyzing": Entry(it: "Analisi delle app installate…", en: "Analyzing installed apps…"),
        "arch.badge_intel": Entry(it: "Intel-only", en: "Intel-only"),
        "arch.badge_universal": Entry(it: "Universale", en: "Universal"),
        "arch.mas_unavailable": Entry(it: "Non disponibile (Mac App Store)", en: "Not available (Mac App Store)"),
        "arch.mas_unavailable_help": Entry(
            it: "Le app del Mac App Store verificano la propria firma originale all'avvio: ri-firmarle le romperebbe quasi certamente.",
            en: "Mac App Store apps verify their original signature at launch: re-signing them would almost certainly break them."
        ),
        "arch.remove_intel_button": Entry(it: "Rimuovi Intel", en: "Remove Intel"),
        "arch.app_management_hint": Entry(
            it: "Vai in Impostazioni di Sistema → Privacy e Sicurezza → Gestione app e abilita PuliziaMac (potrebbe comparire nell'elenco solo dopo questo tentativo).",
            en: "Go to System Settings → Privacy & Security → App Management and enable PuliziaMac (it may only appear in the list after this attempt)."
        ),

        // MARK: Duplicate Finder
        "dup.folders_header": Entry(it: "Cartelle da analizzare", en: "Folders to scan"),
        "dup.add_folder": Entry(it: "Aggiungi cartella…", en: "Add folder…"),
        "dup.search_button": Entry(it: "Cerca duplicati", en: "Find duplicates"),
        "dup.analyzing": Entry(it: "Analisi dei file in corso…", en: "Analyzing files…"),
        "dup.choose_folder": Entry(it: "Scegli una cartella e avvia la ricerca", en: "Choose a folder and start the search"),
        "dup.no_duplicates": Entry(it: "Nessun duplicato trovato", en: "No duplicates found"),

        // MARK: Uninstaller
        "uninstall.search_placeholder": Entry(it: "Cerca app…", en: "Search apps…"),
        "uninstall.select_app": Entry(it: "Seleziona un'app da disinstallare", en: "Select an app to uninstall"),
        "uninstall.leftovers_header": Entry(it: "File residui trovati", en: "Leftover files found"),
        "uninstall.searching_leftovers": Entry(it: "Ricerca residui…", en: "Searching for leftovers…"),
        "uninstall.no_leftovers": Entry(it: "Nessun file residuo noto trovato.", en: "No known leftover files found."),
        "uninstall.button": Entry(it: "Disinstalla (sposta nel Cestino)", en: "Uninstall (move to Trash)"),
        "uninstall.confirm_button": Entry(it: "Disinstalla", en: "Uninstall"),

        // MARK: Update Manager
        "updates.check_button": Entry(it: "Controlla aggiornamenti", en: "Check for updates"),
        "updates.none_available": Entry(it: "Tutto aggiornato", en: "Everything is up to date"),
        "updates.checking": Entry(it: "Controllo aggiornamenti…", en: "Checking for updates…"),
        "updates.none_tools_title": Entry(it: "Homebrew e mas-cli non sono installati", en: "Homebrew and mas-cli aren't installed"),
        "updates.none_tools_desc": Entry(
            it: "PuliziaMac può controllare gli aggiornamenti solo per pacchetti Homebrew e app dal Mac App Store (tramite mas-cli). Per tutte le altre app, controlla direttamente nel loro menu \"Cerca aggiornamenti\".",
            en: "PuliziaMac can only check updates for Homebrew packages and Mac App Store apps (via mas-cli). For all other apps, check directly in their own \"Check for Updates\" menu."
        ),
        "updates.mas_missing": Entry(
            it: "mas-cli non installato: gli aggiornamenti da Mac App Store non vengono controllati.",
            en: "mas-cli not installed: Mac App Store updates aren't checked."
        ),
        "updates.install_mas_button": Entry(it: "Installa mas-cli", en: "Install mas-cli"),
        "updates.install_mas_confirm_title": Entry(it: "Installare mas-cli con Homebrew? (brew install mas)", en: "Install mas-cli with Homebrew? (brew install mas)"),
        "updates.install_mas_confirm_message": Entry(
            it: "Serve per controllare e aggiornare le app del Mac App Store. Verrà eseguito il comando 'brew install mas'.",
            en: "Needed to check and update Mac App Store apps. The command 'brew install mas' will be run."
        ),
        "updates.install_button": Entry(it: "Installa", en: "Install"),
        "updates.install_error": Entry(
            it: "Installazione non riuscita. Prova da Terminale con: brew install mas",
            en: "Installation failed. Try from Terminal with: brew install mas"
        ),
        "updates.update_button": Entry(it: "Aggiorna", en: "Update"),

        // MARK: Impostazioni
        "settings.language_header": Entry(it: "Lingua", en: "Language"),
        "settings.appearance_header": Entry(it: "Aspetto", en: "Appearance"),
        "settings.appearance_system": Entry(it: "Sistema", en: "System"),
        "settings.appearance_light": Entry(it: "Chiaro", en: "Light"),
        "settings.appearance_dark": Entry(it: "Scuro", en: "Dark"),
        "settings.accent_header": Entry(it: "Colore accento", en: "Accent Color"),

        // MARK: Colori accento
        "theme.accent.blue": Entry(it: "Blu", en: "Blue"),
        "theme.accent.orange": Entry(it: "Arancione", en: "Orange"),
        "theme.accent.purple": Entry(it: "Viola", en: "Purple"),
        "theme.accent.green": Entry(it: "Verde", en: "Green"),
        "theme.accent.pink": Entry(it: "Rosa", en: "Pink"),
        "theme.accent.red": Entry(it: "Rosso", en: "Red"),
        "theme.accent.teal": Entry(it: "Turchese", en: "Teal"),
        "theme.accent.graphite": Entry(it: "Grafite", en: "Graphite"),

        // MARK: Servizi (messaggi tecnici)
        "svc.mas_excluded": Entry(it: "App del Mac App Store: esclusa per sicurezza.", en: "Mac App Store app: excluded for safety."),
        "svc.resign_failed": Entry(it: "Ri-firma fallita.", en: "Re-signing failed."),
        "svc.thin_failed_resign": Entry(
            it: "Binari alleggeriti ma la ri-firma è fallita: l'app potrebbe non avviarsi più.",
            en: "Binaries were thinned but re-signing failed: the app may no longer launch."
        ),
        "svc.elevation_prepare_failed": Entry(
            it: "Impossibile preparare l'operazione con privilegi di amministratore.",
            en: "Couldn't prepare the operation with administrator privileges."
        ),
        "svc.elevation_cancelled": Entry(
            it: "Operazione annullata: servono i permessi di amministratore per modificare questa app.",
            en: "Operation cancelled: administrator privileges are needed to modify this app."
        ),
        "svc.app_management_required": Entry(
            it: "A PuliziaMac manca il permesso \"Gestione app\": anche con privilegi di amministratore, macOS blocca la modifica dei file di altre app finché non lo concedi esplicitamente.",
            en: "PuliziaMac is missing the \"App Management\" permission: even with administrator privileges, macOS blocks changes to other apps' files until you explicitly grant it."
        ),
        "svc.elevation_failed": Entry(it: "Operazione con privilegi di amministratore non riuscita.", en: "Operation with administrator privileges failed.")
    ]
}
